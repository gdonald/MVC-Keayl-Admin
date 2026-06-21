use v6.d;
use MVC::Keayl::Admin::Config;

unit class MVC::Keayl::Admin::Chrome;

method brand-html(::?CLASS:U: --> Str) {
  my $config = MVC::Keayl::Admin::Config.current;

  qq[<a class="navbar-brand text-white" href="{$config.mount-path}">{$config.site-title}</a>]
}

method menu-html(::?CLASS:U: Str :$path = '' --> Str) {
  my $mount  = MVC::Keayl::Admin::Config.current.mount-path;
  my $active = ($path eq '' || $path eq '/') ?? ' active' !! '';

  qq[<ul class="nav nav-pills flex-column"><li class="nav-item"><a class="nav-link{$active}" href="{$mount}"><i class="bi bi-speedometer2 me-2"></i>Dashboard</a></li></ul>]
}

method breadcrumbs-html(::?CLASS:U: @crumbs --> Str) {
  return '' unless @crumbs;

  my @items = @crumbs.map(-> $crumb {
    my $label = $crumb.key;
    my $url   = $crumb.value;

    $url.defined && $url ne ''
      ?? qq[<li class="breadcrumb-item"><a href="{$url}">{$label}</a></li>]
      !! qq[<li class="breadcrumb-item active" aria-current="page">{$label}</li>]
  });

  qq[<nav aria-label="breadcrumb"><ol class="breadcrumb">{@items.join}</ol></nav>]
}
