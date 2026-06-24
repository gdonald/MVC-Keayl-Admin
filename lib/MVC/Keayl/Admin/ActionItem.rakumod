use v6.d;

unit class MVC::Keayl::Admin::ActionItem;

has Str $.label is required;
has     &.block is required;
has     @.only;
has     @.except;
has Str $.if-can;

method shows-on(Str:D $action --> Bool) {
  return False if @!only   && $action ∉ @!only;
  return False if @!except && $action ∈ @!except;

  True
}
