use v6.d;

unit class MVC::Keayl::Admin::Column;

has Str  $.name is required;
has Str  $.label;
has Bool $.sortable = False;
has      &.display;
has Str  $.format;
has Bool $.html = False;
