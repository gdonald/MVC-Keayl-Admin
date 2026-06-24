use v6.d;
use MVC::Keayl::Admin::Formatter;

unit class MVC::Keayl::Admin::Panels;

sub visible($panel, $abilities --> Bool) {
  return True unless $panel.if-can.defined;

  !$abilities.defined || $abilities.can($panel.if-can)
}

sub card(Str:D $title, Str:D $body --> Str) {
  qq[<div class="card mb-3"><div class="card-header">{html-escape($title)}</div><div class="card-body">{$body}</div></div>]
}

method sidebars(::?CLASS:U: @sidebars, $context, $abilities, Str:D :$placement --> Str) {
  @sidebars
    .grep({ .on eq $placement || .on eq 'both' })
    .grep({ visible($_, $abilities) })
    .sort(*.priority)
    .map({ card(.title, .block.($context)) })
    .join
}

method panels(::?CLASS:U: @panels, $record, $abilities --> Str) {
  @panels
    .grep({ visible($_, $abilities) })
    .sort(*.priority)
    .map({ card(.title, .block.($record)) })
    .join
}

method tabs(::?CLASS:U: @tabs, $record, $abilities --> Str) {
  my @visible = @tabs.grep({ visible($_, $abilities) }).sort(*.priority);

  return '' unless @visible;

  my $nav = @visible.kv.map(-> $index, $tab {
    my $active = $index == 0 ?? ' active' !! '';

    qq[<li class="nav-item"><button class="nav-link{$active}" data-bs-toggle="tab" data-bs-target="#admin-tab-{$index}" type="button">{html-escape($tab.title)}</button></li>]
  }).join;

  my $panes = @visible.kv.map(-> $index, $tab {
    my $active = $index == 0 ?? ' show active' !! '';

    qq[<div class="tab-pane fade{$active}" id="admin-tab-{$index}">{$tab.block.($record)}</div>]
  }).join;

  qq[<div class="card mb-3"><div class="card-header"><ul class="nav nav-tabs card-header-tabs">{$nav}</ul></div><div class="card-body"><div class="tab-content">{$panes}</div></div></div>]
}
