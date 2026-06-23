use v6.d;

unit class MVC::Keayl::Admin::Field;

has Str  $.name is required;
has Str  $.as = 'string';
has      &.collection;
has Str  $.hint;
has Str  $.placeholder;
has Bool $.multiple = False;

method has-collection(--> Bool) {
  &!collection.defined
}
