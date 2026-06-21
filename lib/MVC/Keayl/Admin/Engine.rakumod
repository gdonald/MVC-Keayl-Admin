use v6.d;
use MVC::Keayl::Engine;

unit class MVC::Keayl::Admin::Engine is MVC::Keayl::Engine;

submethod TWEAK {
  self.isolate-namespace('MVC::Keayl::Admin');
}
