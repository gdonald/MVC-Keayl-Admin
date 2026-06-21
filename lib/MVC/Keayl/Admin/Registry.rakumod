use v6.d;
use MVC::Keayl::Admin::Resource;

unit class MVC::Keayl::Admin::Registry;

has MVC::Keayl::Admin::Resource @.resources;

method add(MVC::Keayl::Admin::Resource:D $resource --> ::?CLASS) {
  @!resources.push: $resource;

  self
}

method all(--> List) {
  @!resources.List
}

method clear(--> ::?CLASS) {
  @!resources = ();

  self
}
