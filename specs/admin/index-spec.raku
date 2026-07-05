use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub index-body {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(MVC::Keayl::Request.new(method => 'GET', path => '/admin/posts')).body
}

describe 'MVC::Keayl::Admin index table', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'First post', body => 'a', published => True }, { title => 'Second post', body => 'b' });
  }

  let(:body, { index-body });

  it 'renders a table', {
    expect(body.contains('<table')).to.be-truthy;
  }

  it 'wraps the table in a horizontal-scroll container so a wide table does not push the content column below the sidebar', {
    expect(body.contains('<div class="table-responsive">')).to.be-truthy;
  }

  it 'lists the records', {
    expect(body.contains('First post') && body.contains('Second post')).to.be-truthy;
  }

  it 'humanizes a column header from the column name', {
    expect(body.contains('Headline')).to.be-truthy;
  }

  it 'computes a cell value from a display block', {
    expect(body.contains('FIRST POST')).to.be-truthy;
  }

  it 'renders the boolean formatter per row', {
    expect(body.contains('Yes') && body.contains('No')).to.be-truthy;
  }

  it 'gives each row an edit action', {
    expect(body.contains('/admin/posts/1/edit')).to.be-truthy;
  }

  it 'gives each row a delete action', {
    expect(body.contains('hx-delete')).to.be-truthy;
  }

  it 'links a link-to-show column to the record', {
    expect(body.contains('href="/admin/posts/1"')).to.be-truthy;
  }

  it 'has a new-record button', {
    expect(body.contains('New Post')).to.be-truthy;
  }

  it 'renders the new-record button at a small size', {
    expect(body.contains('btn btn-primary btn-sm')).to.be-truthy;
  }

  it 'renders the filters button at a small size', {
    expect(body.contains('btn btn-secondary btn-sm') && body.contains('bi-funnel')).to.be-truthy;
  }

  it 'puts the new and filters buttons on the batch row above the table', {
    expect(body.index('data-batch-all') < body.index('New Post')
      && body.index('New Post') < body.index('<table')
      && body.index('bi-funnel') < body.index('<table')).to.be-truthy;
  }

  it 'pushes the toolbar buttons to the right of the batch controls', {
    expect(body.index('data-batch-all') < body.index('ms-auto')).to.be-truthy;
  }

  it 'places the export buttons after the record summary in the footer', {
    expect(body.index('Showing') < body.index('export.csv')).to.be-truthy;
  }

  it 'shows the record summary without pagination controls when everything fits on one page', {
    expect(body.contains('Showing 1&ndash;2 of 2') && !body.contains('class="pagination')).to.be-truthy;
  }

  it 'names a top-level index in a heading', {
    expect(body.contains(q{<h1 class='h3 mb-3'>Posts})).to.be-truthy;
  }

  it 'omits the breadcrumb on a top-level index, since the heading already names it', {
    expect(body.contains('aria-label="breadcrumb"')).to.be-falsy;
  }

  it 'styles row action buttons solid rather than outlined', {
    expect(body.contains('btn-secondary') && !body.contains('btn-outline')).to.be-truthy;
  }

  it 'places the filters button to the right of the new button', {
    expect(body.index('New Post') < body.index('bi-funnel')).to.be-truthy;
  }

  it 'places the export buttons below the table', {
    expect(body.index('</table>') < body.index('export.csv')).to.be-truthy;
  }

  it 'renders the export buttons at a small size', {
    expect(body.contains('btn-group-sm') && body.contains('btn btn-secondary btn-sm')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin column label override', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;

    register-posts-labeled;

    seed-posts({ title => 'First post' });
  }

  it 'uses the declared label as the column header', {
    expect(index-body.contains('Custom Heading')).to.be-truthy;
  }

  it 'suppresses the humanized column name when a label is given', {
    expect(index-body.contains('>Title<')).to.be-falsy;
  }
}

describe 'MVC::Keayl::Admin empty index', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts();
  }

  it 'shows an empty state', {
    expect(index-body.contains('No records yet')).to.be-truthy;
  }
}
