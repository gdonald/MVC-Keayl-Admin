use v6.d;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::Registry;

unit class MVC::Keayl::Admin::Menu;

my @links;
my @group-order;

method add-link(::?CLASS:U: Str:D :$label, Str:D :$url, Str :$group, Int :$priority = 0, Str :$icon, Bool :$external = False --> Nil) {
  @links.push: %( :$label, :$url, :$group, :$priority, :$icon, :$external );
}

method group-order(::?CLASS:U: *@groups --> Nil) {
  @group-order = @groups;
}

method reset(::?CLASS:U: --> Nil) {
  @links       = ();
  @group-order = ();
}

sub item-html(%item --> Str) {
  my $active = %item<active> ?? ' active' !! '';
  my $icon   = %item<icon>.defined ?? qq[<i class="bi bi-{html-escape(%item<icon>)} me-2"></i>] !! '';
  my $target = %item<external> ?? ' target="_blank" rel="noopener"' !! '';

  qq[<li class="nav-item"><a class="nav-link{$active}" href="{html-escape(%item<url>)}"{$target}>{$icon}{html-escape(%item<label>)}</a></li>]
}

sub list-html(@items --> Str) {
  '<ul class="nav nav-pills flex-column">' ~ @items.map(&item-html).join ~ '</ul>'
}

sub group-html(Str:D $name, @items --> Str) {
  my $id   = 'menu-group-' ~ dasherize(underscore($name));
  my $show = @items.first(*<active>).defined ?? ' show' !! '';

  qq:to/HTML/.trim;
  <div class="mt-2">
    <a class="d-flex justify-content-between align-items-center text-uppercase small text-muted text-decoration-none px-2" data-bs-toggle="collapse" href="#{$id}" role="button">
      {html-escape($name)}<i class="bi bi-chevron-down"></i>
    </a>
    <div class="collapse{$show}" id="{$id}">{list-html(@items)}</div>
  </div>
  HTML
}

method render(::?CLASS:U: Str:D :$mount, Str:D :$active-slug = '' --> Str) {
  my @items;

  @items.push: %( label => 'Dashboard', url => $mount, icon => 'speedometer2', priority => -1, group => Str, external => False, active => ($active-slug eq '') );

  for MVC::Keayl::Admin::Registry.current.all -> $resource {
    my $entry = $resource.menu-entry;

    next if $entry.defined && $entry.hide;

    @items.push: %(
      label    => ($entry.defined && $entry.label.defined) ?? $entry.label !! $resource.plural-name,
      url      => $mount ~ '/' ~ $resource.slug,
      icon     => ($entry.defined && $entry.icon.defined) ?? $entry.icon !! 'list-ul',
      priority => ($entry.defined ?? $entry.priority !! 0),
      group    => ($entry.defined ?? $entry.group !! Str),
      external => False,
      active   => ($resource.slug eq $active-slug),
    );
  }

  for @links -> %link {
    @items.push: %(
      label    => %link<label>,
      url      => %link<external> ?? %link<url> !! $mount ~ %link<url>,
      icon     => %link<icon> // 'link-45deg',
      priority => %link<priority>,
      group    => %link<group>,
      external => %link<external>,
      active   => False,
    );
  }

  my sub ordered(@list) { @list.sort({ (.<priority>, .<label>) }) }

  my @ungrouped = ordered(@items.grep({ !.<group>.defined }));

  my @group-names = @items.grep({ .<group>.defined }).map(*.<group>).unique;
  my @ordered-groups = (|@group-order.grep({ $_ ∈ @group-names }), |@group-names.grep({ $_ ∉ @group-order }).sort);

  my $sections = @ordered-groups.map(-> $name {
    group-html($name, ordered(@items.grep({ (.<group> // '') eq $name })))
  }).join;

  '<nav>' ~ list-html(@ungrouped) ~ $sections ~ '</nav>'
}
