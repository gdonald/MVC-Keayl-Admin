use v6.d;
use MVC::Keayl::Admin::Url;
use MVC::Keayl::Admin::Formatter;

unit class MVC::Keayl::Admin::Pagination;

sub page-item(Str:D $label, Int:D $n, Bool:D $enabled, Str:D $base, $sort, $dir, Str:D $target, Bool :$active = False --> Str) {
  my $class = 'page-item' ~ ($active ?? ' active' !! '') ~ ($enabled ?? '' !! ' disabled');

  unless $enabled && !$active {
    return qq[<li class="$class"><span class="page-link">{html-escape($label)}</span></li>];
  }

  my $url = html-escape(query-url($base, page => $n, sort => $sort, dir => $dir));

  qq[<li class="$class"><a class="page-link" hx-get="$url" hx-target="$target" hx-swap="innerHTML" href="$url">{html-escape($label)}</a></li>]
}

method render(::?CLASS:U: Str:D :$base, Int:D :$page, Int:D :$per, Int:D :$total, :$sort, :$dir, Str:D :$target = '#admin-index' --> Str) {
  my $pages = max(1, ceiling($total / $per));
  my $from  = $total == 0 ?? 0 !! ($page - 1) * $per + 1;
  my $to    = min($page * $per, $total);

  my $summary = qq[<div class="text-muted small">Showing {$from}&ndash;{$to} of {$total}</div>];

  return qq[<div class="mt-3">{$summary}</div>] if $pages <= 1;

  my @items;

  @items.push: page-item('Previous', $page - 1, $page > 1, $base, $sort, $dir, $target);

  for 1 .. $pages -> $n {
    @items.push: page-item($n.Str, $n, True, $base, $sort, $dir, $target, :active($n == $page));
  }

  @items.push: page-item('Next', $page + 1, $page < $pages, $base, $sort, $dir, $target);

  qq[<nav class="d-flex justify-content-between align-items-center mt-3"><ul class="pagination mb-0">{@items.join}</ul>{$summary}</nav>]
}
