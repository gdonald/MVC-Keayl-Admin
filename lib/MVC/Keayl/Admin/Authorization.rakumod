use v6.d;
use MVC::Keayl::Admin::Authorization::Policy;

unit class MVC::Keayl::Admin::Authorization;

my $policy;

method policy(::?CLASS:U: --> MVC::Keayl::Admin::Authorization::Policy) {
  $policy //= MVC::Keayl::Admin::Authorization::Policy.new
}

method use-policy(::?CLASS:U: $new --> Nil) {
  $policy = $new;
}

method reset(::?CLASS:U: --> Nil) {
  $policy = MVC::Keayl::Admin::Authorization::Policy.new;
}

method allows(::?CLASS:U: |args --> Bool) {
  self.policy.allows(|args)
}

method scope(::?CLASS:U: |args) {
  self.policy.scope(|args)
}
