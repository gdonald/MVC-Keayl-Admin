use v6.d;
use MVC::Keayl::Admin::Authorization::Policy;

unit class MVC::Keayl::Admin::Authorization::Role is MVC::Keayl::Admin::Authorization::Policy;

has %.permissions;
has &.role-of = -> $admin { $admin.defined ?? $admin.role !! Str };

method allows(Str:D $action, :$admin, :$resource, :$record --> Bool) {
  my $role = &!role-of($admin);

  return False without $role;

  my @allowed = (%!permissions{$role} // ()).list;

  return True if @allowed.first('*');

  so @allowed.first($action)
}
