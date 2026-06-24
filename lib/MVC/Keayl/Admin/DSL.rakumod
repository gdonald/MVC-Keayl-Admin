use v6.d;

unit module MVC::Keayl::Admin::DSL;

# These bare subs are written inside a `register` block and record declarations
# onto the resource being configured, which `Resource.parse` exposes through the
# $*KEAYL-ADMIN-RESOURCE dynamic variable.

sub index(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.index(|args)
}

sub actions(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.actions(|args)
}

sub sort-order(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.sort-order(|args)
}

sub belongs-to(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.belongs-to(|args)
}

sub includes(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.includes(|args)
}

sub action-item(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.action-item(|args)
}

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

sub batch-action(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.batch-action(|args)
}

sub member-action(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.member-action(|args)
}

sub collection-action(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.collection-action(|args)
}

sub sidebar(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.sidebar(|args)
}

sub panel(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.panel(|args)
}

sub tab(|args) is export {
  $*KEAYL-ADMIN-RESOURCE.tab(|args)
}
