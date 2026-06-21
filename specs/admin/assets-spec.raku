use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Assets;
use MVC::Keayl::Admin::AssetsController;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Parameters;

sub request($method, $path) {
  MVC::Keayl::Request.new(:$method, :$path)
}

sub mounted-host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

describe 'MVC::Keayl::Admin asset urls', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'mount-prefixes, namespaces, and fingerprints an asset url', {
    expect(MVC::Keayl::Admin::Assets.asset-url('bootstrap/bootstrap.min.css')
      .starts-with('/admin/admin-assets/bootstrap/bootstrap.min.css?')).to.be-truthy;
  }

  it 'computes a content digest for a vendored asset', {
    expect(MVC::Keayl::Admin::Assets.digest-of('htmx/htmx.min.js').defined).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin asset serving', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:response, { mounted-host.call(request('GET', '/admin/admin-assets/bootstrap/bootstrap.min.css')) });

  it 'serves a vendored asset', {
    expect(response.status).to.be(200);
  }

  it 'carries an immutable long-lived cache header', {
    expect(response.header('Cache-Control')).to.be('public, max-age=31536000, immutable');
  }

  it 'serves a css asset with the css content type', {
    expect(response.header('Content-Type')).to.be('text/css');
  }

  it 'refuses a path traversal attempt', {
    my $traversal = MVC::Keayl::Admin::AssetsController.new(
      params => MVC::Keayl::Parameters.new({ path => '../../META6.json' })
    ).dispatch('show');
    expect($traversal.status).to.be(404);
  }
}

describe 'MVC::Keayl::Admin import map', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'pins htmx to the vendored bundle', {
    expect(MVC::Keayl::Admin::Assets.import-map.imports<htmx.org>
      .contains('/admin/admin-assets/htmx/htmx.min.js')).to.be-truthy;
  }

  it 'pins bootstrap to the vendored bundle', {
    expect(MVC::Keayl::Admin::Assets.import-map.imports<bootstrap>
      .contains('/admin/admin-assets/bootstrap/bootstrap.bundle.min.js')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin override stylesheet', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.use-stylesheet('/css/custom-admin.css');
  }

  it 'layers the override after the vendored bundle', {
    my $tags = MVC::Keayl::Admin::Assets.stylesheet-tags;
    expect($tags.index('bootstrap/bootstrap.min.css') < $tags.index('/css/custom-admin.css')).to.be-truthy;
  }
}
