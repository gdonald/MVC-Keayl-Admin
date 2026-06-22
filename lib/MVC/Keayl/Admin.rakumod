use v6.d;
use MVC::Keayl::Routing;
use MVC::Keayl::Routing::UrlHelpers;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Resource;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Engine;
use MVC::Keayl::Admin::Assets;
use MVC::Keayl::Admin::Authentication;
use MVC::Keayl::Admin::DashboardController;
use MVC::Keayl::Admin::AssetsController;

unit class MVC::Keayl::Admin;

method registry(::?CLASS:U: --> MVC::Keayl::Admin::Registry) {
  MVC::Keayl::Admin::Registry.current
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

method register(::?CLASS:U: Mu:U $model, &block, Str :$slug, Str :$singular, Str :$plural --> MVC::Keayl::Admin::Resource) {
  my $resource = MVC::Keayl::Admin::Resource.new(
    :$model,
    slug-override     => $slug,
    singular-override => $singular,
    plural-override   => $plural,
  );

  $resource.parse(&block);

  MVC::Keayl::Admin::Registry.current.add($resource);

  $resource
}

method use-stylesheet(::?CLASS:U: Str:D $url --> Nil) {
  MVC::Keayl::Admin::Assets.use-stylesheet($url);
}

method authenticate-with(::?CLASS:U: $strategy --> Nil) {
  MVC::Keayl::Admin::Authentication.use-strategy($strategy);
}

sub admin-routes {
  my $dashboard = MVC::Keayl::Admin::DashboardController.controller-path ~ '#index';
  my $assets    = MVC::Keayl::Admin::AssetsController.controller-path ~ '#show';
  my @slugs     = MVC::Keayl::Admin::Registry.current.all.map(*.slug);

  my &block = {
    get '/admin-assets/*path', to => $assets;

    for @slugs -> $slug {
      resources $slug;
    }

    get '/', to => $dashboard;
  };

  &block
}

method path-for(::?CLASS:U: Str:D $name, |args --> Str) {
  my $helpers = MVC::Keayl::Routing::UrlHelpers.new(router => self.engine.router);

  MVC::Keayl::Admin::Config.current.mount-path ~ $helpers.path-for($name, |args)
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
  MVC::Keayl::Admin::Registry.reset;
  MVC::Keayl::Admin::Config.reset;
  MVC::Keayl::Admin::Assets.reset;
  MVC::Keayl::Admin::Authentication.reset;
}
