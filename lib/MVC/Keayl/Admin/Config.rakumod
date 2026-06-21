use v6.d;

unit class MVC::Keayl::Admin::Config;

has Str $.mount-path is rw = '/admin';
has Str $.site-title is rw = 'Admin';

my MVC::Keayl::Admin::Config $instance .= new;

method current(::?CLASS:U: --> ::?CLASS) {
  $instance
}

method reset(::?CLASS:U: --> ::?CLASS) {
  $instance .= new
}
