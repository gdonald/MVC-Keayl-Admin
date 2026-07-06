use v6.d;

unit class MVC::Keayl::Admin::Config;

has Str $.mount-path  is rw = '/admin';
has Str $.site-title  is rw = 'Admin';
has Str $.logout-path is rw;
has     @.view-overrides;

method add-view-override(Str:D $path --> Nil) {
  @!view-overrides.push: $path;
}

my MVC::Keayl::Admin::Config $instance .= new;

method current(::?CLASS:U: --> ::?CLASS) {
  $instance
}

method reset(::?CLASS:U: --> ::?CLASS) {
  $instance .= new
}
