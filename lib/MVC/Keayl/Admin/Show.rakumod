use v6.d;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::I18n;

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
  # A :display override wins over the default per-record links, so a collection
  # can be summarised (e.g. a comma-joined string) instead of listed.
  if $attribute.display.defined {
    my $value = $attribute.display.($record);
    return $attribute.html ?? $value.Str !! html-escape($value.Str);
  }

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

  return $value.Str if $attribute.html;

  return status-tag-html($value) if ($attribute.format // '') eq 'status-tag' && $value.defined;

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

    qq[<tr><th class="text-nowrap" style="width: 12rem">{html-escape(MVC::Keayl::Admin::I18n.attribute-label($resource.model, $attribute.name))}</th><td>{$cell}</td></tr>]
  });

  qq[<table class="table"><tbody>{@rows.join}</tbody></table>]
}

sub member-action-form($action, Str:D $base, $record --> Str) {
  my $url     = html-escape($base ~ '/' ~ $record.id ~ '/' ~ $action.name);
  my $label   = html-escape(MVC::Keayl::Admin::I18n.action-label($action.name));
  my $confirm = $action.confirm.defined ?? qq[ onsubmit="return confirm('{html-escape($action.confirm)}')"] !! '';

  qq[<form method="post" action="$url"{$confirm}><button type="submit" class="list-group-item list-group-item-action w-100 text-start">{$label}</button></form>]
}

sub allowed($abilities, Str:D $action --> Bool) {
  !$abilities.defined || $abilities.can($action)
}

method actions(::?CLASS:U: $resource, $record, Str:D :$base, :$abilities --> Str) {
  my $edit   = html-escape($base ~ '/' ~ $record.id ~ '/edit');
  my $delete = html-escape($base ~ '/' ~ $record.id ~ '/delete');

  my $items = '';

  $items ~= qq[<a class="list-group-item list-group-item-action" href="$edit"><i class="bi bi-pencil me-2"></i>{html-escape(MVC::Keayl::Admin::I18n.chrome('edit', 'Edit'))}</a>]
    if allowed($abilities, 'update');

  $items ~= $resource.member-actions.grep({ allowed($abilities, .name) }).map({ member-action-form($_, $base, $record) }).join;

  $items ~= qq[<form method="post" action="$delete" onsubmit="return confirm('{html-escape(MVC::Keayl::Admin::I18n.chrome('confirm-delete', 'Delete this record?'))}')"><button type="submit" class="list-group-item list-group-item-action text-danger w-100 text-start"><i class="bi bi-trash me-2"></i>{html-escape(MVC::Keayl::Admin::I18n.chrome('delete', 'Delete'))}</button></form>]
    if allowed($abilities, 'destroy');

  qq[<div class="list-group">{$items}</div>]
}
