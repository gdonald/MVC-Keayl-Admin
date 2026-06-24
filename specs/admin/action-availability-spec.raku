use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Authorization::Policy;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

class AvailDenyDestroy is MVC::Keayl::Admin::Authorization::Policy {
  method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) {
    $action ne 'destroy'
  }
}

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub call(Str:D $method, Str:D $path) {
  host.call(MVC::Keayl::Request.new(:$method, target => $path))
}

describe 'MVC::Keayl::Admin read-only resource', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-readonly;
    seed-posts({ title => 'Readme' });
  }

  let(:record-id, { Post.all.all[0].id });

  it 'serves index and show', {
    expect(call('GET', '/admin/posts').status == 200 && call('GET', '/admin/posts/' ~ record-id()).status == 200).to.be-truthy;
  }

  it 'leaves edit and destroy unrouted', {
    expect(call('GET', '/admin/posts/' ~ record-id() ~ '/edit').status == 404 && call('POST', '/admin/posts/' ~ record-id() ~ '/delete').status == 404).to.be-truthy;
  }

  it 'hides the new, edit, and delete controls', {
    my $body = call('GET', '/admin/posts').body;
    expect(!$body.contains('>New Post<') && !$body.contains('hx-delete')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin excluded destroy', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-no-destroy;
    seed-posts({ title => 'Keeper' });
  }

  it 'keeps edit but unroutes destroy', {
    my $id = Post.all.all[0].id;
    expect(call('GET', '/admin/posts/' ~ $id ~ '/edit').status == 200 && call('POST', '/admin/posts/' ~ $id ~ '/delete').status == 404).to.be-truthy;
  }

  it 'drops the batch destroy option', {
    expect(call('GET', '/admin/posts').body.contains('>Destroy<')).to.be-falsy;
  }
}

describe 'MVC::Keayl::Admin default sort order', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-sorted;
    seed-posts({ title => 'Apple' }, { title => 'Cherry' }, { title => 'Banana' });
  }

  it 'applies the declared order when no sort is given', {
    my $body = call('GET', '/admin/posts').body;
    expect($body.index('Cherry') < $body.index('Banana') < $body.index('Apple')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin disabled filters and batch', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
  }

  it 'removes the filter control when filters are disabled', {
    register-posts-no-filters;
    seed-posts({ title => 'A' });
    expect(call('GET', '/admin/posts').body.contains('Filters')).to.be-falsy;
  }

  it 'removes the batch controls when batch actions are disabled', {
    register-posts-no-batch;
    seed-posts({ title => 'A' });
    my $body = call('GET', '/admin/posts').body;
    expect($body.contains('name="ids[]"') || $body.contains('id="admin-batch-all"')).to.be-falsy;
  }
}

describe 'MVC::Keayl::Admin toolbar action items', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-action-items;
    seed-posts({ title => 'Item' });
  }

  let(:record-id, { Post.all.all[0].id });

  it 'shows an index-only item on the index but not the show page', {
    expect(call('GET', '/admin/posts').body.contains('ai-index') && !call('GET', '/admin/posts/' ~ record-id()).body.contains('ai-index')).to.be-truthy;
  }

  it 'shows a show-only item on the show page but not the index', {
    expect(call('GET', '/admin/posts/' ~ record-id()).body.contains('ai-show') && !call('GET', '/admin/posts').body.contains('ai-show')).to.be-truthy;
  }

  it 'hides an ability-gated item when the policy forbids it', {
    MVC::Keayl::Admin.authorize-with(AvailDenyDestroy.new);
    expect(call('GET', '/admin/posts').body.contains('ai-danger')).to.be-falsy;
  }
}
