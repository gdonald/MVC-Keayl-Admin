use v6.d;
use MVC::Keayl::HttpAuthentication;
use MVC::Keayl::Admin::Authentication;

unit class MVC::Keayl::Admin::Authentication::Basic does MVC::Keayl::Admin::Authentication::Strategy;

has Str $.name is required;
has Str $.password is required;
has Str $.realm = 'Admin';

method authenticate($controller) {
  $controller.authenticate-with-http-basic(-> $user, $pass {
    secure-compare($user, $!name) && secure-compare($pass, $!password) ?? $user !! Str
  })
}

method challenge($controller) {
  $controller.request-http-basic-authentication($!realm)
}
