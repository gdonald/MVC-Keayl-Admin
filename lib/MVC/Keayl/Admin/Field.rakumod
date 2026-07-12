use v6.d;

unit class MVC::Keayl::Admin::Field;

has Str  $.name is required;
has Str  $.as = 'string';
has Str  $.label;
has      &.collection;
has Str  $.hint;
has Str  $.placeholder;
has Bool $.multiple = False;
has Int  $.rows;
has      &.value;

method has-collection(--> Bool) {
  &!collection.defined
}

# A field whose form value is computed from the record rather than read straight
# from a database column (a virtual attribute rendered through a method).
method has-value(--> Bool) {
  &!value.defined
}
