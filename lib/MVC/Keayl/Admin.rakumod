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
use MVC::Keayl::Admin::I18n;
use MVC::Keayl::Admin::DashboardController;
use MVC::Keayl::Admin::AssetsController;
use MVC::Keayl::Admin::ResourceController;
use MVC::Keayl::Admin::PageController;
use MVC::Keayl::Admin::Page;
use MVC::Keayl::Admin::Pages;

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

method register(::?CLASS:U: Mu:U $model, &block, Str :$slug, Str :$singular, Str :$plural, Int :$per-page, Bool :$scope-counts, Bool :$filters, Bool :$batch-actions, :$export --> MVC::Keayl::Admin::Resource) {
  my $resource = MVC::Keayl::Admin::Resource.new(
    :$model,
    slug-override         => $slug,
    singular-override     => $singular,
    plural-override       => $plural,
    per-page-override     => $per-page,
    scope-counts-override => $scope-counts,
    filters-override      => $filters,
    batch-override        => $batch-actions,
    export-override       => $export,
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

method page(::?CLASS:U: Str:D $slug, &block, Str :$title, Str :$group, Str :$label, Int :$priority = 0, Str :$icon, Bool :$hide = False --> Nil) {
  MVC::Keayl::Admin::Pages.add(
    MVC::Keayl::Admin::Page.new(
      :$slug,
      title => $title // $slug.tc,
      :&block,
      :$group, :$label, :$priority, :$icon, :$hide,
    )
  );
}

method load-locales(::?CLASS:U: $dir --> Nil) {
  MVC::Keayl::Admin::I18n.load-locales($dir);
}

method locale(::?CLASS:U: Str:D $locale --> Nil) {
  MVC::Keayl::Admin::I18n.set-locale($locale);
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
  my $page-ctrl      = MVC::Keayl::Admin::PageController.controller-path ~ '#show';
  my @resources      = MVC::Keayl::Admin::Registry.current.all;
  my @pages          = MVC::Keayl::Admin::Pages.all;

  my &block = {
    get '/admin-assets/*path', to => $assets;

    for @pages -> $page {
      get '/' ~ $page.slug, to => $page-ctrl;
    }

    for @resources -> $res {
      my $slug = $res.slug;

      # Literal paths are registered before `resources` so they win over the
      # member `:id` route.
      post '/' ~ $slug ~ '/batch',  to => $resource-ctrl ~ '#apply-batch' if $res.batch-enabled;
      get  '/' ~ $slug ~ '/export', to => $resource-ctrl ~ '#export', :format if $res.allows-action('index') && $res.export-enabled;

      for $res.collection-actions -> $action {
        post '/' ~ $slug ~ '/' ~ $action.name, to => $resource-ctrl ~ '#run-collection-action';
      }

      for $res.member-actions -> $action {
        post '/' ~ $slug ~ '/:id/' ~ $action.name, to => $resource-ctrl ~ '#run-member-action';
      }

      my @only = ('index'           if $res.allows-action('index')),
                 ('show'            if $res.allows-action('show')),
                 (|<new create>     if $res.allows-action('new')),
                 (|<edit update>    if $res.allows-action('edit')),
                 ('destroy'         if $res.allows-action('destroy'));

      resources $slug, :controller($resource-ctrl), only => @only.grep(*.defined);

      # HTML forms cannot issue PATCH or DELETE, so accept a plain POST to the
      # member path for update, and to a delete sub-path for destroy, keeping
      # both usable without JavaScript.
      post '/' ~ $slug ~ '/:id',         to => $resource-ctrl ~ '#update'  if $res.allows-action('edit');
      post '/' ~ $slug ~ '/:id/delete',  to => $resource-ctrl ~ '#destroy' if $res.allows-action('destroy');
    }

    # Nested routes for resources that declare a parent, scoping the relation to
    # the parent record. Registered after the standalone routes so the parent
    # resources are known.
    for @resources -> $res {
      next without $res.parent-association;

      my $parent = MVC::Keayl::Admin::Registry.current.by-model($res.parent-reflection.klass) with $res.parent-reflection;
      next without $parent;

      my $nbase = '/' ~ $parent.slug ~ '/:parent_id/' ~ $res.slug;

      get    $nbase,                 to => $resource-ctrl ~ '#index'   if $res.allows-action('index');
      get    $nbase ~ '/new',        to => $resource-ctrl ~ '#new'     if $res.allows-action('new');
      post   $nbase,                 to => $resource-ctrl ~ '#create'  if $res.allows-action('new');
      get    $nbase ~ '/:id/edit',   to => $resource-ctrl ~ '#edit'    if $res.allows-action('edit');
      post   $nbase ~ '/:id/delete', to => $resource-ctrl ~ '#destroy' if $res.allows-action('destroy');
      delete $nbase ~ '/:id',        to => $resource-ctrl ~ '#destroy' if $res.allows-action('destroy');
      post   $nbase ~ '/:id',        to => $resource-ctrl ~ '#update'  if $res.allows-action('edit');
      get    $nbase ~ '/:id',        to => $resource-ctrl ~ '#show'    if $res.allows-action('show');
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
      MVC::Keayl::Admin::PageController,
    ],
    routes-block => admin-routes(),
  )
}

method view-path(::?CLASS:U: Str:D $path --> Nil) {
  MVC::Keayl::Admin::Config.current.add-view-override($path);
}

method endpoint(::?CLASS:U:) {
  self.engine.endpoint(view-path-overrides => MVC::Keayl::Admin::Config.current.view-overrides)
}

method reset(::?CLASS:U: --> Nil) {
  MVC::Keayl::Admin::Registry.reset;
  MVC::Keayl::Admin::Config.reset;
  MVC::Keayl::Admin::Assets.reset;
  MVC::Keayl::Admin::Menu.reset;
  MVC::Keayl::Admin::Dashboard.reset;
  MVC::Keayl::Admin::Authentication.reset;
  MVC::Keayl::Admin::Authorization.reset;
  MVC::Keayl::Admin::I18n.reset;
  MVC::Keayl::Admin::Pages.reset;
}
