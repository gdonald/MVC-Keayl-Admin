use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Admin::DSL;
use MVC::Keayl::Admin::TestSupport;

setup-admin-db;

describe 'MVC::Keayl::Admin grouped menu', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.register(Post,   { column('title'); menu(group => 'Content', label => 'Articles', icon => 'file-text', priority => 2); });
    MVC::Keayl::Admin.register(Author, { column('name');  menu(group => 'Content', priority => 1); });
  }

  let(:html, { MVC::Keayl::Admin::Menu.render(mount => '/admin', active-slug => 'posts') });

  it 'has a dashboard entry', {
    expect(html.contains('Dashboard')).to.be-truthy;
  }

  it 'renders resources under a collapsible group section', {
    expect(html.contains('menu-group-content') && html.contains('data-bs-toggle="collapse"')).to.be-truthy;
  }

  it 'uses the overridden label and icon', {
    expect(html.contains('>Articles') && html.contains('bi-file-text')).to.be-truthy;
  }

  it 'highlights the current resource and expands its group', {
    expect(html.contains('nav-link active') && html.contains('collapse show')).to.be-truthy;
  }

  it 'orders items within a group by priority', {
    expect(html.index('/admin/authors') < html.index('/admin/posts')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin hidden menu entry', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.register(Post,   { column('title'); menu(:hide); });
    MVC::Keayl::Admin.register(Author, { column('name'); });
  }

  let(:html, { MVC::Keayl::Admin::Menu.render(mount => '/admin') });

  it 'leaves a hidden resource out of the menu', {
    expect(html.contains('/admin/posts')).to.be-falsy;
  }

  it 'keeps a visible resource', {
    expect(html.contains('/admin/authors')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin menu links and ordering', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.register(Post,   { column('title'); menu(group => 'Content'); });
    MVC::Keayl::Admin.register(Author, { column('name');  menu(group => 'System'); });
    MVC::Keayl::Admin.menu-group-order('System', 'Content');
    MVC::Keayl::Admin.menu-link(label => 'Docs', url => 'https://example.com/docs', group => 'System', :external);
    MVC::Keayl::Admin.menu-link(label => 'Reports', url => '/reports');
  }

  let(:html, { MVC::Keayl::Admin::Menu.render(mount => '/admin') });

  it 'honours the explicit group order', {
    expect(html.index('menu-group-system') < html.index('menu-group-content')).to.be-truthy;
  }

  it 'opens an external link in a new tab', {
    expect(html.contains('target="_blank"') && html.contains('href="https://example.com/docs"')).to.be-truthy;
  }

  it 'prefixes an internal link with the mount path', {
    expect(html.contains('href="/admin/reports"')).to.be-truthy;
  }
}
