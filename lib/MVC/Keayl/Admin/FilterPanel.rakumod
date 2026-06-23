use v6.d;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Url;

unit class MVC::Keayl::Admin::FilterPanel;

sub param-keys($filter --> List) {
  $filter.as eq 'date-range'
    ?? ($filter.name ~ '-from', $filter.name ~ '-to')
    !! ($filter.name,)
}

sub filter-active($filter, %params --> Bool) {
  param-keys($filter).first({ (%params{$_} // '').Str ne '' }).defined
}

# The subset of query params that belong to filters, kept so sort and page links
# round-trip the active filter state.
sub gather-active-params($resource, %params --> Hash) {
  my %out;

  for $resource.filters -> $filter {
    for param-keys($filter) -> $key {
      %out{$key} = %params{$key} if (%params{$key} // '').Str ne '';
    }
  }

  %out
}

method active-params(::?CLASS:U: $resource, %params --> Hash) {
  gather-active-params($resource, %params)
}

sub select-options($filter, $current --> Str) {
  my @opts = '<option value="">Any</option>';

  for $filter.collection.() -> $item {
    my ($value, $label) = $item ~~ Pair ?? ($item.key, $item.value) !! ($item, $item);
    my $selected = $value.Str eq ($current // '').Str ?? ' selected' !! '';

    @opts.push: qq[<option value="{html-escape($value.Str)}"{$selected}>{html-escape($label.Str)}</option>];
  }

  @opts.join
}

sub control-for($filter, %params --> Str) {
  my $name    = $filter.name;
  my $current = (%params{$name} // '').Str;
  my $value   = html-escape($current);

  given $filter.as {
    when 'boolean' {
      my $opt = sub ($v, $text) {
        my $selected = $v eq $current ?? ' selected' !! '';
        qq[<option value="{$v}"{$selected}>{$text}</option>]
      };

      qq[<select class="form-select" name="{$name}">{$opt('', 'Any')}{$opt('true', 'Yes')}{$opt('false', 'No')}</select>]
    }

    when 'select' {
      $filter.has-collection
        ?? qq[<select class="form-select" name="{$name}">{select-options($filter, $current)}</select>]
        !! qq[<input class="form-control" type="text" name="{$name}" value="{$value}">]
    }

    when 'numeric' {
      qq[<input class="form-control" type="number" name="{$name}" value="{$value}">]
    }

    when 'date' {
      qq[<input class="form-control" type="date" name="{$name}" value="{$value}">]
    }

    when 'date-range' {
      my $from = html-escape((%params{$name ~ '-from'} // '').Str);
      my $to   = html-escape((%params{$name ~ '-to'} // '').Str);

      qq[<div class="input-group"><input class="form-control" type="date" name="{$name}-from" value="{$from}"><span class="input-group-text">to</span><input class="form-control" type="date" name="{$name}-to" value="{$to}"></div>]
    }

    default {
      qq[<input class="form-control" type="text" name="{$name}" value="{$value}">]
    }
  }
}

sub field-for($filter, %params --> Str) {
  my $label = html-escape(humanize($filter.name));

  qq[<div class="mb-3"><label class="form-label">{$label}</label>{control-for($filter, %params)}</div>]
}

method has-filters(::?CLASS:U: $resource --> Bool) {
  $resource.filters.elems > 0
}

method form(::?CLASS:U: $resource, %params, Str:D :$base, Str:D :$target, :$sort, :$dir, :$scope --> Str) {
  my $fields = $resource.filters.map({ field-for($_, %params) }).join;

  my $hidden = '';
  $hidden ~= qq[<input type="hidden" name="sort" value="{html-escape($sort.Str)}">]   if $sort.defined;
  $hidden ~= qq[<input type="hidden" name="dir" value="{html-escape($dir.Str)}">]     if $dir.defined;
  $hidden ~= qq[<input type="hidden" name="scope" value="{html-escape($scope.Str)}">] if $scope.defined;

  my $clear = html-escape(query-url($base, scope => $scope, sort => $sort, dir => $dir));

  qq:to/HTML/.trim;
  <form hx-get="{html-escape($base)}" hx-target="{$target}" hx-swap="innerHTML">
    {$hidden}{$fields}
    <div class="d-flex gap-2">
      <button type="submit" class="btn btn-primary">Apply</button>
      <a class="btn btn-outline-secondary" hx-get="{$clear}" hx-target="{$target}" hx-swap="innerHTML" href="{$clear}">Clear</a>
    </div>
  </form>
  HTML
}

method chips(::?CLASS:U: $resource, %params, Str:D :$base, Str:D :$target, :$sort, :$dir, :$scope --> Str) {
  my @active = $resource.filters.grep({ filter-active($_, %params) });

  return '' unless @active;

  my @chips;

  for @active -> $filter {
    my %remaining = gather-active-params($resource, %params);
    %remaining{$_}:delete for param-keys($filter);

    my $url   = html-escape(query-url($base, |%remaining, scope => $scope, sort => $sort, dir => $dir));
    my $shown = param-keys($filter).map({ %params{$_} // '' }).grep(*.Str ne '').join(' to ');
    my $label = html-escape(humanize($filter.name) ~ ': ' ~ $shown);

    @chips.push: qq[<a class="badge text-bg-secondary text-decoration-none me-2" hx-get="$url" hx-target="{$target}" hx-swap="innerHTML" href="$url">{$label} &times;</a>];
  }

  my $clear = html-escape(query-url($base, scope => $scope, sort => $sort, dir => $dir));

  @chips.push: qq[<a class="badge text-bg-light text-decoration-none" hx-get="$clear" hx-target="{$target}" hx-swap="innerHTML" href="$clear">Clear all</a>];

  qq[<div class="mb-3">{@chips.join}</div>]
}
