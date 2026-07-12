use BDD::Behave;
use JSON::Fast;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

sub streamed-body($response --> Str) {
  $response.is-streaming
    ?? $response.stream-chunks.map({ $_ ~~ Blob ?? .decode('utf-8') !! $_.Str }).join
    !! $response.body
}

describe 'MVC::Keayl::Admin CSV export', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'Alpha' }, { title => 'Beta' });
  }

  let(:response, { fetch('/admin/posts/export.csv') });

  it 'is sent as a text/csv attachment', {
    expect(response.header('Content-Type').contains('text/csv') && response.header('Content-Disposition').contains('attachment')).to.be-truthy;
  }

  it 'streams a header row and one row per record', {
    my $csv = streamed-body(response);
    expect($csv.contains('Title') && $csv.contains('Alpha') && $csv.contains('Beta')).to.be-truthy;
  }

  it 'quotes values containing a comma', {
    seed-posts({ title => 'Has, comma' });
    expect(streamed-body(fetch('/admin/posts/export.csv')).contains('"Has, comma"')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin JSON export', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'One' }, { title => 'Two' });
  }

  it 'is rendered as application/json through the renderer registry', {
    expect(fetch('/admin/posts/export.json').header('Content-Type').contains('application/json')).to.be-truthy;
  }

  it 'has one object per record carrying the column values', {
    my @records = from-json(fetch('/admin/posts/export.json').body).list;
    expect(@records.elems == 2 && @records[0]<title> eq 'Two').to.be-truthy;
  }

  it 'honours the active filter', {
    expect(from-json(fetch('/admin/posts/export.json?title=One').body).list.elems).to.be(1);
  }
}
