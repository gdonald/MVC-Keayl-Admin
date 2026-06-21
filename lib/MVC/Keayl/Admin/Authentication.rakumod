use v6.d;

class MVC::Keayl::Admin::Authentication {
  my $strategy;

  method strategy(::?CLASS:U:) {
    $strategy
  }

  method use-strategy(::?CLASS:U: $new --> Nil) {
    $strategy = $new;
  }

  method reset(::?CLASS:U: --> Nil) {
    $strategy = Nil;
  }
}

role MVC::Keayl::Admin::Authentication::Strategy {
  method authenticate($controller) { ... }
  method challenge($controller)    { ... }
}
