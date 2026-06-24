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

sub submit(Str:D $path, *@pairs) {
  my $body = @pairs.map({ .key ~ '=' ~ .value.subst(' ', '+', :g) }).join('&');

  host.call(MVC::Keayl::Request.new(
    method  => 'POST',
    target  => $path,
    headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
    body    => $body,
  ))
}

describe 'MVC::Keayl::Admin nested attributes', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-authors-nested;
  }

  it 'renders a nested array input for a has-many association', {
    expect(fetch('/admin/authors/new').body.contains('posts-attributes[][title]')).to.be-truthy;
  }

  it 'creates the nested children on create', {
    submit('/admin/authors',
      'name' => 'Ann',
      'posts-attributes[][title]' => 'First post',
      'posts-attributes[][title]' => 'Second post');

    expect(Author.where({ name => 'Ann' }).first.posts.list.elems).to.be(2);
  }

  it 'applies the nested attributes to each child', {
    submit('/admin/authors',
      'name' => 'Ann',
      'posts-attributes[][title]' => 'Only post');

    expect(Author.where({ name => 'Ann' }).first.posts.list[0].read-attribute('title')).to.be('Only post');
  }

  context 'with an existing author', {
    before-each {
      submit('/admin/authors', 'name' => 'Ann', 'posts-attributes[][title]' => 'Original');
    }

    let(:author, { Author.where({ name => 'Ann' }).first });

    it 'pre-fills the nested children in the edit form', {
      expect(fetch('/admin/authors/' ~ author.id ~ '/edit').body.contains('value="Original"')).to.be-truthy;
    }

    it 'updates an existing child by id', {
      my $post = author.posts.list[0];

      submit('/admin/authors/' ~ author.id,
        'name' => 'Ann',
        'posts-attributes[][id]'    => $post.id.Str,
        'posts-attributes[][title]' => 'Revised');

      expect(Post.where({ id => $post.id }).first.read-attribute('title')).to.be('Revised');
    }
  }
}
