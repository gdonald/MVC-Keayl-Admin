use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub encode($value) {
  $value.Str.subst(/(<-[A..Za..z0..9._-]>)/, { '%' ~ $0.ord.fmt('%02X') }, :g)
}

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

sub submit(Str:D $path, %fields) {
  my $body = %fields.map({ .key ~ '=' ~ encode(.value) }).join('&');

  host.call(MVC::Keayl::Request.new(
    method  => 'POST',
    target  => $path,
    headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
    body    => $body,
  ))
}

describe 'MVC::Keayl::Admin form rendering', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    register-authors;
    seed-authors({ name => 'Ann' });
  }

  let(:new-form, { fetch('/admin/posts/new').body });

  it 'renders a text input for a string field', {
    expect(new-form.contains('name="title"')).to.be-truthy;
  }

  it 'renders a textarea for a text field', {
    expect(new-form.contains('<textarea')).to.be-truthy;
  }

  it 'renders a checkbox for a boolean field', {
    expect(new-form.contains('type="checkbox"')).to.be-truthy;
  }

  it 'renders select options from a collection', {
    expect(new-form.contains('<select') && new-form.contains('Ann')).to.be-truthy;
  }

  it 'renders a placeholder and a hint', {
    expect(new-form.contains('placeholder="Headline"') && new-form.contains('Keep it short.')).to.be-truthy;
  }

  it 'shows the parent as a breadcrumb link without repeating the current page as a crumb', {
    expect(new-form.contains('<li class="breadcrumb-item"><a href="/admin/posts">')
      && !new-form.contains('aria-current="page"')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin create', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    register-authors;
  }

  it 'redirects to the show page on success', {
    my $response = submit('/admin/posts', { title => 'A post', body => 'Hello' });
    expect($response.status).to.be(302);
  }

  it 'persists the permitted attributes', {
    submit('/admin/posts', { title => 'A post', body => 'Hello' });
    expect(Post.where({ title => 'A post' }).first.read-attribute('body')).to.be('Hello');
  }

  it 'ignores an unpermitted attribute', {
    submit('/admin/posts', { title => 'Sneaky', id => '99999' });
    expect(Post.where({ title => 'Sneaky' }).first.id != 99999).to.be-truthy;
  }

  it 're-renders the form with errors on failure', {
    my $response = submit('/admin/posts', { title => '', body => 'x' });
    expect($response.status == 200 && $response.body.contains('must be present')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin update', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    register-authors;
    seed-posts({ title => 'Original', body => 'b' });
  }

  let(:post, { Post.where({ title => 'Original' }).first });

  it 'pre-fills the edit form', {
    expect(fetch('/admin/posts/' ~ post.id ~ '/edit').body.contains('value="Original"')).to.be-truthy;
  }

  it 'persists the change on success', {
    submit('/admin/posts/' ~ post.id, { title => 'Renamed', body => 'b' });
    expect(Post.where({ id => post.id }).first.read-attribute('title')).to.be('Renamed');
  }

  it 're-renders the form with errors on failure', {
    my $response = submit('/admin/posts/' ~ post.id, { title => '', body => 'b' });
    expect($response.status == 200 && $response.body.contains('must be present')).to.be-truthy;
  }
}
