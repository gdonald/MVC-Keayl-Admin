use v6.d;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Table;
use MVC::Keayl::Admin::IndexView;
use MVC::Keayl::Admin::Pagination;
use MVC::Keayl::Admin::FilterPanel;
use MVC::Keayl::Admin::Scopes;
use MVC::Keayl::Admin::Show;
use MVC::Keayl::Admin::Panels;
use MVC::Keayl::Admin::Form;
use MVC::Keayl::Admin::Attachments;
use MVC::Keayl::Admin::Predicate;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::I18n;
use MVC::Keayl::Admin::Authorization;
use MVC::Keayl::Admin::Authorization::Abilities;
use JSON::Fast;

unit class MVC::Keayl::Admin::ResourceController is MVC::Keayl::Admin::Controller;

sub export-value($column, $record) {
  $column.display.defined ?? $column.display.($record) !! $record.read-attribute($column.name)
}

sub export-cell($column, $record --> Str) {
  format-value(export-value($column, $record), $column.format)
}

sub csv-escape(Str:D $value --> Str) {
  $value ~~ /<[ " , \n \r ]>/ ?? '"' ~ $value.subst('"', '""', :g) ~ '"' !! $value
}

sub csv-row(@cells --> Str) {
  @cells.map({ csv-escape(.Str) }).join(',')
}

sub export-records($resource, $relation --> List) {
  $relation.all.map(-> $record {
    %( $resource.export-columns.map({ .name => export-cell($_, $record) }) )
  }).List
}

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

sub attach-files($resource, $record, %params) {
  for $resource.fields.grep(*.as eq 'file') -> $field {
    my $upload = %params{$field.name};

    next unless $upload ~~ Associative && ($upload<filename> // '').Str ne '';

    MVC::Keayl::Admin::Attachments.attach($record, $field.name, $upload);
  }
}

sub strong-params($resource, %params) {
  my %attrs;

  for $resource.permitted -> $name {
    my $field  = $resource.fields.first({ .name eq $name });
    my $column = $name.subst('-', '_', :g);
    my $type   = $field.defined ?? $field.as !! 'string';

    next if $type eq 'file';

    if $type eq 'boolean' {
      %attrs{$column} = so (%params{$name} // '').Str.lc eq any('1', 'true', 'on', 'yes');
    } elsif %params{$name}:exists {
      my $value = %params{$name};
      %attrs{$column} = $type eq 'number' ?? +$value !! $value;
    }
  }

  for $resource.nested-attributes -> $nested {
    my $key = $nested.name ~ '-attributes';

    %attrs{$key} = %params{$key} if %params{$key}:exists;
  }

  %attrs
}

sub batch-toolbar($base, $resource, $abilities --> Str) {
  my @names = ();
  @names.push('Destroy') if $abilities.can('destroy');
  @names.append: $resource.batch-actions.map(*.name).grep({ $abilities.can($_) });

  return '' unless @names;

  my $options = @names.map({ qq[<option value="{html-escape($_)}">{html-escape($_)}</option>] }).join;

  my $select-all = qq[<div class="form-check me-1"><input class="form-check-input" type="checkbox" id="admin-batch-all" data-batch-all><label class="form-check-label" for="admin-batch-all">All</label></div>];

  qq[<div class="d-flex gap-2 mb-2 align-items-center">{$select-all}<select class="form-select form-select-sm w-auto" name="batch-action">{$options}</select><button type="submit" class="btn btn-secondary btn-sm">Apply to <span data-batch-count>0</span> selected</button></div>]
}

sub batch-form($base, $resource, Str:D $table, Str:D $pager, :$abilities --> Str) {
  qq[<form method="post" action="{html-escape($base ~ '/batch')}">{batch-toolbar($base, $resource, $abilities)}{$table}{$pager}</form>]
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
  my $registry = MVC::Keayl::Admin::Registry.current;
  my $found;

  for self.request.path.split('/').grep(*.chars) -> $segment {
    my $resource = $registry.by-slug($segment);
    $found = $resource if $resource.defined;
  }

  $found
}

method parent-resource($resource) {
  with $resource.parent-reflection -> $reflection {
    return MVC::Keayl::Admin::Registry.current.by-model($reflection.klass);
  }

  Nil
}

method nested-parent($resource) {
  my $parent-id = self.params<parent_id>;

  return Nil without $parent-id;

  with $resource.parent-reflection -> $reflection {
    return $reflection.klass.where({ id => $parent-id.Int }).first;
  }

  Nil
}

method parent-fk($resource --> Str) {
  $resource.parent-reflection.foreign-key
}

method parent-scoped($resource, $relation) {
  with self.nested-parent($resource) -> $parent {
    return $relation.where({ self.parent-fk($resource) => $parent.id });
  }

  $relation
}

method resource-base($resource --> Str) {
  my $mount = MVC::Keayl::Admin::Config.current.mount-path;

  with self.nested-parent($resource) -> $parent {
    return $mount ~ '/' ~ self.parent-resource($resource).slug ~ '/' ~ $parent.id ~ '/' ~ $resource.slug;
  }

  $mount ~ '/' ~ $resource.slug
}

method resource-breadcrumbs($resource, *@tail) {
  my $mount = MVC::Keayl::Admin::Config.current.mount-path;
  my @crumbs;

  with self.nested-parent($resource) -> $parent {
    my $parent-resource = self.parent-resource($resource);
    my $parent-base     = $mount ~ '/' ~ $parent-resource.slug;

    @crumbs.push: ($parent-resource.plural-name => $parent-base);
    @crumbs.push: ($parent-resource.singular-name ~ ' #' ~ $parent.id => $parent-base ~ '/' ~ $parent.id);
  }

  @crumbs.append: @tail;

  @crumbs
}

method action-ability {
  given self.current-action {
    when 'index' | 'export'                          { 'index' }
    when 'show'                                      { 'show' }
    when 'new-record' | 'create'                     { 'create' }
    when 'edit' | 'update'                           { 'update' }
    when 'destroy' | 'apply-batch'                   { 'destroy' }
    when 'run-member-action' | 'run-collection-action' {
      self.request.path.split('/').grep(*.chars).tail
    }
    default                                          { $_ }
  }
}

method authorize-action {
  my $resource = self.current-resource;

  return without $resource;

  return if MVC::Keayl::Admin::Authorization.allows(self.action-ability, admin => self.current-admin, :$resource);

  self.forbidden;
}

method abilities-for($resource) {
  MVC::Keayl::Admin::Authorization::Abilities.new(admin => self.current-admin, :$resource)
}

method policy-scope($resource, $relation) {
  MVC::Keayl::Admin::Authorization.scope($relation, admin => self.current-admin, :$resource)
}

method !authorize-record(Str:D $ability, $resource, $record --> Bool) {
  MVC::Keayl::Admin::Authorization.allows($ability, admin => self.current-admin, :$resource, :$record)
}

method index {
  my $resource = self.current-resource;
  my $mount    = MVC::Keayl::Admin::Config.current.mount-path;
  my $base     = self.resource-base($resource);
  my %params   = self.params.Hash;

  my $sort = self.params<sort>;
  my $dir  = (self.params<dir> // 'asc') eq 'desc' ?? 'desc' !! 'asc';
  my $page = max(1, (self.params<page> // 1).Int);
  my $per  = $resource.per-page;

  my %filters = $resource.filters-enabled ?? MVC::Keayl::Admin::FilterPanel.active-params($resource, %params) !! %();

  my $scope      = resolve-scope($resource, %params);
  my $scope-name = ($scope.defined && !$scope.default) ?? $scope.name !! Str;

  my %carry = %filters;
  %carry<scope> = $scope-name if $scope-name.defined;

  my $visible  = self.policy-scope($resource, $resource.model.all);
  my $relation = self!list-relation($resource, %params);

  my $total    = $relation.count;
  my @records  = $relation.limit($per).offset(($page - 1) * $per).all;

  my %counts;
  if $resource.scope-counts {
    for $resource.scopes -> $each {
      %counts{$each.name} = apply-filters($resource, apply-scope($each, $visible), %params).count;
    }
  }

  my $abilities = self.abilities-for($resource);

  my $batch = $resource.batch-enabled;

  my $tabs  = MVC::Keayl::Admin::Scopes.render($resource, :active($scope), :$base, :%filters, :$sort, :$dir, :%counts);
  my $chips = $resource.filters-enabled ?? MVC::Keayl::Admin::FilterPanel.chips($resource, %params, :$base, :target<#admin-index>, :$sort, :$dir, scope => $scope-name) !! '';
  my $table = MVC::Keayl::Admin::IndexView.render($resource, @records, :$base, :$sort, :$dir, filters => %carry, :$batch, :$abilities);
  my $pager = MVC::Keayl::Admin::Pagination.render(:$base, :$page, :$per, :$total, :$sort, :$dir, filters => %carry);

  my $body = $tabs ~ $chips ~ ($batch ?? batch-form($base, $resource, $table, $pager, :$abilities) !! ($table ~ $pager));

  return self.render(:html($body)) if self.request.header('HX-Request');

  my $items = self.action-items-html($resource, 'index', $abilities);

  my $collection-actions = $resource.collection-actions.grep({ $abilities.can(.name) }).map(-> $action {
    my $url     = html-escape($base ~ '/' ~ $action.name);
    my $label   = html-escape(MVC::Keayl::Admin::I18n.action-label($action.name));
    my $confirm = $action.confirm.defined ?? qq[ onsubmit="return confirm('{html-escape($action.confirm)}')"] !! '';

    qq[<form method="post" action="$url"{$confirm} class="d-inline"><button type="submit" class="btn btn-secondary">{$label}</button></form>]
  }).join;

  my $export-links = $resource.export-formats.map(-> $format {
    qq[<a class="btn btn-secondary btn-sm" href="{html-escape($base ~ '/export.' ~ $format)}">{html-escape(MVC::Keayl::Admin::I18n.chrome('export-' ~ $format, $format.uc))}</a>]
  }).join;
  my $export = $export-links ?? qq[<div class="btn-group btn-group-sm">{$export-links}</div>] !! '';

  my $new-link = $abilities.can('create')
    ?? qq[<a class="btn btn-primary" href="{html-escape($base ~ '/new')}"><i class="bi bi-plus-lg me-1"></i>{html-escape(MVC::Keayl::Admin::I18n.chrome('new', 'New') ~ ' ' ~ $resource.singular-name)}</a>]
    !! '';

  my $sidebars = MVC::Keayl::Admin::Panels.sidebars($resource.sidebars, $relation, $abilities, placement => 'index');

  self.assign('admin_index_body', $body);
  self.assign('admin_index_sidebar', $sidebars ?? qq[<div class="col-lg-3">{$sidebars}</div>] !! '');
  self.assign('admin_new_link', $items ~ $collection-actions ~ $new-link);
  self.assign('admin_export_links', $export);
  self.assign('admin_filters_panel', self.filters-panel($resource, %params, :$base, :$sort, :$dir, scope => $scope-name));

  self.render-admin(
    'resource/index',
    page-title  => $resource.plural-name,
    breadcrumbs => self.resource-breadcrumbs($resource, $resource.plural-name => Nil),
  )
}

method apply-batch {
  my $resource = self.current-resource;
  my $base     = MVC::Keayl::Admin::Config.current.mount-path ~ '/' ~ $resource.slug;

  my @ids  = (self.params<ids> // ()).list.map(*.Int);
  my $name = (self.params<batch-action> // '').Str;

  my @records = @ids ?? $resource.model.where({ id => @ids }).all !! ();

  if @records {
    if $name eq 'Destroy' {
      .destroy for @records;

      self.flash<notice> = @records.elems ~ ' ' ~ $resource.plural-name ~ ' deleted.';
    } else {
      with $resource.batch-actions.first({ .name eq $name }) -> $action {
        $action.block.(@records);

        self.flash<notice> = $name ~ ' applied to ' ~ @records.elems ~ ' ' ~ $resource.plural-name ~ '.';
      }
    }
  }

  self.redirect-to($base);
}

method run-member-action {
  my $resource = self.current-resource;
  my $name     = self.request.path.split('/').grep(*.chars).tail;
  my $record   = self!find-record($resource);

  return self.head(404) without $record;
  return self.forbidden unless self!authorize-record($name, $resource, $record);

  with $resource.member-actions.first({ .name eq $name }) -> $action {
    return $action.block.(self, $record);
  }

  self.head(404)
}

method run-collection-action {
  my $resource = self.current-resource;
  my $name     = self.request.path.split('/').grep(*.chars).tail;

  with $resource.collection-actions.first({ .name eq $name }) -> $action {
    return $action.block.(self, $resource.model.all);
  }

  self.head(404)
}

method destroy {
  my $resource = self.current-resource;
  my $record   = self!find-record($resource);

  return self.head(404) without $record;
  return self.forbidden unless self!authorize-record('destroy', $resource, $record);

  my $index = MVC::Keayl::Admin::Config.current.mount-path ~ '/' ~ $resource.slug;

  $record.destroy;

  self.flash<notice> = $resource.singular-name ~ ' deleted.';

  # An htmx DELETE from the index removes the row in place; a plain POST from the
  # show page (or a no-JavaScript client) falls back to a full-page redirect.
  return self.render(:html('')) if self.request.method eq 'DELETE';

  self.redirect-to($index);
}

method !find-record($resource) {
  my $id = (self.params<id> // '').Str;

  return Nil unless $id ~~ /^ \d+ $/;

  self.policy-scope($resource, self.parent-scoped($resource, $resource.model.all)).where({ id => $id.Int }).first
}

method !list-relation($resource, %params) {
  my $visible = self.policy-scope($resource, self.parent-scoped($resource, $resource.model.all));
  my $scope   = resolve-scope($resource, %params);

  my $relation = apply-scope($scope, $visible);
  $relation = apply-filters($resource, $relation, %params) if $resource.filters-enabled;

  my $sort = %params<sort>;
  my $dir  = (%params<dir> // 'asc') eq 'desc' ?? 'desc' !! 'asc';

  if $sort.defined && $resource.columns.first({ .name eq $sort && .sortable }) {
    $relation = $relation.order($sort ~ ($dir eq 'desc' ?? ' DESC' !! ' ASC'));
  } elsif $resource.sort-column.defined {
    $relation = $relation.order($resource.sort-column ~ ($resource.sort-dir eq 'desc' ?? ' DESC' !! ' ASC'));
  }

  $relation = $relation.includes(|$resource.eager-loads) if $resource.eager-loads;

  $relation
}

method action-items-html($resource, Str:D $action, $abilities, $record = Nil --> Str) {
  $resource.visible-action-items($action, $abilities).map({ .block.(self, $record) }).join
}

method export {
  my $resource = self.current-resource;
  my $format   = (self.params<format> // 'csv').Str;

  return self.head(404) unless $format eq any($resource.export-formats);

  my $relation = self!list-relation($resource, self.params.Hash);

  return self.render(admin-json => export-records($resource, $relation), content-type => 'application/json; charset=utf-8') if $format eq 'json';
  return self.render(admin-xml  => export-records($resource, $relation), content-type => 'application/xml; charset=utf-8')  if $format eq 'xml';

  my @columns = $resource.export-columns;

  my $rows := gather {
    take csv-row(@columns.map({ MVC::Keayl::Admin::I18n.attribute-label($resource.model, .name) }));

    for $relation.all -> $record {
      take csv-row(@columns.map({ export-cell($_, $record) }));
    }
  };

  self.response.content-type('text/csv; charset=utf-8');
  self.response.set-header('Content-Disposition', 'attachment; filename="' ~ $resource.slug ~ '.csv"');
  self.response.stream($rows.map(* ~ "\r\n"));

  self.head(200)
}

# The route action is `new`, but `new` is the object constructor and a reserved
# method name, so the base controller's dispatch maps it here.
method new-record {
  my $resource = self.current-resource;
  my $base     = self.resource-base($resource);

  self.render-form($resource, $resource.model.build, action => $base, submit => 'Create', :$base,
    page-title => 'New ' ~ $resource.singular-name);
}

method create {
  my $resource = self.current-resource;
  my $base     = self.resource-base($resource);

  my %attrs = strong-params($resource, self.params.Hash);

  with self.nested-parent($resource) -> $parent {
    %attrs{self.parent-fk($resource)} = $parent.id;
  }

  my $record = $resource.model.create(%attrs);

  if $record.id {
    attach-files($resource, $record, self.params.Hash);

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
  return self.forbidden unless self!authorize-record('update', $resource, $record);

  my $base = self.resource-base($resource);

  self.render-form($resource, $record, action => $base ~ '/' ~ $record.id, submit => 'Update', :$base,
    page-title => 'Edit ' ~ $resource.singular-name ~ ' #' ~ $record.id);
}

method update {
  my $resource = self.current-resource;
  my $record   = self!find-record($resource);

  return self.head(404) without $record;
  return self.forbidden unless self!authorize-record('update', $resource, $record);

  my $base = self.resource-base($resource);

  if $record.update(strong-params($resource, self.params.Hash)) {
    attach-files($resource, $record, self.params.Hash);

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
    breadcrumbs => self.resource-breadcrumbs($resource, $resource.plural-name => $base, $page-title => Nil),
  )
}

method show {
  my $resource = self.current-resource;
  my $record   = self!find-record($resource);

  return self.head(404) without $record;
  return self.forbidden unless self!authorize-record('show', $resource, $record);

  my $mount = MVC::Keayl::Admin::Config.current.mount-path;
  my $base  = self.resource-base($resource);
  my $title = $resource.singular-name ~ ' #' ~ $record.id;

  my $abilities = self.abilities-for($resource);

  my $toolbar = self.action-items-html($resource, 'show', $abilities, $record);
  self.assign('admin_show_toolbar', $toolbar ?? qq[<div class="d-flex justify-content-end gap-2 mb-3">{$toolbar}</div>] !! '');
  self.assign('admin_show_body',     MVC::Keayl::Admin::Show.render($resource, $record, mount-path => $mount));
  self.assign('admin_show_actions',  MVC::Keayl::Admin::Show.actions($resource, $record, :$base, :$abilities));
  self.assign('admin_show_panels',   MVC::Keayl::Admin::Panels.panels($resource.panels, $record, $abilities));
  self.assign('admin_show_tabs',     MVC::Keayl::Admin::Panels.tabs($resource.tabs, $record, $abilities));
  self.assign('admin_show_sidebars', MVC::Keayl::Admin::Panels.sidebars($resource.sidebars, $record, $abilities, placement => 'show'));

  my @child-links = MVC::Keayl::Admin::Registry.current.children-of($resource.model).map(-> $child {
    qq[<a class="list-group-item list-group-item-action" href="{html-escape($base ~ '/' ~ $record.id ~ '/' ~ $child.slug)}">{html-escape($child.plural-name)}</a>]
  });
  self.assign('admin_show_children', @child-links
    ?? qq[<div class="card mb-3"><div class="card-header">{html-escape(MVC::Keayl::Admin::I18n.chrome('related', 'Related'))}</div><div class="list-group list-group-flush">{@child-links.join}</div></div>]
    !! '');

  self.render-admin(
    'resource/show',
    page-title  => $title,
    breadcrumbs => self.resource-breadcrumbs($resource, $resource.plural-name => $base, $title => Nil),
  )
}

method filters-panel($resource, %params, Str:D :$base, :$sort, :$dir, :$scope --> Str) {
  return '' unless $resource.filters-enabled && MVC::Keayl::Admin::FilterPanel.has-filters($resource);

  my $form = MVC::Keayl::Admin::FilterPanel.form($resource, %params, :$base, :target<#admin-index>, :$sort, :$dir, :$scope);

  qq:to/HTML/.trim;
  <button class="btn btn-secondary" type="button" data-bs-toggle="offcanvas" data-bs-target="#admin-filters"><i class="bi bi-funnel me-1"></i>{html-escape(MVC::Keayl::Admin::I18n.chrome('filters', 'Filters'))}</button>
  <div class="offcanvas offcanvas-end" tabindex="-1" id="admin-filters">
    <div class="offcanvas-header"><h5 class="offcanvas-title">{html-escape(MVC::Keayl::Admin::I18n.chrome('filters', 'Filters'))}</h5><button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close"></button></div>
    <div class="offcanvas-body">{$form}</div>
  </div>
  HTML
}

MVC::Keayl::Admin::ResourceController.before-action('authorize-action');

MVC::Keayl::Admin::ResourceController.add-renderer('admin-json', -> $controller, $data, %opts {
  to-json($data)
});

sub xml-escape(Str() $text --> Str) {
  $text.trans(['&', '<', '>'] => ['&amp;', '&lt;', '&gt;'])
}

MVC::Keayl::Admin::ResourceController.add-renderer('admin-xml', -> $controller, $data, %opts {
  my $records = $data.map(-> %record {
    '<record>' ~ %record.sort(*.key).map(-> $pair {
      '<' ~ $pair.key ~ '>' ~ xml-escape($pair.value.Str) ~ '</' ~ $pair.key ~ '>'
    }).join ~ '</record>'
  }).join;

  '<?xml version="1.0" encoding="UTF-8"?>' ~ "\n" ~ '<records>' ~ $records ~ '</records>'
});
