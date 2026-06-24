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

describe 'MVC::Keayl::Admin status tags', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-status;
    seed-posts({ title => 'Live', published => True });
  }

  it 'renders a colored badge for a status-tag column', {
    my $body = fetch('/admin/posts').body;
    expect($body.contains('badge text-bg-success') && $body.contains('>Active</span>')).to.be-truthy;
  }

  it 'renders a boolean status-tag on the show page', {
    my $id = Post.all.all[0].id;
    my $body = fetch('/admin/posts/' ~ $id).body;
    expect($body.contains('badge text-bg-success') && $body.contains('>Yes</span>')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin export columns', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-csv;
    seed-posts({ title => 'Alpha', body => 'Body text' });
  }

  it 'uses the declared export column for CSV', {
    my $csv = streamed-body(fetch('/admin/posts/export.csv'));
    expect($csv.contains('Alpha') && !$csv.contains('Body text')).to.be-truthy;
  }

  it 'uses the declared export column for JSON', {
    my @json = from-json(fetch('/admin/posts/export.json').body).list;
    expect((@json[0]<title>:exists) && !(@json[0]<body>:exists)).to.be-truthy;
  }

  it 'exports XML through the renderer registry', {
    my $response = fetch('/admin/posts/export.xml');
    expect($response.header('Content-Type').contains('application/xml') && $response.body.contains('<title>Alpha</title>')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin export toggle', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
  }

  it 'unroutes export and hides links when disabled', {
    register-posts-no-export;
    seed-posts({ title => 'X' });
    expect(fetch('/admin/posts/export.csv').status == 404 && !fetch('/admin/posts').body.contains('export.csv')).to.be-truthy;
  }

  it 'limits the offered formats', {
    register-posts-csv-only;
    seed-posts({ title => 'X' });
    my $body = fetch('/admin/posts').body;
    expect(fetch('/admin/posts/export.csv').status == 200 && fetch('/admin/posts/export.json').status == 404 && $body.contains('export.csv') && !$body.contains('export.json')).to.be-truthy;
  }
}
