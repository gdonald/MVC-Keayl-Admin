use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

describe 'MVC::Keayl::Admin standalone page', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.page('reports', -> $controller {
      '<div class="report">Sales summary</div>'
    }, title => 'Reports', group => 'Tools', icon => 'graph-up');
  }

  it 'renders its block inside the admin layout', {
    my $body = fetch('/admin/reports').body;
    expect($body.contains('Sales summary') && $body.contains('navbar-brand')).to.be-truthy;
  }

  it 'uses its title for the document title', {
    expect(fetch('/admin/reports').body.contains('<title>Reports</title>')).to.be-truthy;
  }

  it 'shows its icon in the heading', {
    expect(fetch('/admin/reports').body.contains(q{<h1 class='h3 mb-3'><i class="bi bi-graph-up me-2"></i>Reports})).to.be-truthy;
  }

  it 'is linked and grouped in the menu', {
    my $menu = MVC::Keayl::Admin::Menu.render(mount => '/admin');
    expect($menu.contains('/admin/reports') && $menu.contains('menu-group-tools')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin hidden page', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.page('secret', -> $c { '<p>hush</p>' }, title => 'Secret', :hide);
  }

  it 'is still routable', {
    expect(fetch('/admin/secret').body.contains('hush')).to.be-truthy;
  }

  it 'renders a plain heading without an icon', {
    expect(fetch('/admin/secret').body.contains(q{<h1 class='h3 mb-3'>Secret})).to.be-truthy;
  }

  it 'is left out of the menu', {
    expect(MVC::Keayl::Admin::Menu.render(mount => '/admin').contains('/admin/secret')).to.be-falsy;
  }
}
