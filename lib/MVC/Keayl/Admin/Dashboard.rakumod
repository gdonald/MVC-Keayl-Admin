use v6.d;
use MVC::Keayl::Admin::Formatter;
use MVC::Keayl::Admin::Registry;

unit class MVC::Keayl::Admin::Dashboard;

my @blocks;

method add-block(::?CLASS:U: Str:D :$title, :&block --> Nil) {
  @blocks.push: %( :$title, :&block );
}

method reset(::?CLASS:U: --> Nil) {
  @blocks = ();
}

sub resource-card($resource, Str:D $mount --> Str) {
  my $url = html-escape($mount ~ '/' ~ $resource.slug);

  qq:to/HTML/.trim;
  <div class="col-sm-6 col-lg-4">
    <div class="card h-100">
      <div class="card-body">
        <h5 class="card-title">{html-escape($resource.plural-name)}</h5>
        <p class="display-6 mb-0">{$resource.model.all.count}</p>
        <a href="$url" class="stretched-link">View</a>
      </div>
    </div>
  </div>
  HTML
}

sub block-panel(%panel --> Str) {
  qq:to/HTML/.trim;
  <div class="col-12">
    <div class="card">
      <div class="card-header">{html-escape(%panel<title>)}</div>
      <div class="card-body">{%panel<block>()}</div>
    </div>
  </div>
  HTML
}

method render(::?CLASS:U: Str:D :$mount --> Str) {
  my $cards  = MVC::Keayl::Admin::Registry.current.all.map({ resource-card($_, $mount) }).join;
  my $panels = @blocks.map(&block-panel).join;

  $cards ~ $panels
}
