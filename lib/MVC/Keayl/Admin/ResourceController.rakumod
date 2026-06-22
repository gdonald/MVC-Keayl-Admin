use v6.d;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Table;
use MVC::Keayl::Admin::Pagination;
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

  my $sort = self.params<sort>;
  my $dir  = (self.params<dir> // 'asc') eq 'desc' ?? 'desc' !! 'asc';
  my $page = max(1, (self.params<page> // 1).Int);
  my $per  = $resource.per-page;

  my $total    = $resource.model.all.count;
  my $relation = $resource.model.all;

  if $sort.defined && $resource.columns.first({ .name eq $sort && .sortable }) {
    $relation = $relation.order($sort ~ ($dir eq 'desc' ?? ' DESC' !! ' ASC'));
  }

  my @records = $relation.limit($per).offset(($page - 1) * $per).all;

  my $table = MVC::Keayl::Admin::Table.render($resource, @records, mount-path => $mount, :$sort, :$dir);
  my $pager = MVC::Keayl::Admin::Pagination.render(:$base, :$page, :$per, :$total, :$sort, :$dir);

  return self.render(:html($table ~ $pager)) if self.request.header('HX-Request');

  self.assign('admin_index_body', $table ~ $pager);
  self.assign('admin_new_link',
    qq[<a class="btn btn-primary" href="{html-escape($base ~ '/new')}"><i class="bi bi-plus-lg me-1"></i>New {html-escape($resource.singular-name)}</a>]);

  self.render-admin(
    'resource/index',
    page-title  => $resource.plural-name,
    breadcrumbs => [ $resource.plural-name => Nil ],
  )
}
