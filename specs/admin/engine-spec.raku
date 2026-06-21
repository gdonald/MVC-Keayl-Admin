use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Engine;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;

sub request($method, $path) {
  MVC::Keayl::Request.new(:$method, :$path)
}

sub mounted-host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

describe 'MVC::Keayl::Admin engine', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:engine, { MVC::Keayl::Admin.engine });

  it 'is an admin engine', {
    expect(engine() ~~ MVC::Keayl::Admin::Engine).to.be-truthy;
  }

  it 'isolates the admin namespace', {
    expect(engine.namespace).to.be('MVC::Keayl::Admin');
  }

  it 'declares a view path', {
    expect(engine.view-paths.elems > 0).to.be-truthy;
  }

  it 'declares an asset path', {
    expect(engine.asset-paths.elems > 0).to.be-truthy;
  }

  it 'declares a helper path', {
    expect(engine.helper-paths.elems > 0).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin mounting', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'serves the dashboard below the mount point', {
    expect(mounted-host.call(request('GET', '/admin')).body.contains('Admin')).to.be-truthy;
  }

  context 'with a configured site title', {
    before-each {
      MVC::Keayl::Admin.configure(site-title => 'Control Panel');
    }

    it 'renders the configured site title', {
      expect(mounted-host.call(request('GET', '/admin')).body.contains('Control Panel')).to.be-truthy;
    }
  }
}

describe 'MVC::Keayl::Admin mount path', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'defaults to /admin', {
    expect(MVC::Keayl::Admin.config.mount-path).to.be('/admin');
  }

  context 'when configured', {
    before-each {
      MVC::Keayl::Admin.configure(mount-path => '/manage');
    }

    it 'reflects the configured path', {
      expect(MVC::Keayl::Admin.config.mount-path).to.be('/manage');
    }
  }
}
