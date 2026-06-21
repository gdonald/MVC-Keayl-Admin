use v6.d;
use MVC::Keayl::Admin::Authentication;

unit class MVC::Keayl::Admin::Authentication::Session does MVC::Keayl::Admin::Authentication::Strategy;

has Str $.key        = 'admin_id';
has Str $.login-path = '/login';
has     &.resolve;

method authenticate($controller) {
  my $id = $controller.session{$!key};

  return Nil without $id;

  &!resolve.defined ?? &!resolve.($id) !! $id
}

method challenge($controller) {
  $controller.redirect-to($!login-path)
}
