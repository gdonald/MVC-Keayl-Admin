use v6.d;
use MVC::Keayl::Admin::Authorization;

unit class MVC::Keayl::Admin::Authorization::Abilities;

has $.admin;
has $.resource;

method can(Str:D $action, $record = Nil --> Bool) {
  MVC::Keayl::Admin::Authorization.allows($action, :$!admin, :$!resource, :$record)
}
