use v6.d;
use MVC::Keayl::Admin::Field;

unit class MVC::Keayl::Admin::Nested;

has Str  $.name is required;
has Bool $.multiple = False;
has MVC::Keayl::Admin::Field @.fields;

method field(Str:D $name, Str :$as = 'string', :&collection, Str :$hint, Str :$placeholder, Bool :$multiple = False --> ::?CLASS) {
  @!fields.push: MVC::Keayl::Admin::Field.new(:$name, :$as, :&collection, :$hint, :$placeholder, :$multiple);

  self
}
