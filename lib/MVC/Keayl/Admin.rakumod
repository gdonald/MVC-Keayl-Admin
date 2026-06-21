use v6.d;
use MVC::Keayl::Routing;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Resource;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Engine;
use MVC::Keayl::Admin::Assets;
use MVC::Keayl::Admin::DashboardController;
use MVC::Keayl::Admin::AssetsController;

unit class MVC::Keayl::Admin;

my MVC::Keayl::Admin::Registry $registry .= new;

method registry(::?CLASS:U: --> MVC::Keayl::Admin::Registry) {
  $registry
}

method config(::?CLASS:U: --> MVC::Keayl::Admin::Config) {
  MVC::Keayl::Admin::Config.current
}

method configure(::?CLASS:U: Str :$mount-path, Str :$site-title --> MVC::Keayl::Admin::Config) {
  my $config = MVC::Keayl::Admin::Config.current;

  $config.mount-path = $_ with $mount-path;
  $config.site-title = $_ with $site-title;

  $config
}

method register(::?CLASS:U: Mu:U $model, &block --> MVC::Keayl::Admin::Resource) {
  my $resource = MVC::Keayl::Admin::Resource.new(:$model, :&block);

  $registry.add($resource);

  $resource
}

method use-stylesheet(::?CLASS:U: Str:D $url --> Nil) {
  MVC::Keayl::Admin::Assets.use-stylesheet($url);
}

sub admin-routes {
  my $dashboard = MVC::Keayl::Admin::DashboardController.controller-path ~ '#index';
  my $assets    = MVC::Keayl::Admin::AssetsController.controller-path ~ '#show';

  my &block = {
    get '/admin-assets/*path', to => $assets;
    get '/', to => $dashboard;
  };

  &block
}

method engine(::?CLASS:U: --> MVC::Keayl::Admin::Engine) {
  MVC::Keayl::Admin::Engine.new(
    controllers  => [
      MVC::Keayl::Admin::DashboardController,
      MVC::Keayl::Admin::AssetsController,
    ],
    routes-block => admin-routes(),
  )
}

method endpoint(::?CLASS:U:) {
  self.engine.endpoint
}

method reset(::?CLASS:U: --> Nil) {
  $registry .= new;
  MVC::Keayl::Admin::Config.reset;
  MVC::Keayl::Admin::Assets.reset;
}
