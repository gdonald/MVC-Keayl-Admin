use v6.d;

unit class MVC::Keayl::Admin::Page;

has Str  $.slug is required;
has Str  $.title is required;
has      &.block is required;
has Str  $.group;
has Str  $.label;
has Int  $.priority = 0;
has Str  $.icon;
has Bool $.hide = False;

method menu-label(--> Str) {
  $!label // $!title
}
