use v6.d;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Url;

unit class MVC::Keayl::Admin::Scopes;

method render(::?CLASS:U: $resource, :$active, Str:D :$base, Str:D :$target = '#admin-index', :%filters, :$sort, :$dir, :%counts --> Str) {
  my @scopes = $resource.scopes;

  return '' unless @scopes;

  my @tabs = @scopes.map(-> $scope {
    my $is-active = $active.defined && $scope.name eq $active.name;
    my $class     = 'nav-link' ~ ($is-active ?? ' active' !! '');
    my $url       = html-escape(query-url($base, |%filters, scope => $scope.name, sort => $sort, dir => $dir));

    my $count = %counts{$scope.name}:exists
      ?? qq[ <span class="badge text-bg-secondary">{%counts{$scope.name}}</span>]
      !! '';

    qq[<li class="nav-item"><a class="$class" hx-get="$url" hx-target="{$target}" hx-swap="innerHTML" href="$url">{html-escape($scope.name)}{$count}</a></li>]
  });

  qq[<ul class="nav nav-tabs mb-3">{@tabs.join}</ul>]
}
