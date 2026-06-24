use v6.d;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::I18n;
use MVC::Keayl::Admin::Table;

unit class MVC::Keayl::Admin::IndexView;

sub allowed($abilities, Str:D $action --> Bool) {
  !$abilities.defined || $abilities.can($action)
}

sub column-value($column, $record --> Str) {
  my $value = $column.display.defined ?? $column.display.($record) !! $record.read-attribute($column.name);

  html-escape(format-value($value, $column.format))
}

sub select-box($record, Bool $batch --> Str) {
  return '' unless $batch;

  qq[<input class="form-check-input" type="checkbox" data-batch-select name="ids[]" value="{$record.id}">]
}

sub record-actions(Str:D $base, $id, $abilities, Str:D $remove-target --> Str) {
  my $show = html-escape($base ~ '/' ~ $id);
  my $edit = html-escape($base ~ '/' ~ $id ~ '/edit');

  my $buttons = '';
  $buttons ~= qq[<a class="btn btn-sm btn-outline-secondary" href="$show">{html-escape(MVC::Keayl::Admin::I18n.chrome('show', 'Show'))}</a>] if allowed($abilities, 'show');
  $buttons ~= qq[<a class="btn btn-sm btn-outline-secondary" href="$edit">{html-escape(MVC::Keayl::Admin::I18n.chrome('edit', 'Edit'))}</a>] if allowed($abilities, 'update');
  $buttons ~= qq[<button type="button" class="btn btn-sm btn-outline-danger" hx-delete="$show" hx-confirm="{html-escape(MVC::Keayl::Admin::I18n.chrome('confirm-delete', 'Delete this record?'))}" hx-target="closest {$remove-target}" hx-swap="delete">{html-escape(MVC::Keayl::Admin::I18n.chrome('delete', 'Delete'))}</button>] if allowed($abilities, 'destroy');

  qq[<div class="btn-group" role="group">{$buttons}</div>]
}

sub empty-state(--> Str) {
  qq[<p class="text-center text-muted py-4">{html-escape(MVC::Keayl::Admin::I18n.chrome('no-records', 'No records yet.'))}</p>]
}

sub default-body($resource, $record --> Str) {
  $resource.columns.map(-> $column {
    qq[<div><span class="text-muted small">{html-escape(MVC::Keayl::Admin::I18n.attribute-label($resource.model, $column.name))}</span><div>{column-value($column, $record)}</div></div>]
  }).join
}

sub grid-html($resource, @records, Str:D $base, $abilities, Bool $batch --> Str) {
  return empty-state() unless @records;

  my $cards = @records.map(-> $record {
    my $body  = $resource.index-block.defined ?? $resource.index-block.($record) !! default-body($resource, $record);
    my $check = $batch ?? qq[<div class="form-check mb-2">{select-box($record, $batch)}</div>] !! '';

    qq[<div class="col"><div class="card h-100">{$check}<div class="card-body">{$body}</div><div class="card-footer">{record-actions($base, $record.id, $abilities, '.col')}</div></div></div>]
  }).join;

  qq[<div class="row row-cols-1 row-cols-sm-2 row-cols-lg-3 g-3">{$cards}</div>]
}

sub blog-html($resource, @records, Str:D $base, $abilities, Bool $batch --> Str) {
  return empty-state() unless @records;

  my $items = @records.map(-> $record {
    my $body  = $resource.index-block.defined ?? $resource.index-block.($record) !! default-body($resource, $record);
    my $check = $batch ?? qq[<div class="form-check">{select-box($record, $batch)}</div>] !! '';

    qq[<article class="d-flex gap-3 border-bottom py-3">{$check}<div class="flex-grow-1">{$body}</div><div>{record-actions($base, $record.id, $abilities, 'article')}</div></article>]
  }).join;

  qq[<div class="admin-blog">{$items}</div>]
}

method render(::?CLASS:U: $resource, @records, Str:D :$mount-path, :$sort, :$dir, Str:D :$target = '#admin-index', :%filters, Bool :$batch = False, :$abilities --> Str) {
  my $base = $mount-path ~ '/' ~ $resource.slug;

  given $resource.index-as {
    when 'grid' { grid-html($resource, @records, $base, $abilities, $batch) }
    when 'blog' { blog-html($resource, @records, $base, $abilities, $batch) }
    default     { MVC::Keayl::Admin::Table.render($resource, @records, :$mount-path, :$sort, :$dir, :$target, :%filters, :$batch, :$abilities) }
  }
}
