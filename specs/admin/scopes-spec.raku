use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub fetch(Str:D $path) {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

describe 'MVC::Keayl::Admin scopes', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts(
      { title => 'Alpha', published => True },
      { title => 'Beta',  published => False },
      { title => 'Gamma', published => True },
    );
  }

  let(:default-body,   { fetch('/admin/posts').body });
  let(:published-body, { fetch('/admin/posts?scope=Published').body });

  it 'shows every record under the default scope', {
    expect(default-body.contains('Alpha') && default-body.contains('Beta') && default-body.contains('Gamma')).to.be-truthy;
  }

  it 'applies a scope block to the relation', {
    expect(published-body.contains('Alpha') && !published-body.contains('Beta') && published-body.contains('Gamma')).to.be-truthy;
  }

  it 'renders scope tabs', {
    expect(default-body.contains('nav-tabs')).to.be-truthy;
  }

  it 'highlights the active scope tab', {
    expect(published-body.contains('nav-link active') && published-body.contains('Published')).to.be-truthy;
  }

  it 'shows per-scope counts', {
    expect(default-body.contains('badge')).to.be-truthy;
  }

  it 'composes a scope with a filter', {
    my $composed = fetch('/admin/posts?scope=Published&title=Alpha').body;
    expect($composed.contains('Alpha') && !$composed.contains('Gamma')).to.be-truthy;
  }

  it 'preserves the active scope on sort links', {
    expect(published-body.contains('scope=Published') && published-body.contains('sort=title')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin suppressible scope counts', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts(scope-counts => False);
    seed-posts({ title => 'Alpha', published => True });
  }

  it 'omits the count badges', {
    my $body = fetch('/admin/posts').body;
    expect($body.contains('nav-tabs') && !($body ~~ /'nav-link' .*? 'badge'/)).to.be-truthy;
  }
}
