use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

describe 'MVC::Keayl::Admin default table presentation', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'Tabular' });
  }

  it 'renders a table by default', {
    expect(fetch('/admin/posts').body.contains('<table')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin grid presentation', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-grid;
    seed-posts({ title => 'Gridded' });
  }

  let(:body, { fetch('/admin/posts').body });

  it 'renders a card grid from the per-record block', {
    expect(body.contains('row-cols') && body.contains('<h5 class="card-title">Gridded</h5>')).to.be-truthy;
  }

  it 'does not render a table', {
    expect(body.contains('<table')).to.be-falsy;
  }

  it 'preserves batch selection on the cards', {
    expect(body.contains('name="ids[]"') && body.contains('id="admin-batch-all"')).to.be-truthy;
  }

  it 'shows the empty state with no records', {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-grid;
    expect(fetch('/admin/posts').body.contains('No records yet')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin blog presentation', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-blog;
    seed-posts({ title => 'Posted' });
  }

  let(:body, { fetch('/admin/posts').body });

  it 'renders a stacked list from the per-record block', {
    expect(body.contains('admin-blog') && body.contains('<h2 class="post-headline">Posted</h2>')).to.be-truthy;
  }

  it 'still wraps the presentation in the index chrome', {
    expect(body.contains('Filters')).to.be-truthy;
  }
}

describe 'html-safe columns and attributes', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-html;
    seed-posts({ title => 'Raw' });
  }

  it 'emits raw markup from an :html column and escapes an ordinary one', {
    my $body = fetch('/admin/posts').body;
    expect($body.contains('<a href="/x">link</a>') && $body.contains('&lt;b&gt;bold')).to.be-truthy;
  }

  it 'emits raw markup from an :html show attribute', {
    my $id = MVC::Keayl::Admin.registry.all.first(*.model-name eq 'Post').model.all.all.first.id;
    expect(fetch("/admin/posts/$id").body.contains('<img src="/y">')).to.be-truthy;
  }
}

describe 'html-safe columns in a presentation without a per-record block', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-html-grid;
    seed-posts({ title => 'Raw' });
  }

  let(:body, { fetch('/admin/posts').body });

  it 'emits raw markup from an :html column in the default grid body', {
    expect(body.contains('<a href="/x">link</a>')).to.be-truthy;
  }

  it 'escapes an ordinary display column in the default grid body', {
    expect(body.contains('&lt;b&gt;bold')).to.be-truthy;
  }
}
