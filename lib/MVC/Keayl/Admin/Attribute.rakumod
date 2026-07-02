use v6.d;

unit class MVC::Keayl::Admin::Attribute;

has Str $.name is required;
has     &.display;
has Str $.format;
has Bool $.html = False;
