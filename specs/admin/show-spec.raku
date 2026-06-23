use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub fetch(Str:D $path) {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

describe 'MVC::Keayl::Admin show page', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    register-authors;
  }

  let(:ann, { seed-authors({ name => 'Ann' })[0] });

  it 'renders attribute values from declared attributes', {
    ann;
    seed-posts({ title => 'First post', body => 'hello', published => True });
    my $post = Post.where({ title => 'First post' }).first;
    expect(fetch('/admin/posts/' ~ $post.id).body.contains('First post')).to.be-truthy;
  }

  it 'renders the action panel with an edit link', {
    seed-posts({ title => 'P', body => 'b' });
    my $post = Post.where({ title => 'P' }).first;
    expect(fetch('/admin/posts/' ~ $post.id).body.contains('/admin/posts/' ~ $post.id ~ '/edit')).to.be-truthy;
  }

  it 'has a destroy control', {
    seed-posts({ title => 'P', body => 'b' });
    my $post = Post.where({ title => 'P' }).first;
    expect(fetch('/admin/posts/' ~ $post.id).body.contains('hx-delete="/admin/posts/' ~ $post.id ~ '"')).to.be-truthy;
  }

  it 'links a belongs-to attribute to the associated record', {
    my $author = ann;
    seed-posts({ title => 'P', body => 'b', author_id => $author.id });
    my $post = Post.where({ title => 'P' }).first;
    expect(fetch('/admin/posts/' ~ $post.id).body.contains('/admin/authors/' ~ $author.id)).to.be-truthy;
  }

  it 'renders no link for a missing belongs-to', {
    seed-posts({ title => 'P', body => 'b' });
    my $post = Post.where({ title => 'P' }).first;
    expect(fetch('/admin/posts/' ~ $post.id).body.contains('/admin/authors/')).to.be-falsy;
  }

  it 'renders a has-many attribute as links into the associated resource', {
    my $author = ann;
    seed-posts({ title => 'P', body => 'b', author_id => $author.id });
    my $post = Post.where({ title => 'P' }).first;
    expect(fetch('/admin/authors/' ~ $author.id).body.contains('/admin/posts/' ~ $post.id)).to.be-truthy;
  }

  it 'returns 404 for an unknown id', {
    expect(fetch('/admin/posts/999999').status).to.be(404);
  }

  it 'returns 404 for a non-numeric id', {
    expect(fetch('/admin/posts/not-a-number').status).to.be(404);
  }
}
