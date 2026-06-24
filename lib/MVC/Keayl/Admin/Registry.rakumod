use v6.d;
use MVC::Keayl::Admin::Resource;

unit class MVC::Keayl::Admin::Registry;

has MVC::Keayl::Admin::Resource @.resources;
has %!by-slug;
has %!by-model;

my MVC::Keayl::Admin::Registry $instance .= new;

method current(::?CLASS:U: --> ::?CLASS) {
  $instance
}

method reset(::?CLASS:U: --> ::?CLASS) {
  $instance .= new
}

method add(MVC::Keayl::Admin::Resource:D $resource --> ::?CLASS) {
  @!resources.push: $resource;

  %!by-slug{$resource.slug}          = $resource;
  %!by-model{$resource.model.^name}  = $resource;

  self
}

method all(--> List) {
  @!resources.List
}

method by-slug(Str:D $slug --> MVC::Keayl::Admin::Resource) {
  %!by-slug{$slug} // MVC::Keayl::Admin::Resource
}

method by-model(Mu:U $model --> MVC::Keayl::Admin::Resource) {
  %!by-model{$model.^name} // MVC::Keayl::Admin::Resource
}

method children-of(Mu:U $model --> List) {
  @!resources.grep(-> $resource {
    with $resource.parent-reflection -> $reflection {
      $reflection.klass.^name eq $model.^name
    } else {
      False
    }
  }).List
}

method clear(--> ::?CLASS) {
  @!resources = ();
  %!by-slug   = ();
  %!by-model  = ();

  self
}
