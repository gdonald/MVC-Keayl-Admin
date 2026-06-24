use v6.d;

unit module MVC::Keayl::Admin::DSL;

# These bare subs are written inside a `register` block and record declarations
# onto the resource being configured, which `Resource.parse` exposes through the
# $*KEAYL-ADMIN-RESOURCE dynamic variable.

sub column(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.column(|args)
}

sub attribute(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.attribute(|args)
}

sub field(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.field(|args)
}

sub filter(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.filter(|args)
}

sub scope(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.scope(|args)
}

sub permit(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.permit(|args)
}

sub menu(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.menu(|args)
}

sub nested(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.nested(|args)
}
