use v6.d;
use MVC::Keayl::Controller;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Assets;
use MVC::Keayl::Admin::Chrome;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Admin::Authentication;

class MVC::Keayl::Admin::Controller is MVC::Keayl::Controller {
  has %.admin-context;
  has $.current-admin;

  method authenticate-admin {
    my $strategy = MVC::Keayl::Admin::Authentication.strategy;

    return without $strategy;

    my $admin = $strategy.authenticate(self);

    if $admin.defined {
      $!current-admin = $admin;
    } else {
      $strategy.challenge(self);
    }
  }

  method dispatch(Str:D $action) {
    callwith($action eq 'new' ?? 'new-record' !! $action)
  }

  method set-admin-context {
    my $config = MVC::Keayl::Admin::Config.current;

    %!admin-context = (
      site-title => $config.site-title,
      mount-path => $config.mount-path,
      path       => self.request.defined ?? self.request.path !! '',
    );
  }

  method forbidden {
    my $mount = MVC::Keayl::Admin::Config.current.mount-path;

    self.assign('admin_forbidden_body', qq:to/HTML/.trim);
    <div class="text-center py-5">
      <i class="bi bi-shield-lock display-1 text-muted"></i>
      <h1 class="h3 mt-3">Forbidden</h1>
      <p class="text-muted">You are not allowed to perform this action.</p>
      <a class="btn btn-primary" href="$mount">Back to dashboard</a>
    </div>
    HTML

    my $response = self.render-admin(
      'errors/forbidden',
      page-title => 'Forbidden',
    );

    self.response.status = 403;

    $response
  }

  method render-admin($template, Str :$page-title, Str :$icon, :@breadcrumbs, *%options) {
    my $config = MVC::Keayl::Admin::Config.current;
    my $path   = self.request.defined ?? self.request.path !! '';

    self.assign('site_title', $config.site-title);
    self.assign('mount_path', $config.mount-path);
    my $title = $page-title // $config.site-title;

    self.assign('page_title', $title);
    self.assign('admin_heading', MVC::Keayl::Admin::Chrome.heading-html($title, $icon));

    self.assign('admin_styles',    MVC::Keayl::Admin::Assets.stylesheet-tags);
    self.assign('admin_scripts',   MVC::Keayl::Admin::Assets.script-tags);
    self.assign('admin_importmap', MVC::Keayl::Admin::Assets.importmap-tags);

    self.assign('admin_brand',       MVC::Keayl::Admin::Chrome.brand-html);
    my $active-slug = $path.split('/').grep(*.chars).head // '';
    self.assign('admin_menu',        MVC::Keayl::Admin::Menu.render(mount => $config.mount-path, :$active-slug, admin => $!current-admin));
    self.assign('admin_breadcrumbs', MVC::Keayl::Admin::Chrome.breadcrumbs-html(@breadcrumbs));

    self.assign('current_admin', $!current-admin);
    self.assign('flash_notice',  self.flash<notice>);

    self.render($template, :layout('admin'), |%options)
  }
}

MVC::Keayl::Admin::Controller.before-action('authenticate-admin');
MVC::Keayl::Admin::Controller.before-action('set-admin-context');
