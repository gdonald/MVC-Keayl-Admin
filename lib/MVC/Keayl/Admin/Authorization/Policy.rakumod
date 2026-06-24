use v6.d;

unit class MVC::Keayl::Admin::Authorization::Policy;

method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) {
  True
}

method scope($relation, :$admin, :$resource) {
  $relation
}
