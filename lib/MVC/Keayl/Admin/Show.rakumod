use v6.d;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Registry;

unit class MVC::Keayl::Admin::Show;

sub record-link(Str:D $mount, $target, $record, Str:D $text --> Str) {
  $target.defined
    ?? qq[<a href="{html-escape($mount ~ '/' ~ $target.slug ~ '/' ~ $record.id)}">{html-escape($text)}</a>]
    !! html-escape($text)
}

sub belongs-to-cell($attribute, $record, $reflection, Str:D $mount --> Str) {
  my $associated = $record."{$attribute.name}"();

  return '<span class="text-muted">&mdash;</span>' without $associated;

  my $text   = $attribute.display.defined ?? $attribute.display.($record).Str !! ($reflection.class-name ~ ' #' ~ $associated.id);
  my $target = MVC::Keayl::Admin::Registry.current.by-model($reflection.klass);

  record-link($mount, $target, $associated, $text)
}

sub has-many-cell($attribute, $record, $reflection, Str:D $mount --> Str) {
  my @all   = $record."{$attribute.name}"().list;
  my $count = @all.elems;

  return '<span class="text-muted">None</span>' unless $count;

  my $target = MVC::Keayl::Admin::Registry.current.by-model($reflection.klass);
  my @items  = @all.head(10);

  my @rows = @items.map(-> $item {
    '<tr><td>' ~ record-link($mount, $target, $item, $reflection.class-name ~ ' #' ~ $item.id) ~ '</td></tr>'
  });

  my $more = $count > @items.elems
    ?? qq[<tr><td class="text-muted small">and {$count - @items.elems} more</td></tr>]
    !! '';

  qq[<table class="table table-sm mb-0"><tbody>{@rows.join}{$more}</tbody></table>]
}

sub value-cell($attribute, $record --> Str) {
  my $value = $attribute.display.defined ?? $attribute.display.($record) !! $record.read-attribute($attribute.name);

  html-escape(format-value($value, $attribute.format))
}

method render(::?CLASS:U: $resource, $record, Str:D :$mount-path --> Str) {
  my @rows = $resource.attributes.map(-> $attribute {
    my $reflection = $resource.model.reflect-on-association($attribute.name);

    my $cell = do {
      if $reflection.defined && $reflection.is-singular {
        belongs-to-cell($attribute, $record, $reflection, $mount-path);
      } elsif $reflection.defined && $reflection.is-collection {
        has-many-cell($attribute, $record, $reflection, $mount-path);
      } else {
        value-cell($attribute, $record);
      }
    };

    qq[<tr><th class="text-nowrap" style="width: 12rem">{html-escape(humanize($attribute.name))}</th><td>{$cell}</td></tr>]
  });

  qq[<table class="table"><tbody>{@rows.join}</tbody></table>]
}

method actions(::?CLASS:U: $resource, $record, Str:D :$mount-path --> Str) {
  my $base = $mount-path ~ '/' ~ $resource.slug;
  my $edit = html-escape($base ~ '/' ~ $record.id ~ '/edit');
  my $show = html-escape($base ~ '/' ~ $record.id);

  qq:to/HTML/.trim;
  <div class="list-group">
    <a class="list-group-item list-group-item-action" href="$edit"><i class="bi bi-pencil me-2"></i>Edit</a>
    <button type="button" class="list-group-item list-group-item-action text-danger" hx-delete="$show" hx-confirm="Delete this record?"><i class="bi bi-trash me-2"></i>Delete</button>
  </div>
  HTML
}
