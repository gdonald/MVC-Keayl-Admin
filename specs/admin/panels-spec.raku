use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Authorization::Policy;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

class PanelsDenyDestroy is MVC::Keayl::Admin::Authorization::Policy {
  method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) {
    $action ne 'destroy'
  }
}

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

describe 'MVC::Keayl::Admin content panels', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-panels;
    seed-posts({ title => 'Subject' });
  }

  let(:record-id, { Post.all.all[0].id });
  let(:index,     { fetch('/admin/posts').body });
  let(:show,      { fetch('/admin/posts/' ~ record-id).body });

  it 'renders sidebar sections in the index right column', {
    expect(index.contains('col-lg-3') && index.contains('Need help?') && index.contains('index tip')).to.be-truthy;
  }

  it 'renders a panel in the show main column with the record', {
    expect(show.contains('<div class="notes">Subject</div>')).to.be-truthy;
  }

  it 'renders tabs as a tabbed card', {
    expect(show.contains('nav-tabs') && show.contains('tab-overview') && show.contains('tab-history')).to.be-truthy;
  }

  it 'honours sidebar placement', {
    expect(show.contains('Need help?') && !show.contains('index tip')).to.be-truthy;
  }

  it 'shows an ability-gated sidebar under the default policy', {
    expect(index.contains('audit log') && show.contains('audit log')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin gated panels', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts-panels;
    seed-posts({ title => 'Subject' });
    MVC::Keayl::Admin.authorize-with(PanelsDenyDestroy.new);
  }

  it 'hides an ability-gated sidebar when the policy forbids it', {
    my $id = Post.all.all[0].id;
    expect(fetch('/admin/posts').body.contains('audit log') || fetch('/admin/posts/' ~ $id).body.contains('audit log')).to.be-falsy;
  }

  it 'still renders ungated sidebars', {
    expect(fetch('/admin/posts').body.contains('Need help?')).to.be-truthy;
  }
}
