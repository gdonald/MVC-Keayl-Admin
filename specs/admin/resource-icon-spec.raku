use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Admin::Chrome;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub fetch(Str:D $path) {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  my $host   = MVC::Keayl::Dispatcher.new(:$router, controllers => []);
  $host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

sub heading-with-icon(Str:D $icon --> Str) {
  q{<h1 class='h3 mb-3'><i class="bi bi-} ~ $icon ~ q{ me-2"></i>}
}

setup-admin-db;

describe 'MVC::Keayl::Admin resource icons', {
  context 'a resource that sets its own icon', {
    before-each {
      MVC::Keayl::Admin.reset;
      register-posts-icon;
      register-authors;

      seed-posts({ title => 'First post', body => 'hello' });
    }

    let(:post, { Post.where({ title => 'First post' }).first });
    let(:menu, { MVC::Keayl::Admin::Menu.render(mount => '/admin', active-slug => 'posts') });

    it 'uses the resource icon in the sidebar', {
      expect(menu.contains('bi-newspaper')).to.be-truthy;
    }

    it 'falls back to the default sidebar icon for a resource without one', {
      expect(menu.contains('bi-list-ul')).to.be-truthy;
    }

    it 'shows the resource icon in the index heading', {
      expect(fetch('/admin/posts').body.contains(heading-with-icon('newspaper'))).to.be-truthy;
    }

    it 'shows the resource icon in the show heading', {
      expect(fetch("/admin/posts/{post.id}").body.contains(heading-with-icon('newspaper'))).to.be-truthy;
    }

    it 'shows the resource icon in the new form heading', {
      expect(fetch('/admin/posts/new').body.contains(heading-with-icon('newspaper'))).to.be-truthy;
    }

    it 'shows the resource icon in the edit form heading', {
      expect(fetch("/admin/posts/{post.id}/edit").body.contains(heading-with-icon('newspaper'))).to.be-truthy;
    }
  }

  context 'a resource with an explicit menu icon', {
    before-each {
      MVC::Keayl::Admin.reset;
      register-posts-icon-menu-override;
    }

    let(:menu, { MVC::Keayl::Admin::Menu.render(mount => '/admin', active-slug => 'posts') });

    it 'lets the menu icon win in the sidebar', {
      expect(menu.contains('bi-file-text')).to.be-truthy;
    }

    it 'does not also show the resource icon in the sidebar', {
      expect(menu.contains('bi-newspaper')).to.be-falsy;
    }

    it 'still uses the resource icon in the heading', {
      expect(fetch('/admin/posts').body.contains(heading-with-icon('newspaper'))).to.be-truthy;
    }
  }

  context 'the heading builder', {
    it 'renders a title without an icon as the escaped title', {
      expect(MVC::Keayl::Admin::Chrome.heading-html('Posts', Str)).to.eq('Posts');
    }

    it 'prefixes the escaped title with the icon', {
      expect(MVC::Keayl::Admin::Chrome.heading-html('Posts', 'newspaper').contains('<i class="bi bi-newspaper me-2"></i>Posts')).to.be-truthy;
    }

    it 'escapes the title', {
      expect(MVC::Keayl::Admin::Chrome.heading-html('<b>x</b>', Str)).to.eq('&lt;b&gt;x&lt;/b&gt;');
    }
  }
}
