use v6.d;
use MVC::Keayl::Engine;
use MVC::Keayl::Admin::Paths;

unit class MVC::Keayl::Admin::Engine is MVC::Keayl::Engine;

submethod TWEAK {
  self.isolate-namespace('MVC::Keayl::Admin');

  self.append-view-paths(views-path());
  self.append-helper-paths(helpers-path());
  self.append-asset-paths(assets-path());
}
