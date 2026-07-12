use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub fetch(Str:D $path, :%headers) {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(MVC::Keayl::Request.new(method => 'GET', target => $path, :%headers))
}

describe 'MVC::Keayl::Admin index sorting', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'Banana' }, { title => 'Apple' }, { title => 'Cherry' });
  }

  let(:asc, { fetch('/admin/posts?sort=title&dir=asc').body });

  it 'orders rows ascending by the column', {
    expect(asc.index('Apple') < asc.index('Banana') < asc.index('Cherry')).to.be-truthy;
  }

  it 'reverses the order descending', {
    my $desc = fetch('/admin/posts?sort=title&dir=desc').body;
    expect($desc.index('Cherry') < $desc.index('Banana') < $desc.index('Apple')).to.be-truthy;
  }

  it 'carries an htmx sort link on a sortable header', {
    expect(asc.contains('hx-get') && asc.contains('sort=title')).to.be-truthy;
  }

  it 'offers a descending toggle for an ascending column', {
    expect(asc.contains('dir=desc')).to.be-truthy;
  }

  it 'shows a direction indicator on the active sort column', {
    expect(asc.contains('&uarr;')).to.be-truthy;
  }

  it 'defaults to id descending when no sort is requested', {
    my $default = fetch('/admin/posts').body;
    expect($default.index('Cherry') < $default.index('Apple') < $default.index('Banana')).to.be-truthy;
  }

  it 'leaves a non-sortable column header plain', {
    expect(fetch('/admin/posts').body.contains('<th>Headline</th>')).to.be-truthy;
  }

  it 'renders only the table fragment for an htmx request', {
    my $fragment = fetch('/admin/posts', headers => { 'HX-Request' => 'true' }).body;
    expect($fragment.contains('<table') && !$fragment.contains('<html')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin index pagination', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts(per-page => 2);
    seed-posts({ title => 'P1' }, { title => 'P2' }, { title => 'P3' }, { title => 'P4' }, { title => 'P5' });
  }

  let(:page1, { fetch('/admin/posts?page=1').body });

  it 'shows only the page slice', {
    expect(page1.contains('P5') && page1.contains('P4') && !page1.contains('P3')).to.be-truthy;
  }

  it 'reports the range and total in the summary', {
    expect(page1.contains('Showing 1&ndash;2 of 5')).to.be-truthy;
  }

  it 'renders a pagination control', {
    expect(page1.contains('pagination')).to.be-truthy;
  }

  it 'renders the pagination control at a small size', {
    expect(page1.contains('pagination pagination-sm')).to.be-truthy;
  }

  it 'sits the record summary to the right of the pagination buttons', {
    expect(page1.index('class="pagination') < page1.index('Showing 1')).to.be-truthy;
  }

  it 'shows a later page slice', {
    my $page3 = fetch('/admin/posts?page=3').body;
    expect($page3.contains('P1') && !$page3.contains('P5')).to.be-truthy;
  }

  it 'preserves sort state in pagination links', {
    expect(fetch('/admin/posts?page=1&sort=title&dir=desc').body.contains('sort=title')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin per-page', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'is configurable per resource', {
    register-posts(per-page => 2);
    expect(MVC::Keayl::Admin.registry.by-slug('posts').per-page).to.be(2);
  }

  it 'defaults to 25', {
    register-posts;
    expect(MVC::Keayl::Admin.registry.by-slug('posts').per-page).to.be(25);
  }
}
