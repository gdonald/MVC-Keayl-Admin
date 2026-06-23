use v6.d;
use MVC::Keayl::I18n;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Formatter;

unit class MVC::Keayl::Admin::Form;

my $default-i18n;

sub i18n(--> MVC::Keayl::I18n) {
  $default-i18n //= MVC::Keayl::I18n.new(default-locale => 'en')
}

sub column-of($field --> Str) {
  $field.name.subst('-', '_', :g)
}

sub label-for($model, $field --> Str) {
  html-escape(i18n.human-attribute-name($model, column-of($field)))
}

sub select-input($field, $record --> Str) {
  my $current  = ($record.read-attribute(column-of($field)) // '').Str;
  my $name     = $field.multiple ?? $field.name ~ '[]' !! $field.name;
  my $multiple = $field.multiple ?? ' multiple' !! '';

  my @options = $field.multiple ?? () !! ('<option value=""></option>',);

  for $field.collection.() -> $item {
    my ($value, $label) = $item ~~ Pair ?? ($item.key, $item.value) !! ($item, $item);
    my $selected = (!$field.multiple && $value.Str eq $current) ?? ' selected' !! '';

    @options.push: qq[<option value="{html-escape($value.Str)}"{$selected}>{html-escape($label.Str)}</option>];
  }

  qq[<select class="form-select" name="{$name}"{$multiple}>{@options.join}</select>]
}

sub control-for($field, $record --> Str) {
  my $name  = $field.name;
  my $value = html-escape(($record.read-attribute(column-of($field)) // '').Str);
  my $place = $field.placeholder.defined ?? qq[ placeholder="{html-escape($field.placeholder)}"] !! '';

  given $field.as {
    when 'text'     { qq[<textarea class="form-control" name="{$name}"{$place}>{$value}</textarea>] }
    when 'select'   { select-input($field, $record) }
    when 'boolean'  {
      my $checked = $record.read-attribute(column-of($field)) ?? ' checked' !! '';
      qq[<div class="form-check"><input class="form-check-input" type="checkbox" name="{$name}" value="1"{$checked}></div>]
    }
    when 'number'   { qq[<input class="form-control" type="number" name="{$name}" value="{$value}"{$place}>] }
    when 'date'     { qq[<input class="form-control" type="date" name="{$name}" value="{$value}">] }
    when 'time'     { qq[<input class="form-control" type="time" name="{$name}" value="{$value}">] }
    when 'datetime' { qq[<input class="form-control" type="datetime-local" name="{$name}" value="{$value}">] }
    when 'password' { qq[<input class="form-control" type="password" name="{$name}"{$place}>] }
    when 'hidden'   { qq[<input type="hidden" name="{$name}" value="{$value}">] }
    when 'file'     { qq[<input class="form-control" type="file" name="{$name}">] }
    default         { qq[<input class="form-control" type="text" name="{$name}" value="{$value}"{$place}>] }
  }
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

sub error-summary($record --> Str) {
  my @messages = $record.errors.full-messages;

  return '' unless @messages;

  my $items = @messages.map({ '<li>' ~ html-escape($_) ~ '</li>' }).join;

  qq[<div class="alert alert-danger"><ul class="mb-0">{$items}</ul></div>]
}

method render(::?CLASS:U: $resource, $record, Str:D :$action, Str:D :$submit, Str:D :$cancel --> Str) {
  my $fields = $resource.fields.map({ field-group($resource.model, $record, $_) }).join;

  qq:to/HTML/.trim;
  <form method="post" action="{html-escape($action)}">
    {error-summary($record)}
    {$fields}
    <div class="d-flex gap-2">
      <button type="submit" class="btn btn-primary">{html-escape($submit)}</button>
      <a class="btn btn-outline-secondary" href="{html-escape($cancel)}">Cancel</a>
    </div>
  </form>
  HTML
}
