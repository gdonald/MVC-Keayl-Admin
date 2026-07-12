use v6.d;
use MVC::Keayl::I18n;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::I18n;

unit class MVC::Keayl::Admin::Form;

sub i18n(--> MVC::Keayl::I18n) {
  MVC::Keayl::Admin::I18n.backend
}

sub column-of($field --> Str) {
  $field.name.subst('-', '_', :g)
}

sub label-for($model, $field --> Str) {
  return html-escape($field.label) if $field.label.defined;
  html-escape(i18n.human-attribute-name($model, column-of($field)))
}

sub select-html($field, Str:D $input-name, $raw --> Str) {
  my $current  = ($raw // '').Str;
  my $name     = $field.multiple ?? $input-name ~ '[]' !! $input-name;
  my $multiple = $field.multiple ?? ' multiple' !! '';

  my @options = $field.multiple ?? () !! ('<option value=""></option>',);

  for $field.collection.() -> $item {
    my ($value, $label) = $item ~~ Pair ?? ($item.key, $item.value) !! ($item, $item);
    my $selected = (!$field.multiple && $value.Str eq $current) ?? ' selected' !! '';

    @options.push: qq[<option value="{html-escape($value.Str)}"{$selected}>{html-escape($label.Str)}</option>];
  }

  qq[<select class="form-select" name="{$name}"{$multiple}>{@options.join}</select>]
}

# Format a raw attribute for a native date/time input. Those inputs require an
# exact string (YYYY-MM-DD, HH:MM, YYYY-MM-DDTHH:MM) and silently blank a value
# carrying a timezone offset, which is exactly how a DateTime stringifies, so
# pull the parts out. A value that is already a string passes through unchanged.
sub input-value($raw, Str:D $type --> Str) {
  return '' without $raw;

  if $type eq 'date' && $raw ~~ Dateish {
    return sprintf('%04d-%02d-%02d', $raw.year, $raw.month, $raw.day);
  }
  if $type eq 'time' && $raw ~~ DateTime {
    return sprintf('%02d:%02d', $raw.hour, $raw.minute);
  }
  if $type eq 'datetime' && $raw ~~ DateTime {
    return sprintf('%04d-%02d-%02dT%02d:%02d', $raw.year, $raw.month, $raw.day, $raw.hour, $raw.minute);
  }

  $raw.Str
}

sub control-html($field, Str:D $input-name, $raw --> Str) {
  my $value = html-escape(($raw // '').Str);
  my $place = $field.placeholder.defined ?? qq[ placeholder="{html-escape($field.placeholder)}"] !! '';

  given $field.as {
    when 'text'     {
      my $rows = $field.rows.defined ?? qq[ rows="{$field.rows}"] !! '';
      qq[<textarea class="form-control" name="{$input-name}"{$rows}{$place}>{$value}</textarea>]
    }
    when 'select'   { select-html($field, $input-name, $raw) }
    when 'boolean'  {
      my $checked = $raw ?? ' checked' !! '';
      qq[<div class="form-check"><input class="form-check-input" type="checkbox" name="{$input-name}" value="1"{$checked}></div>]
    }
    when 'number'   { qq[<input class="form-control" type="number" name="{$input-name}" value="{$value}"{$place}>] }
    when 'date'     { qq[<input class="form-control" type="date" name="{$input-name}" value="{html-escape(input-value($raw, 'date'))}">] }
    when 'time'     { qq[<input class="form-control" type="time" name="{$input-name}" value="{html-escape(input-value($raw, 'time'))}">] }
    when 'datetime' { qq[<input class="form-control" type="datetime-local" name="{$input-name}" value="{html-escape(input-value($raw, 'datetime'))}">] }
    when 'password' { qq[<input class="form-control" type="password" name="{$input-name}"{$place}>] }
    when 'hidden'   { qq[<input type="hidden" name="{$input-name}" value="{$value}">] }
    when 'file'     { qq[<input class="form-control" type="file" name="{$input-name}">] }
    default         { qq[<input class="form-control" type="text" name="{$input-name}" value="{$value}"{$place}>] }
  }
}

sub control-for($field, $record --> Str) {
  my $raw = $field.has-value ?? $field.value.($record) !! $record.read-attribute(column-of($field));
  control-html($field, $field.name, $raw)
}

sub field-errors($record, $field --> Str) {
  my @messages = $record.errors.full-messages-for(column-of($field));

  return '' unless @messages;

  qq[<div class="invalid-feedback d-block">{html-escape(@messages.join(', '))}</div>]
}

sub field-group($model, $record, $field --> Str) {
  return control-for($field, $record) if $field.as eq 'hidden';

  my $label = label-for($model, $field);
  my $hint  = $field.hint.defined ?? qq[<div class="form-text">{html-escape($field.hint)}</div>] !! '';

  qq[<div class="mb-3"><label class="form-label">{$label}</label>{control-for($field, $record)}{$hint}{field-errors($record, $field)}</div>]
}

sub nested-group($field, Str:D $input-name, $value --> Str) {
  return control-html($field, $input-name, $value) if $field.as eq 'hidden';

  my $label = html-escape(humanize($field.name));

  qq[<div class="mb-3"><label class="form-label">{$label}</label>{control-html($field, $input-name, $value)}</div>]
}

sub nested-fieldset($record, $nested --> Str) {
  my $prefix   = $nested.name ~ '-attributes';
  my $assoc    = $record."{$nested.name}"();

  # A has-many nested fieldset renders its existing children plus one blank row
  # for adding a new child. A blank row is skipped on save by the model's
  # reject-if.
  my @children = $nested.multiple ?? (|$assoc.list, Nil) !! ($assoc,);

  my @rows = @children.map(-> $child {
    my $groups = $nested.fields.map(-> $field {
      my $input = $nested.multiple ?? "{$prefix}[][{$field.name}]" !! "{$prefix}[{$field.name}]";
      my $value = $child.defined ?? $child.read-attribute(column-of($field)) !! Nil;

      nested-group($field, $input, $value)
    }).join;

    qq[<div class="border rounded p-3 mb-2">{$groups}</div>]
  });

  qq[<fieldset class="mb-3"><legend class="fs-6">{html-escape(humanize($nested.name))}</legend>{@rows.join}</fieldset>]
}

sub error-summary($record --> Str) {
  my @messages = $record.errors.full-messages;

  return '' unless @messages;

  my $items = @messages.map({ '<li>' ~ html-escape($_) ~ '</li>' }).join;

  qq[<div class="alert alert-danger"><ul class="mb-0">{$items}</ul></div>]
}

method render(::?CLASS:U: $resource, $record, Str:D :$action, Str:D :$submit, Str:D :$cancel --> Str) {
  my $fields  = $resource.fields.map({ field-group($resource.model, $record, $_) }).join;
  my $nested  = $resource.nested-attributes.map({ nested-fieldset($record, $_) }).join;
  my $enctype = $resource.fields.first(*.as eq 'file').defined ?? ' enctype="multipart/form-data"' !! '';

  qq:to/HTML/.trim;
  <form method="post" action="{html-escape($action)}"{$enctype}>
    {error-summary($record)}
    {$fields}{$nested}
    <div class="d-flex gap-2">
      <button type="submit" class="btn btn-primary">{html-escape($submit)}</button>
      <a class="btn btn-secondary" href="{html-escape($cancel)}">Cancel</a>
    </div>
  </form>
  HTML
}
