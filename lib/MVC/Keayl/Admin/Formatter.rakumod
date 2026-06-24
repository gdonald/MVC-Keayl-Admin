use v6.d;
use MVC::Keayl::Admin::Inflection;

unit module MVC::Keayl::Admin::Formatter;

sub html-escape(Str() $text --> Str) is export {
  $text.trans(['&', '<', '>', '"'] => ['&amp;', '&lt;', '&gt;', '&quot;'])
}

my %status-variants =
  active => 'success', published => 'success', approved => 'success', completed => 'success',
  enabled => 'success', yes => 'success', true => 'success', live => 'success',
  pending => 'warning', warning => 'warning', review => 'warning',
  inactive => 'secondary', draft => 'secondary', disabled => 'secondary', archived => 'secondary',
  rejected => 'danger', failed => 'danger', error => 'danger', cancelled => 'danger',
  'no' => 'danger', false => 'danger';

sub status-tag-html($value --> Str) is export {
  my ($label, $variant);

  if $value ~~ Bool {
    $label   = $value ?? 'Yes' !! 'No';
    $variant = $value ?? 'success' !! 'secondary';
  } else {
    my $text = $value.Str;
    $label   = humanize($text);
    $variant = %status-variants{$text.lc} // 'secondary';
  }

  qq[<span class="badge text-bg-{$variant}">{html-escape($label)}</span>]
}

sub format-date($value --> Str) {
  $value ~~ DateTime ?? $value.Date.Str !! $value.Str
}

sub format-time($value --> Str) {
  $value ~~ DateTime ?? sprintf('%02d:%02d', $value.hour, $value.minute.Int) !! $value.Str
}

sub format-datetime($value --> Str) {
  $value ~~ DateTime
    ?? sprintf('%s %02d:%02d', $value.Date.Str, $value.hour, $value.minute.Int)
    !! $value.Str
}

sub format-currency($value --> Str) {
  '$' ~ sprintf('%.2f', +$value)
}

sub truncate-text(Str:D $text, Int:D $length --> Str) {
  $text.chars > $length ?? $text.substr(0, $length) ~ '…' !! $text
}

sub format-value($value, Str $format?, Int :$length = 50 --> Str) is export {
  return '' without $value;

  given $format {
    when 'boolean'  { $value ?? 'Yes' !! 'No' }
    when 'date'     { format-date($value) }
    when 'time'     { format-time($value) }
    when 'datetime' { format-datetime($value) }
    when 'currency' { format-currency($value) }
    when 'truncate' { truncate-text($value.Str, $length) }
    default         { $value.Str }
  }
}
