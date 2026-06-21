use v6.d;
use MVC::Keayl::Admin::DSL;

unit class MVC::Keayl::Admin::Resource does MVC::Keayl::Admin::DSL;

has Mu  $.model is required;
has     &.block;

method model-name(--> Str) {
  $!model.^name.split('::')[*-1]
}
