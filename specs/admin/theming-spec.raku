use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Assets;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;

my $fixtures = $?FILE.IO.parent.parent.parent.add('t/fixtures/theme').Str;

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

describe 'MVC::Keayl::Admin host view overrides', {
  before-each { MVC::Keayl::Admin.reset }

  it 'lets a host view path override an engine template', {
    MVC::Keayl::Admin.view-path($fixtures);
    expect(fetch('/admin').body.contains('host-themed-dashboard')).to.be-truthy;
  }

  it 'renders the engine template when no override is registered', {
    my $body = fetch('/admin').body;
    expect($body.contains('Welcome to') && !$body.contains('host-themed-dashboard')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin theme', {
  before-each { MVC::Keayl::Admin.reset }

  it 'defines documented CSS variables', {
    expect(MVC::Keayl::Admin::Assets.theme-tag.contains('--keayl-admin-sidebar-bg')).to.be-truthy;
  }

  it 'layers the theme after the Bootstrap bundle', {
    my $tags = MVC::Keayl::Admin::Assets.stylesheet-tags;
    expect($tags.index('bootstrap/bootstrap.min.css') < $tags.index('--keayl-admin-sidebar-bg')).to.be-truthy;
  }

  it 'loads a host stylesheet after the theme so its values win', {
    MVC::Keayl::Admin.use-stylesheet('/custom/admin-theme.css');
    my $tags = MVC::Keayl::Admin::Assets.stylesheet-tags;
    expect($tags.index('--keayl-admin-sidebar-bg') < $tags.index('/custom/admin-theme.css')).to.be-truthy;
  }
}
