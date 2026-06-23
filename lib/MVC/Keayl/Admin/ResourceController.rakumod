use v6.d;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Table;
use MVC::Keayl::Admin::Pagination;
use MVC::Keayl::Admin::FilterPanel;
use MVC::Keayl::Admin::Scopes;
use MVC::Keayl::Admin::Show;
use MVC::Keayl::Admin::Form;
use MVC::Keayl::Admin::Predicate;
use MVC::Keayl::Admin::Formatter;

unit class MVC::Keayl::Admin::ResourceController is MVC::Keayl::Admin::Controller;

sub filter-value($filter, %params) {
  if $filter.as eq 'date-range' {
    my $from = (%params{$filter.name ~ '-from'} // '').Str;
    my $to   = (%params{$filter.name ~ '-to'}   // '').Str;

    return Nil unless $from ne '' && $to ne '';

    return "$from,$to";
  }

  my $value = (%params{$filter.name} // '').Str;

  $value ne '' ?? $value !! Nil
}

sub strong-params($resource, %params) {
  my %attrs;

  for $resource.permitted -> $name {
    my $field  = $resource.fields.first({ .name eq $name });
    my $column = $name.subst('-', '_', :g);
    my $type   = $field.defined ?? $field.as !! 'string';

    if $type eq 'boolean' {
      %attrs{$column} = so (%params{$name} // '').Str.lc eq any('1', 'true', 'on', 'yes');
    } elsif %params{$name}:exists {
      my $value = %params{$name};
      %attrs{$column} = $type eq 'number' ?? +$value !! $value;
    }
  }

  %attrs
}

sub resolve-scope($resource, %params) {
  my $name = (%params<scope> // '').Str;

  if $name ne '' {
    my $found = $resource.scopes.first({ .name eq $name });

    return $found if $found;
  }

  $resource.default-scope
}

sub apply-scope($scope, $relation) {
  return $relation unless $scope.defined && $scope.block.defined;

  $scope.block.($relation)
}

sub apply-filters($resource, $relation, %params) {
  my $rel = $relation;

  for $resource.filters -> $filter {
    my $value = filter-value($filter, %params);

    next without $value;

    my $column = $filter.name.subst('-', '_', :g);

    if $filter.as eq 'boolean' {
      my $on = so $value.lc eq any('true', '1', 'yes', 'on');

      $rel = apply-predicate($rel, $column, ($on ?? 'true' !! 'false'), Nil);
    } else {
      $rel = apply-predicate($rel, $column, $filter.effective-predicate, $value);
    }
  }

  $rel
}

method current-resource {
  my $slug = self.request.path.split('/').grep(*.chars).head;

  MVC::Keayl::Admin::Registry.current.by-slug($slug)
}

method index {
  my $resource = self.current-resource;
  my $mount    = MVC::Keayl::Admin::Config.current.mount-path;
  my $base     = $mount ~ '/' ~ $resource.slug;
  my %params   = self.params.Hash;

  my $sort = self.params<sort>;
  my $dir  = (self.params<dir> // 'asc') eq 'desc' ?? 'desc' !! 'asc';
  my $page = max(1, (self.params<page> // 1).Int);
  my $per  = $resource.per-page;

  my %filters = MVC::Keayl::Admin::FilterPanel.active-params($resource, %params);

  my $scope      = resolve-scope($resource, %params);
  my $scope-name = ($scope.defined && !$scope.default) ?? $scope.name !! Str;

  my %carry = %filters;
  %carry<scope> = $scope-name if $scope-name.defined;

  my $total    = apply-filters($resource, apply-scope($scope, $resource.model.all), %params).count;
  my $relation = apply-filters($resource, apply-scope($scope, $resource.model.all), %params);

  if $sort.defined && $resource.columns.first({ .name eq $sort && .sortable }) {
    $relation = $relation.order($sort ~ ($dir eq 'desc' ?? ' DESC' !! ' ASC'));
  }

  my @records = $relation.limit($per).offset(($page - 1) * $per).all;

  my %counts;
  if $resource.scope-counts {
    for $resource.scopes -> $each {
      %counts{$each.name} = apply-filters($resource, apply-scope($each, $resource.model.all), %params).count;
    }
  }

  my $tabs  = MVC::Keayl::Admin::Scopes.render($resource, :active($scope), :$base, :%filters, :$sort, :$dir, :%counts);
  my $chips = MVC::Keayl::Admin::FilterPanel.chips($resource, %params, :$base, :target<#admin-index>, :$sort, :$dir, scope => $scope-name);
  my $table = MVC::Keayl::Admin::Table.render($resource, @records, mount-path => $mount, :$sort, :$dir, filters => %carry);
  my $pager = MVC::Keayl::Admin::Pagination.render(:$base, :$page, :$per, :$total, :$sort, :$dir, filters => %carry);

  my $body = $tabs ~ $chips ~ $table ~ $pager;

  return self.render(:html($body)) if self.request.header('HX-Request');

  self.assign('admin_index_body', $body);
  self.assign('admin_new_link',
    qq[<a class="btn btn-primary" href="{html-escape($base ~ '/new')}"><i class="bi bi-plus-lg me-1"></i>New {html-escape($resource.singular-name)}</a>]);
  self.assign('admin_filters_panel', self.filters-panel($resource, %params, :$base, :$sort, :$dir, scope => $scope-name));

  self.render-admin(
    'resource/index',
    page-title  => $resource.plural-name,
    breadcrumbs => [ $resource.plural-name => Nil ],
  )
}

method !find-record($resource) {
  my $id = (self.params<id> // '').Str;

  $id ~~ /^ \d+ $/ ?? $resource.model.where({ id => $id.Int }).first !! Nil
}

# The route action is `new`, but `new` is the object constructor and a reserved
# method name, so the base controller's dispatch maps it here.
method new-record {
  my $resource = self.current-resource;
  my $mount    = MVC::Keayl::Admin::Config.current.mount-path;
  my $base     = $mount ~ '/' ~ $resource.slug;

  self.render-form($resource, $resource.model.build, action => $base, submit => 'Create', :$base,
    page-title => 'New ' ~ $resource.singular-name);
}

method create {
  my $resource = self.current-resource;
  my $mount    = MVC::Keayl::Admin::Config.current.mount-path;
  my $base     = $mount ~ '/' ~ $resource.slug;

  my $record = $resource.model.create(strong-params($resource, self.params.Hash));

  if $record.id {
    self.flash<notice> = $resource.singular-name ~ ' created.';

    return self.redirect-to($base ~ '/' ~ $record.id);
  }

  self.render-form($resource, $record, action => $base, submit => 'Create', :$base,
    page-title => 'New ' ~ $resource.singular-name);
}

method edit {
  my $resource = self.current-resource;
  my $record   = self!find-record($resource);

  return self.head(404) without $record;

  my $mount = MVC::Keayl::Admin::Config.current.mount-path;
  my $base  = $mount ~ '/' ~ $resource.slug;

  self.render-form($resource, $record, action => $base ~ '/' ~ $record.id, submit => 'Update', :$base,
    page-title => 'Edit ' ~ $resource.singular-name ~ ' #' ~ $record.id);
}

method update {
  my $resource = self.current-resource;
  my $record   = self!find-record($resource);

  return self.head(404) without $record;

  my $mount = MVC::Keayl::Admin::Config.current.mount-path;
  my $base  = $mount ~ '/' ~ $resource.slug;

  if $record.update(strong-params($resource, self.params.Hash)) {
    self.flash<notice> = $resource.singular-name ~ ' updated.';

    return self.redirect-to($base ~ '/' ~ $record.id);
  }

  self.render-form($resource, $record, action => $base ~ '/' ~ $record.id, submit => 'Update', :$base,
    page-title => 'Edit ' ~ $resource.singular-name ~ ' #' ~ $record.id);
}

method render-form($resource, $record, Str:D :$action, Str:D :$submit, Str:D :$base, Str:D :$page-title) {
  self.assign('admin_form', MVC::Keayl::Admin::Form.render($resource, $record, :$action, :$submit, cancel => $base));

  self.render-admin(
    'resource/form',
    :$page-title,
    breadcrumbs => [ $resource.plural-name => $base, $page-title => Nil ],
  )
}

method show {
  my $resource = self.current-resource;
  my $record   = self!find-record($resource);

  return self.head(404) without $record;

  my $mount = MVC::Keayl::Admin::Config.current.mount-path;
  my $base  = $mount ~ '/' ~ $resource.slug;
  my $title = $resource.singular-name ~ ' #' ~ $record.id;

  self.assign('admin_show_body',    MVC::Keayl::Admin::Show.render($resource, $record, mount-path => $mount));
  self.assign('admin_show_actions', MVC::Keayl::Admin::Show.actions($resource, $record, mount-path => $mount));

  self.render-admin(
    'resource/show',
    page-title  => $title,
    breadcrumbs => [ $resource.plural-name => $base, $title => Nil ],
  )
}

method filters-panel($resource, %params, Str:D :$base, :$sort, :$dir, :$scope --> Str) {
  return '' unless MVC::Keayl::Admin::FilterPanel.has-filters($resource);

  my $form = MVC::Keayl::Admin::FilterPanel.form($resource, %params, :$base, :target<#admin-index>, :$sort, :$dir, :$scope);

  qq:to/HTML/.trim;
  <button class="btn btn-outline-secondary" type="button" data-bs-toggle="offcanvas" data-bs-target="#admin-filters"><i class="bi bi-funnel me-1"></i>Filters</button>
  <div class="offcanvas offcanvas-end" tabindex="-1" id="admin-filters">
    <div class="offcanvas-header"><h5 class="offcanvas-title">Filters</h5><button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close"></button></div>
    <div class="offcanvas-body">{$form}</div>
  </div>
  HTML
}
