use v6.d;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Resource;
use MVC::Keayl::Admin::Engine;

unit class MVC::Keayl::Admin;

my MVC::Keayl::Admin::Registry $registry .= new;

method registry(::?CLASS:U: --> MVC::Keayl::Admin::Registry) {
  $registry
}

method register(::?CLASS:U: Mu:U $model, &block --> MVC::Keayl::Admin::Resource) {
  my $resource = MVC::Keayl::Admin::Resource.new(:$model, :&block);

  $registry.add($resource);

  $resource
}

method engine(::?CLASS:U: --> MVC::Keayl::Admin::Engine) {
  MVC::Keayl::Admin::Engine.new
}

method reset(::?CLASS:U: --> Nil) {
  $registry .= new;
}
