use v6.d;

unit class MVC::Keayl::Admin::Filter;

has Str $.name is required;
has Str $.as = 'string';
has Str $.predicate;
has     &.collection;

constant DEFAULT-PREDICATES = {
  string       => 'cont',
  numeric      => 'eq',
  boolean      => 'eq',
  date         => 'eq',
  'date-range' => 'between',
  select       => 'eq',
};

method effective-predicate(--> Str) {
  return $!predicate with $!predicate;

  DEFAULT-PREDICATES{$!as} // 'eq'
}

method has-collection(--> Bool) {
  &!collection.defined
}
