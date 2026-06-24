use v6.d;
use MVC::Keayl::Routing;
use MVC::Keayl::Routing::UrlHelpers;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Resource;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Engine;
use MVC::Keayl::Admin::Assets;
use MVC::Keayl::Admin::Menu;
use MVC::Keayl::Admin::Dashboard;
use MVC::Keayl::Admin::Authentication;
use MVC::Keayl::Admin::Authorization;
use MVC::Keayl::Admin::DashboardController;
use MVC::Keayl::Admin::AssetsController;
use MVC::Keayl::Admin::ResourceController;

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

method register(::?CLASS:U: Mu:U $model, &block, Str :$slug, Str :$singular, Str :$plural, Int :$per-page, Bool :$scope-counts --> MVC::Keayl::Admin::Resource) {
  my $resource = MVC::Keayl::Admin::Resource.new(
    :$model,
    slug-override         => $slug,
    singular-override     => $singular,
    plural-override       => $plural,
    per-page-override     => $per-page,
    scope-counts-override => $scope-counts,
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

method authorize-with(::?CLASS:U: $policy --> Nil) {
  MVC::Keayl::Admin::Authorization.use-policy($policy);
}

method menu-link(::?CLASS:U: |args --> Nil) {
  MVC::Keayl::Admin::Menu.add-link(|args);
}

method menu-group-order(::?CLASS:U: *@groups --> Nil) {
  MVC::Keayl::Admin::Menu.group-order(|@groups);
}

method dashboard-block(::?CLASS:U: &block, Str:D :$title --> Nil) {
  MVC::Keayl::Admin::Dashboard.add-block(:$title, :&block);
}

sub admin-routes {
  my $dashboard      = MVC::Keayl::Admin::DashboardController.controller-path ~ '#index';
  my $assets         = MVC::Keayl::Admin::AssetsController.controller-path ~ '#show';
  my $resource-ctrl  = MVC::Keayl::Admin::ResourceController.controller-path;
  my @resources      = MVC::Keayl::Admin::Registry.current.all;

  my &block = {
    get '/admin-assets/*path', to => $assets;

    for @resources -> $res {
      my $slug = $res.slug;

      # Literal paths are registered before `resources` so they win over the
      # member `:id` route.
      post '/' ~ $slug ~ '/batch', to => $resource-ctrl ~ '#apply-batch';

      for $res.collection-actions -> $action {
        post '/' ~ $slug ~ '/' ~ $action.name, to => $resource-ctrl ~ '#run-collection-action';
      }

      for $res.member-actions -> $action {
        post '/' ~ $slug ~ '/:id/' ~ $action.name, to => $resource-ctrl ~ '#run-member-action';
      }

      resources $slug, :controller($resource-ctrl);

      # HTML forms cannot issue PATCH or DELETE, so accept a plain POST to the
      # member path for update, and to a delete sub-path for destroy, keeping
      # both usable without JavaScript.
      post '/' ~ $slug ~ '/:id',         to => $resource-ctrl ~ '#update';
      post '/' ~ $slug ~ '/:id/delete',  to => $resource-ctrl ~ '#destroy';
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
      MVC::Keayl::Admin::ResourceController,
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
  MVC::Keayl::Admin::Menu.reset;
  MVC::Keayl::Admin::Dashboard.reset;
  MVC::Keayl::Admin::Authentication.reset;
  MVC::Keayl::Admin::Authorization.reset;
}
