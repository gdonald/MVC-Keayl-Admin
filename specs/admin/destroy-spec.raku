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

sub call(Str:D $method, Str:D $path) {
  host.call(MVC::Keayl::Request.new(:$method, target => $path))
}

describe 'MVC::Keayl::Admin destroy', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'Doomed', body => 'b' });
  }

  let(:doomed, { Post.where({ title => 'Doomed' }).first });

  it 'renders an in-place htmx delete control on each row', {
    doomed;
    my $index = call('GET', '/admin/posts').body;
    expect($index.contains('hx-delete=') && $index.contains('hx-swap="delete"') && $index.contains('hx-confirm')).to.be-truthy;
  }

  it 'destroys the record on an htmx delete', {
    my $id = doomed.id;
    call('DELETE', '/admin/posts/' ~ $id);
    expect(Post.where({ id => $id }).first.defined).to.be-falsy;
  }

  it 'returns an empty body so the row is removed in place', {
    expect(call('DELETE', '/admin/posts/' ~ doomed.id).body).to.be('');
  }

  it 'deletes from the show page via a redirecting form', {
    my $id = doomed.id;
    my $response = call('POST', '/admin/posts/' ~ $id ~ '/delete');
    expect($response.status == 302 && $response.header('Location') eq '/admin/posts').to.be-truthy;
  }

  it 'is a 404 for an unknown record', {
    expect(call('DELETE', '/admin/posts/999999').status).to.be(404);
  }
}
