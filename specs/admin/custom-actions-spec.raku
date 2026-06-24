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

sub send(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'POST', target => $path))
}

describe 'MVC::Keayl::Admin member actions', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'One', published => False }, { title => 'Two', published => False });
  }

  let(:post-record, { Post.all.all[0] });

  it 'renders a confirming button on the show page', {
    my $body = fetch('/admin/posts/' ~ post-record.id).body;
    expect($body.contains('/approve"') && $body.contains('Approve this post?')).to.be-truthy;
  }

  it 'runs the handler over the record and returns its response', {
    my $id = post-record.id;
    my $response = send('/admin/posts/' ~ $id ~ '/approve');
    expect($response.status == 302 && Post.where({ id => $id }).first.read-attribute('published')).to.be-truthy;
  }

  it 'is a 404 for an unknown member action', {
    expect(send('/admin/posts/' ~ post-record.id ~ '/nope').status).to.be(404);
  }
}

describe 'MVC::Keayl::Admin collection actions', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts({ title => 'One', published => False }, { title => 'Two', published => False });
  }

  it 'renders a button on the index', {
    expect(fetch('/admin/posts').body.contains('action="/admin/posts/publish-all"')).to.be-truthy;
  }

  it 'runs the handler over the whole relation', {
    send('/admin/posts/publish-all');
    expect(Post.all.all.map(*.read-attribute('published')).all.so).to.be-truthy;
  }
}
