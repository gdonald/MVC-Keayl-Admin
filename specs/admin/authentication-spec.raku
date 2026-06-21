use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::Authentication::Basic;
use MVC::Keayl::Admin::Authentication::Session;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::HttpAuthentication;

sub fetch($path, :$authorization) {
  my %headers = $authorization.defined ?? (Authorization => $authorization) !! ();
  my $router  = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host    = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(MVC::Keayl::Request.new(method => 'GET', path => $path, :%headers))
}

describe 'MVC::Keayl::Admin without an authentication strategy', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'leaves the admin open', {
    expect(fetch('/admin').status).to.be(200);
  }
}

describe 'MVC::Keayl::Admin with a basic-auth gate', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.authenticate-with(
      MVC::Keayl::Admin::Authentication::Basic.new(name => 'admin', password => 'secret', realm => 'Admin')
    );
  }

  it 'challenges an unauthenticated visitor', {
    expect(fetch('/admin').status).to.be(401);
  }

  it 'asks for basic credentials in the challenge', {
    expect(fetch('/admin').header('WWW-Authenticate').contains('Basic')).to.be-truthy;
  }

  it 'rejects invalid credentials', {
    expect(fetch('/admin', authorization => encode-basic-credentials('admin', 'wrong')).status).to.be(401);
  }

  it 'admits valid credentials', {
    expect(fetch('/admin', authorization => encode-basic-credentials('admin', 'secret')).status).to.be(200);
  }

  it 'exposes the current admin to the view', {
    expect(fetch('/admin', authorization => encode-basic-credentials('admin', 'secret')).body.contains('Signed in as admin')).to.be-truthy;
  }

  it 'serves assets without authentication', {
    expect(fetch('/admin/admin-assets/htmx/htmx.min.js').status).to.be(200);
  }
}

describe 'MVC::Keayl::Admin session authentication strategy', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:strategy, { MVC::Keayl::Admin::Authentication::Session.new(key => 'admin_id', login-path => '/admin/login') });

  context 'with a signed-in visitor', {
    let(:controller, {
      my $c = MVC::Keayl::Admin::Controller.new;
      $c.session<admin_id> = 7;
      $c
    });

    it 'returns the stored admin id', {
      expect(strategy.authenticate(controller)).to.be(7);
    }
  }

  context 'with an anonymous visitor', {
    let(:controller, { MVC::Keayl::Admin::Controller.new });

    it 'returns nothing', {
      expect(strategy.authenticate(controller).defined).to.be-falsy;
    }

    it 'redirects to the login path', {
      expect(strategy.challenge(controller).status).to.be(302);
    }

    it 'targets the configured login path', {
      expect(strategy.challenge(controller).header('Location')).to.be('/admin/login');
    }
  }

  context 'with a resolver', {
    let(:resolving, { MVC::Keayl::Admin::Authentication::Session.new(resolve => -> $id { "admin-$id" }) });
    let(:controller, {
      my $c = MVC::Keayl::Admin::Controller.new;
      $c.session<admin_id> = 5;
      $c
    });

    it 'maps the stored id to an admin', {
      expect(resolving.authenticate(controller)).to.be('admin-5');
    }
  }
}
