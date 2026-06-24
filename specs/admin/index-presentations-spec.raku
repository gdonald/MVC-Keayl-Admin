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
