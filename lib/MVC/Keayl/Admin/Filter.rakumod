use v6.d;

unit class MVC::Keayl::Admin::Filter;

has Str $.name is required;
has     %.options;

method predicate(--> Str) {
  %!options<predicate> // 'eq'
}
