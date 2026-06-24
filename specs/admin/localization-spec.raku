use BDD::Behave;
use MVC::Keayl::I18n;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::I18n;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub french {
  my $backend = MVC::Keayl::I18n.new(default-locale => 'fr');

  $backend.store-translations('fr', {
    activerecord => {
      models     => { post => 'Article' },
      attributes => { post => { title => 'Titre' } },
    },
    keayl_admin => {
      chrome  => { dashboard => 'Tableau de bord' },
      scopes  => { published => 'Publies' },
      actions => { approve => 'Approuver' },
    },
  });

  MVC::Keayl::Admin::I18n.use-backend($backend);
}

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

describe 'MVC::Keayl::Admin localized labels', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    french;
  }

  it 'localizes attribute labels', {
    expect(MVC::Keayl::Admin::I18n.attribute-label(Post, 'title')).to.be('Titre');
  }

  it 'localizes chrome strings', {
    expect(MVC::Keayl::Admin::I18n.chrome('dashboard', 'Dashboard')).to.be('Tableau de bord');
  }

  it 'localizes scope and action labels', {
    expect(MVC::Keayl::Admin::I18n.scope-label('published') eq 'Publies' && MVC::Keayl::Admin::I18n.action-label('approve') eq 'Approuver').to.be-truthy;
  }

  it 'reflects the locale in the rendered index', {
    seed-posts({ title => 'Bonjour' });
    my $index = fetch('/admin/posts').body;
    expect($index.contains('Titre') && $index.contains('Article') && $index.contains('Tableau de bord')).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin label fallback', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
  }

  it 'falls back to the humanized attribute name', {
    expect(MVC::Keayl::Admin::I18n.attribute-label(Post, 'title')).to.be('Title');
  }

  it 'falls back to the default chrome string', {
    expect(MVC::Keayl::Admin::I18n.chrome('dashboard', 'Dashboard')).to.be('Dashboard');
  }
}
