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
