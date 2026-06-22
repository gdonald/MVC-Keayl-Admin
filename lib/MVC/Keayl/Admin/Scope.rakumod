use v6.d;

unit class MVC::Keayl::Admin::Scope;

has Str  $.name is required;
has      &.block;
has Bool $.default = False;
