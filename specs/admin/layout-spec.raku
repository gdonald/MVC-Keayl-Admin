use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Chrome;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;

sub request($method, $path) {
  MVC::Keayl::Request.new(:$method, :$path)
}

sub dashboard-body {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(request('GET', '/admin')).body
}

describe 'MVC::Keayl::Admin layout', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:body, { dashboard-body });

  it 'renders a full HTML document', {
    expect(body.contains('<html')).to.be-truthy;
  }

  it 'fills the document title from the page title', {
    expect(body.contains('<title>Dashboard</title>')).to.be-truthy;
  }

  it 'links the vendored stylesheet bundle', {
    expect(body.contains('rel="stylesheet"') && body.contains('bootstrap/bootstrap.min.css')).to.be-truthy;
  }

  it 'includes the htmx script', {
    expect(body.contains('htmx/htmx.min.js')).to.be-truthy;
  }

  it 'emits the import map', {
    expect(body.contains('type="importmap"')).to.be-truthy;
  }

  it 'renders the top bar with the brand', {
    expect(body.contains('navbar') && body.contains('navbar-brand')).to.be-truthy;
  }

  it 'renders a responsive offcanvas sidebar with a toggle target', {
    expect(body.contains('offcanvas') && body.contains('data-bs-target') && body.contains('#admin-sidebar')).to.be-truthy;
  }

  it 'exposes a hamburger toggler that hides at the large breakpoint', {
    expect(body.contains('navbar-toggler') && body.contains('d-lg-none')).to.be-truthy;
  }

  it 'carries the dark theme on the navbar so the toggler icon stays visible', {
    expect(body.contains(q{data-bs-theme='dark'})).to.be-truthy;
  }

  it 'names the page in a heading', {
    expect(body.contains(q{<h1 class='h3 mb-3'>Dashboard})).to.be-truthy;
  }

  it 'omits the breadcrumb on a top-level page, since the heading already names it', {
    expect(body.contains('aria-label="breadcrumb"')).to.be-falsy;
  }

  it 'renders a main content region', {
    expect(body.contains('<main')).to.be-truthy;
  }

  it 'gives the main region a flex-fill column so it sits beside the fixed-width sidebar', {
    expect(body.contains(q{<main id='admin-main' class='col })).to.be-truthy;
  }

  it 'does not pin the main region to a fixed column width that overflows the sidebar and wraps below it', {
    expect(body.contains('col-lg-10')).to.be-falsy;
  }

  it 'keeps the shell row from wrapping so the content column cannot drop below the sidebar', {
    expect(body.contains('flex-nowrap')).to.be-truthy;
  }

  it 'renders the dashboard content inside the layout', {
    expect(body.contains('Welcome to Admin')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin chrome', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'links the brand to the mount path', {
    expect(MVC::Keayl::Admin::Chrome.brand-html.contains('navbar-brand')
      && MVC::Keayl::Admin::Chrome.brand-html.contains('/admin')).to.be-truthy;
  }

  it 'marks the dashboard menu entry active at the mount root', {
    expect(MVC::Keayl::Admin::Menu.render(mount => '/admin', active-slug => '').contains('active')).to.be-truthy;
  }

  it 'renders empty breadcrumbs without crumbs', {
    expect(MVC::Keayl::Admin::Chrome.breadcrumbs-html([])).to.be('');
  }

  it 'renders a breadcrumb with a url as a link', {
    expect(MVC::Keayl::Admin::Chrome.breadcrumbs-html([ 'Posts' => '/admin/posts' ]).contains('href="/admin/posts"')).to.be-truthy;
  }

  it 'renders a breadcrumb without a url as the active page', {
    expect(MVC::Keayl::Admin::Chrome.breadcrumbs-html([ 'Posts' => Nil ]).contains('aria-current="page"')).to.be-truthy;
  }
}
