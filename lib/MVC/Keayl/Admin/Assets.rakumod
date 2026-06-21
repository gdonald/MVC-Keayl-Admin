use v6.d;
use MVC::Keayl::Assets;
use MVC::Keayl::Helpers::Tag;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Paths;

unit class MVC::Keayl::Admin::Assets;

constant ASSET-PREFIX = '/admin-assets';

my @bundle-styles  = <bootstrap/bootstrap.min.css bootstrap-icons/bootstrap-icons.min.css>;
my @bundle-scripts = <bootstrap/bootstrap.bundle.min.js htmx/htmx.min.js>;

my %digest-cache;
my Str $override-stylesheet;

method digest-of(::?CLASS:U: Str:D $logical --> Str) {
  return %digest-cache{$logical} if %digest-cache{$logical}:exists;

  my $file   = assets-path().IO.add($logical);
  my $digest = $file.e ?? digest-for($file.slurp(:bin)) !! Str;

  %digest-cache{$logical} = $digest;

  $digest
}

method asset-url(::?CLASS:U: Str:D $logical --> Str) {
  my $base   = MVC::Keayl::Admin::Config.current.mount-path ~ ASSET-PREFIX ~ '/' ~ $logical;
  my $digest = self.digest-of($logical);

  $digest.defined ?? $base ~ '?' ~ $digest !! $base
}

method use-stylesheet(::?CLASS:U: Str:D $url --> Nil) {
  $override-stylesheet = $url;
}

method override-stylesheet(::?CLASS:U: --> Str) {
  $override-stylesheet
}

method stylesheet-tags(::?CLASS:U: --> Str) {
  my @hrefs = @bundle-styles.map({ self.asset-url($_) });

  @hrefs.push($override-stylesheet) if $override-stylesheet.defined;

  @hrefs.map({ tag('link', %( rel => 'stylesheet', href => $_ )).Str }).join("\n")
}

method script-tags(::?CLASS:U: --> Str) {
  @bundle-scripts.map({ content-tag('script', '', %( src => self.asset-url($_) )).Str }).join("\n")
}

method import-map(::?CLASS:U: --> MVC::Keayl::Assets::ImportMap) {
  my $map = MVC::Keayl::Assets::ImportMap.new;

  $map.pin('htmx.org',  to => self.asset-url('htmx/htmx.min.js'));
  $map.pin('bootstrap', to => self.asset-url('bootstrap/bootstrap.bundle.min.js'));

  $map
}

method importmap-tags(::?CLASS:U: --> Str) {
  javascript-importmap-tags(self.import-map).Str
}

method reset(::?CLASS:U: --> Nil) {
  $override-stylesheet = Str;
  %digest-cache = ();
}
