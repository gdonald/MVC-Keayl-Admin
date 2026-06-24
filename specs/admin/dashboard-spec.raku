use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub dashboard-body {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);

  $host.call(MVC::Keayl::Request.new(method => 'GET', target => '/admin')).body
}

describe 'MVC::Keayl::Admin dashboard', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    register-authors;
    seed-posts({ title => 'One' }, { title => 'Two' });
  }

  it 'renders at the mount root', {
    expect(dashboard-body.contains('Welcome to')).to.be-truthy;
  }

  it 'lists a registered resource linking to its index', {
    my $body = dashboard-body;
    expect($body.contains('Posts</h5>') && $body.contains('href="/admin/posts"')).to.be-truthy;
  }

  it 'shows the record count for a resource', {
    expect(dashboard-body.contains('>2<')).to.be-truthy;
  }

  it 'renders a custom dashboard block', {
    MVC::Keayl::Admin.dashboard-block(title => 'Recent activity', { '<p class="activity">nothing yet</p>' });
    my $body = dashboard-body;
    expect($body.contains('Recent activity') && $body.contains('<p class="activity">nothing yet</p>')).to.be-truthy;
  }
}
