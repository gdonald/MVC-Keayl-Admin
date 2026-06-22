use v6.d;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Table;
use MVC::Keayl::Admin::Formatter;

unit class MVC::Keayl::Admin::ResourceController is MVC::Keayl::Admin::Controller;

method current-resource {
  my $slug = self.request.path.split('/').grep(*.chars).head;

  MVC::Keayl::Admin::Registry.current.by-slug($slug)
}

method index {
  my $resource = self.current-resource;
  my $mount    = MVC::Keayl::Admin::Config.current.mount-path;
  my $base     = $mount ~ '/' ~ $resource.slug;

  my @records = $resource.model.all.all;

  self.assign('admin_table', MVC::Keayl::Admin::Table.render($resource, @records, mount-path => $mount));
  self.assign('admin_new_link',
    qq[<a class="btn btn-primary" href="{html-escape($base ~ '/new')}"><i class="bi bi-plus-lg me-1"></i>New {html-escape($resource.singular-name)}</a>]);

  self.render-admin(
    'resource/index',
    page-title  => $resource.plural-name,
    breadcrumbs => [ $resource.plural-name => Nil ],
  )
}
