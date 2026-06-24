use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Admin::Authorization;
use MVC::Keayl::Admin::Authorization::Policy;
use MVC::Keayl::Admin::Authorization::Role;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

class DenyDestroy is MVC::Keayl::Admin::Authorization::Policy {
  method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) { $action ne 'destroy' }
}

class DenyCreate is MVC::Keayl::Admin::Authorization::Policy {
  method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) { $action ne 'create' }
}

class OddRecordsOnly is MVC::Keayl::Admin::Authorization::Policy {
  method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) {
    return True without $record;
    $record.id %% 2 ?? False !! True
  }
}

class OnlyPublished is MVC::Keayl::Admin::Authorization::Policy {
  method scope($relation, :$admin, :$resource) { $relation.where({ published => True }) }
}

class HidePosts is MVC::Keayl::Admin::Authorization::Policy {
  method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) {
    !($action eq 'index' && $resource.defined && $resource.slug eq 'posts')
  }
}

class FakeAdmin { has $.role }

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub call(Str:D $method, Str:D $path) {
  host.call(MVC::Keayl::Request.new(:$method, target => $path))
}

sub prepare {
  MVC::Keayl::Admin.reset;
  setup-admin-db;
  register-posts;
}

describe 'MVC::Keayl::Admin authorization default', {
  before-each { prepare }

  it 'allows every action under the default policy', {
    expect(MVC::Keayl::Admin::Authorization.allows('destroy')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin forbidden action', {
  before-each {
    prepare;
    seed-posts({ title => 'Doomed' });
    MVC::Keayl::Admin.authorize-with(DenyDestroy.new);
  }

  let(:doomed, { Post.where({ title => 'Doomed' }).first });

  it 'responds with a 403 page', {
    my $response = call('POST', '/admin/posts/' ~ doomed.id ~ '/delete');
    expect($response.status == 403 && $response.body.contains('Forbidden')).to.be-truthy;
  }

  it 'does not run the forbidden action', {
    my $id = doomed.id;
    call('POST', '/admin/posts/' ~ $id ~ '/delete');
    expect(Post.where({ id => $id }).first.defined).to.be-truthy;
  }

  it 'still allows a permitted action', {
    expect(call('GET', '/admin/posts').status).to.be(200);
  }
}

describe 'MVC::Keayl::Admin record-level authorization', {
  before-each {
    prepare;
    seed-posts({ title => 'One' }, { title => 'Two' });
    MVC::Keayl::Admin.authorize-with(OddRecordsOnly.new);
  }

  it 'shows a permitted record', {
    my $odd = Post.all.all.first({ .id !%% 2 });
    expect(call('GET', '/admin/posts/' ~ $odd.id).status).to.be(200);
  }

  it 'forbids a record outside the policy', {
    my $even = Post.all.all.first({ .id %% 2 });
    expect(call('GET', '/admin/posts/' ~ $even.id).status).to.be(403);
  }
}

describe 'MVC::Keayl::Admin scoped visibility', {
  before-each {
    prepare;
    seed-posts({ title => 'Public', published => True }, { title => 'Private', published => False });
    MVC::Keayl::Admin.authorize-with(OnlyPublished.new);
  }

  it 'lists only records inside the policy scope', {
    my $index = call('GET', '/admin/posts').body;
    expect($index.contains('Public') && !$index.contains('Private')).to.be-truthy;
  }

  it 'cannot reach a record outside the scope', {
    my $private = Post.where({ title => 'Private' }).first;
    expect(call('GET', '/admin/posts/' ~ $private.id).status).to.be(404);
  }
}

describe 'MVC::Keayl::Admin hidden controls', {
  before-each {
    prepare;
    seed-posts({ title => 'Item' });
  }

  it 'hides the delete row action when destroy is forbidden', {
    MVC::Keayl::Admin.authorize-with(DenyDestroy.new);
    expect(call('GET', '/admin/posts').body.contains('hx-delete')).to.be-falsy;
  }

  it 'hides the new button when create is forbidden', {
    MVC::Keayl::Admin.authorize-with(DenyCreate.new);
    expect(call('GET', '/admin/posts').body.contains('>New Post<')).to.be-falsy;
  }

  it 'hides a forbidden resource from the menu', {
    MVC::Keayl::Admin.authorize-with(HidePosts.new);
    expect(MVC::Keayl::Admin::Menu.render(mount => '/admin').contains('/admin/posts')).to.be-falsy;
  }
}

describe 'MVC::Keayl::Admin role policy', {
  before-each { MVC::Keayl::Admin.reset }

  let(:policy, { MVC::Keayl::Admin::Authorization::Role.new(permissions => { editor => <index show>, super => <*> }) });

  it 'allows a permitted action for a role', {
    expect(policy.allows('index', admin => FakeAdmin.new(role => 'editor'))).to.be-truthy;
  }

  it 'denies an unlisted action for a role', {
    expect(policy.allows('destroy', admin => FakeAdmin.new(role => 'editor'))).to.be-falsy;
  }

  it 'allows everything for a wildcard role', {
    expect(policy.allows('destroy', admin => FakeAdmin.new(role => 'super'))).to.be-truthy;
  }

  it 'denies an admin without a role', {
    expect(policy.allows('index', admin => FakeAdmin)).to.be-falsy;
  }
}
