use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Predicate;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub fetch(Str:D $path, :%headers) {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(MVC::Keayl::Request.new(method => 'GET', target => $path, :%headers))
}

describe 'MVC::Keayl::Admin predicate compiler', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts(
      { title => 'Alpha post',  published => True },
      { title => 'Beta post',   published => False },
      { title => 'Gamma entry', published => True },
    );
  }

  it 'compiles cont to a substring match', {
    expect(apply-predicate(Post.all, 'title', 'cont', 'post').count).to.be(2);
  }

  it 'compiles eq to equality', {
    expect(apply-predicate(Post.all, 'title', 'eq', 'Beta post').count).to.be(1);
  }

  it 'compiles starts to a prefix match', {
    expect(apply-predicate(Post.all, 'title', 'starts', 'Gamma').count).to.be(1);
  }

  it 'compiles gteq to a range', {
    expect(apply-predicate(Post.all, 'id', 'gteq', 2).count).to.be(2);
  }

  it 'compiles in to an IN list', {
    expect(apply-predicate(Post.all, 'id', 'in', '1,3').count).to.be(2);
  }

  it 'compiles true to a boolean match', {
    expect(apply-predicate(Post.all, 'published', 'true', Nil).count).to.be(2);
  }
}

describe 'MVC::Keayl::Admin index filtering', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    seed-posts(
      { title => 'Alpha post',  published => True },
      { title => 'Beta post',   published => False },
      { title => 'Gamma entry', published => True },
    );
  }

  let(:cont, { fetch('/admin/posts?title=post').body });

  it 'narrows the index by substring', {
    expect(cont.contains('Alpha post') && cont.contains('Beta post') && !cont.contains('Gamma')).to.be-truthy;
  }

  it 'narrows the index by a boolean filter', {
    my $pub = fetch('/admin/posts?published=true').body;
    expect($pub.contains('Alpha post') && !$pub.contains('Beta post')).to.be-truthy;
  }

  it 'reflects the filtered count in the page summary', {
    expect(cont.contains('of 2')).to.be-truthy;
  }

  it 'shows a filters control', {
    expect(cont.contains('Filters')).to.be-truthy;
  }

  it 'shows a removable chip for an active filter', {
    expect(cont.contains('badge') && cont.contains('Title: post')).to.be-truthy;
  }

  it 'carries the active filter on sort links', {
    expect(cont.contains('title=post') && cont.contains('sort=title')).to.be-truthy;
  }

  it 'renders an input per declared filter', {
    expect(cont.contains('name="title"') && cont.contains('name="published"')).to.be-truthy;
  }
}
