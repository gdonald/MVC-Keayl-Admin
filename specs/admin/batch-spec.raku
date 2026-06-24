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

sub batch(Str:D $action, *@ids) {
  my $body = (@ids.map({ 'ids[]=' ~ $_ }).Slip, 'batch-action=' ~ $action).join('&');

  host.call(MVC::Keayl::Request.new(
    method  => 'POST',
    target  => '/admin/posts/batch',
    headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
    body    => $body,
  ))
}

describe 'MVC::Keayl::Admin batch selection', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'One' }, { title => 'Two' }, { title => 'Three' });
  }

  let(:index, { fetch('/admin/posts').body });

  it 'renders a select-all-on-page control', {
    expect(index.contains('data-batch-all')).to.be-truthy;
  }

  it 'renders a selection checkbox per row', {
    expect(index.contains('data-batch-select') && index.contains('name="ids[]"')).to.be-truthy;
  }

  it 'renders a selected-count indicator', {
    expect(index.contains('data-batch-count')).to.be-truthy;
  }

  it 'offers batch destroy and a custom batch action', {
    expect(index.contains('>Destroy<') && index.contains('>Publish<')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin batch destroy', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'One' }, { title => 'Two' }, { title => 'Three' });
  }

  it 'destroys the selected records and redirects', {
    my @posts = Post.all.all;
    my $response = batch('Destroy', @posts[0].id, @posts[1].id);
    expect($response.status == 302 && Post.all.count == 1).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin custom batch action', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'A', published => False }, { title => 'B', published => False });
  }

  it 'runs its block over the selected records', {
    my @posts = Post.all.all;
    batch('Publish', @posts[0].id);
    expect(Post.where({ id => @posts[0].id }).first.read-attribute('published')).to.be-truthy;
  }

  it 'leaves unselected records untouched', {
    my @posts = Post.all.all;
    batch('Publish', @posts[0].id);
    expect(Post.where({ id => @posts[1].id }).first.read-attribute('published')).to.be-falsy;
  }
}
