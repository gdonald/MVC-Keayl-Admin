use v6.d;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Url;
use MVC::Keayl::Admin::I18n;

unit class MVC::Keayl::Admin::Table;

sub header-cell($column, $model, Str:D $base, $sort, $dir, Str:D $target, %filters --> Str) {
  my $label = html-escape(MVC::Keayl::Admin::I18n.attribute-label($model, $column.name));

  return '<th>' ~ $label ~ '</th>' unless $column.sortable;

  my $active    = ($sort // '') eq $column.name;
  my $next-dir  = ($active && ($dir // 'asc') eq 'asc') ?? 'desc' !! 'asc';
  my $indicator = $active ?? (($dir // 'asc') eq 'asc' ?? ' &uarr;' !! ' &darr;') !! '';
  my $url       = html-escape(query-url($base, |%filters, sort => $column.name, dir => $next-dir, page => 1));

  qq[<th><a class="text-decoration-none" hx-get="$url" hx-target="$target" hx-swap="innerHTML" href="$url">{$label}{$indicator}</a></th>]
}

sub cell-value($column, $record) {
  $column.display.defined ?? $column.display.($record) !! $record.read-attribute($column.name)
}

sub cell-html($column, $record, Str:D $base --> Str) {
  my $value = cell-value($column, $record);

  return $value.Str if $column.html;

  return status-tag-html($value) if ($column.format // '') eq 'status-tag' && $value.defined;

  if ($column.format // '') eq 'link-to-show' {
    my $href = html-escape($base ~ '/' ~ $record.id);

    return qq[<a href="$href">{html-escape(format-value($value))}</a>];
  }

  html-escape(format-value($value, $column.format))
}

sub allowed($abilities, Str:D $action --> Bool) {
  !$abilities.defined || $abilities.can($action)
}

sub row-actions(Str:D $base, $id, $abilities --> Str) {
  my $show = html-escape($base ~ '/' ~ $id);
  my $edit = html-escape($base ~ '/' ~ $id ~ '/edit');

  my $buttons = '';
  $buttons ~= qq[<a class="btn btn-outline-secondary" href="$show">{html-escape(MVC::Keayl::Admin::I18n.chrome('show', 'Show'))}</a>]     if allowed($abilities, 'show');
  $buttons ~= qq[<a class="btn btn-outline-secondary" href="$edit">{html-escape(MVC::Keayl::Admin::I18n.chrome('edit', 'Edit'))}</a>]     if allowed($abilities, 'update');
  $buttons ~= qq[<button type="button" class="btn btn-outline-danger" hx-delete="$show" hx-confirm="{html-escape(MVC::Keayl::Admin::I18n.chrome('confirm-delete', 'Delete this record?'))}" hx-target="closest tr" hx-swap="delete">{html-escape(MVC::Keayl::Admin::I18n.chrome('delete', 'Delete'))}</button>] if allowed($abilities, 'destroy');

  qq[<div class="btn-group btn-group-sm" role="group">{$buttons}</div>]
}

method render(::?CLASS:U: $resource, @records, Str:D :$base, :$sort, :$dir, Str:D :$target = '#admin-index', :%filters, Bool :$batch = False, :$abilities --> Str) {
  my @columns = $resource.columns;

  my $select-head = $batch ?? '<th style="width: 1rem"></th>' !! '';

  my $head = $select-head
    ~ @columns.map({ header-cell($_, $resource.model, $base, $sort, $dir, $target, %filters) }).join
    ~ qq[<th class="text-end">{html-escape(MVC::Keayl::Admin::I18n.chrome('actions', 'Actions'))}</th>];

  my $body;

  if @records {
    $body = @records.map(-> $record {
      my $select = $batch
        ?? qq[<td><input class="form-check-input" type="checkbox" data-batch-select name="ids[]" value="{$record.id}"></td>]
        !! '';
      my $cells = @columns.map({ '<td>' ~ cell-html($_, $record, $base) ~ '</td>' }).join;

      qq[<tr>{$select}{$cells}<td class="text-end">{row-actions($base, $record.id, $abilities)}</td></tr>]
    }).join;
  } else {
    my $span = @columns.elems + 1 + ($batch ?? 1 !! 0);

    $body = qq[<tr><td colspan="$span" class="text-center text-muted py-4">{html-escape(MVC::Keayl::Admin::I18n.chrome('no-records', 'No records yet.'))}</td></tr>];
  }

  qq[<table class="table table-striped table-hover align-middle"><thead><tr>{$head}</tr></thead><tbody>{$body}</tbody></table>]
}
