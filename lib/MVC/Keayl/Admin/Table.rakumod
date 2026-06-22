use v6.d;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Url;

unit class MVC::Keayl::Admin::Table;

sub column-label($column --> Str) {
  humanize($column.name)
}

sub header-cell($column, Str:D $base, $sort, $dir, Str:D $target --> Str) {
  my $label = html-escape(column-label($column));

  return '<th>' ~ $label ~ '</th>' unless $column.sortable;

  my $active    = ($sort // '') eq $column.name;
  my $next-dir  = ($active && ($dir // 'asc') eq 'asc') ?? 'desc' !! 'asc';
  my $indicator = $active ?? (($dir // 'asc') eq 'asc' ?? ' &uarr;' !! ' &darr;') !! '';
  my $url       = html-escape(query-url($base, sort => $column.name, dir => $next-dir, page => 1));

  qq[<th><a class="text-decoration-none" hx-get="$url" hx-target="$target" hx-swap="innerHTML" href="$url">{$label}{$indicator}</a></th>]
}

sub cell-value($column, $record) {
  $column.display.defined ?? $column.display.($record) !! $record.read-attribute($column.name)
}

sub cell-html($column, $record, Str:D $base --> Str) {
  my $value = cell-value($column, $record);

  if ($column.format // '') eq 'link-to-show' {
    my $href = html-escape($base ~ '/' ~ $record.id);

    return qq[<a href="$href">{html-escape(format-value($value))}</a>];
  }

  html-escape(format-value($value, $column.format))
}

sub row-actions(Str:D $base, $id --> Str) {
  my $show = html-escape($base ~ '/' ~ $id);
  my $edit = html-escape($base ~ '/' ~ $id ~ '/edit');

  qq:to/HTML/.trim;
  <div class="btn-group btn-group-sm" role="group">
    <a class="btn btn-outline-secondary" href="$show">Show</a>
    <a class="btn btn-outline-secondary" href="$edit">Edit</a>
    <button type="button" class="btn btn-outline-danger" hx-delete="$show" hx-confirm="Delete this record?">Delete</button>
  </div>
  HTML
}

method render(::?CLASS:U: $resource, @records, Str:D :$mount-path, :$sort, :$dir, Str:D :$target = '#admin-index' --> Str) {
  my @columns = $resource.columns;
  my $base    = $mount-path ~ '/' ~ $resource.slug;

  my $head = @columns.map({ header-cell($_, $base, $sort, $dir, $target) }).join
    ~ '<th class="text-end">Actions</th>';

  my $body;

  if @records {
    $body = @records.map(-> $record {
      my $cells = @columns.map({ '<td>' ~ cell-html($_, $record, $base) ~ '</td>' }).join;

      qq[<tr>{$cells}<td class="text-end">{row-actions($base, $record.id)}</td></tr>]
    }).join;
  } else {
    my $span = @columns.elems + 1;

    $body = qq[<tr><td colspan="$span" class="text-center text-muted py-4">No records yet.</td></tr>];
  }

  qq[<table class="table table-striped table-hover align-middle"><thead><tr>{$head}</tr></thead><tbody>{$body}</tbody></table>]
}
