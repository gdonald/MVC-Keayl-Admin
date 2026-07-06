use v6.d;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Formatter;

unit class MVC::Keayl::Admin::Chrome;

method heading-html(::?CLASS:U: Str:D $title, Str $icon --> Str) {
  my $bootstrap-icon = $icon.defined ?? qq[<i class="bi bi-{html-escape($icon)} me-2"></i>] !! '';

  $bootstrap-icon ~ html-escape($title)
}

method brand-html(::?CLASS:U: --> Str) {
  my $config = MVC::Keayl::Admin::Config.current;

  qq[<a class="navbar-brand text-white" href="{$config.mount-path}">{$config.site-title}</a>]
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
