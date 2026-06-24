use v6.d;

unit class MVC::Keayl::Admin::MenuEntry;

has Str  $.group;
has Str  $.label;
has Int  $.priority = 0;
has Str  $.icon;
has Bool $.hide = False;
