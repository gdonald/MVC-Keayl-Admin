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
    expect(fetch('/admin/posts/' ~ $post.id).body.contains('action="/admin/posts/' ~ $post.id ~ '/delete"')).to.be-truthy;
  }

  it 'confirms the destroy through a data attribute rather than a native alert', {
    seed-posts({ title => 'P', body => 'b' });
    my $body = fetch('/admin/posts/' ~ Post.where({ title => 'P' }).first.id).body;
    expect($body.contains('data-confirm=') && !$body.contains('onsubmit=')).to.be-truthy;
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

  it 'honors a :display override on a has-many attribute, rendering a summary', {
    MVC::Keayl::Admin.reset;
    register-authors-posts-summary;
    my $author = seed-authors({ name => 'Amy' })[0];
    seed-posts({ title => 'Alpha', author_id => $author.id }, { title => 'Beta', author_id => $author.id });
    my $body = fetch('/admin/authors/' ~ $author.id).body;

    aggregate-failures {
      expect($body.contains('Alpha')).to.be-truthy;
      expect($body.contains('Beta')).to.be-truthy;
      expect($body.contains('/admin/posts/')).to.be-falsy;
    }
  }

  it 'escapes a has-many :display summary unless the attribute is html', {
    MVC::Keayl::Admin.reset;
    register-authors-posts-summary;
    my $author = seed-authors({ name => 'Amy' })[0];
    seed-posts({ title => 'A<b>B', author_id => $author.id });
    my $body = fetch('/admin/authors/' ~ $author.id).body;

    aggregate-failures {
      expect($body.contains('A&lt;b&gt;B')).to.be-truthy;
      expect($body.contains('A<b>B')).to.be-falsy;
    }
  }

  it 'renders a has-many :display summary as raw markup when the attribute is html', {
    MVC::Keayl::Admin.reset;
    register-authors-posts-html-summary;
    my $author = seed-authors({ name => 'Amy' })[0];
    seed-posts({ title => 'Alpha', author_id => $author.id }, { title => 'Beta', author_id => $author.id });
    my $body = fetch('/admin/authors/' ~ $author.id).body;

    expect($body.contains('<em>Alpha, Beta</em>')).to.be-truthy;
  }

  it 'returns 404 for an unknown id', {
    expect(fetch('/admin/posts/999999').status).to.be(404);
  }

  it 'returns 404 for a non-numeric id', {
    expect(fetch('/admin/posts/not-a-number').status).to.be(404);
  }
}
