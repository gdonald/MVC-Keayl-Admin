use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub call(Str:D $method, Str:D $path, Str :$body) {
  my %args = :$method, target => $path;

  if $body.defined {
    %args<body>    = $body;
    %args<headers> = { 'Content-Type' => 'application/x-www-form-urlencoded' };
  }

  host.call(MVC::Keayl::Request.new(|%args))
}

describe 'MVC::Keayl::Admin nested resources', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-authors;
    register-posts-nested;

    my $alice = Author.create({ name => 'Alice' });
    my $bob   = Author.create({ name => 'Bob' });

    Post.create({ title => 'Alice One', author_id => $alice.id });
    Post.create({ title => 'Alice Two', author_id => $alice.id });
    Post.create({ title => 'Bob One',   author_id => $bob.id });
  }

  let(:alice, { Author.where({ name => 'Alice' }).first });
  let(:abase, { '/admin/authors/' ~ alice().id ~ '/posts' });

  it 'scopes the nested index to the parent', {
    my $body = call('GET', abase()).body;
    expect($body.contains('Alice One') && $body.contains('Alice Two') && !$body.contains('Bob One')).to.be-truthy;
  }

  it 'shows the parent chain in the breadcrumbs', {
    my $body = call('GET', abase()).body;
    expect($body.contains('Authors') && $body.contains('Alice')).to.be-truthy;
  }

  it 'links the new button into the parent path', {
    expect(call('GET', abase()).body.contains('href="' ~ abase() ~ '/new"')).to.be-truthy;
  }

  it 'fixes the parent foreign key on create', {
    call('POST', abase(), body => 'title=Created Nested');
    my $created = Post.where({ title => 'Created Nested' }).first;
    expect($created.defined && $created.read-attribute('author_id') == alice().id).to.be-truthy;
  }

  it 'shows a record under its parent', {
    my $post = Post.where({ title => 'Alice One' }).first;
    expect(call('GET', abase() ~ '/' ~ $post.id).status).to.be(200);
  }

  it 'is a 404 for a record under a different parent', {
    my $bob-post = Post.where({ title => 'Bob One' }).first;
    expect(call('GET', abase() ~ '/' ~ $bob-post.id).status).to.be(404);
  }

  it 'links the parent show page to the nested resource', {
    expect(call('GET', '/admin/authors/' ~ alice().id).body.contains('href="' ~ abase() ~ '"')).to.be-truthy;
  }

  it 'hides the nested resource from the top menu', {
    expect(MVC::Keayl::Admin::Menu.render(mount => '/admin').contains('href="/admin/posts"')).to.be-falsy;
  }

  it 'still serves the standalone index over every record', {
    my $body = call('GET', '/admin/posts').body;
    expect($body.contains('Alice One') && $body.contains('Bob One')).to.be-truthy;
  }
}
