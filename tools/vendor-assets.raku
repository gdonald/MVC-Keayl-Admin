#!/usr/bin/env raku

use v6.d;
use lib $?FILE.IO.parent(2).add('lib').Str;
use JSON::Fast;
use MVC::Keayl::Assets;

# Fetch and verify the vendored frontend bundle from tools/vendored-assets.json.
#
#   raku tools/vendor-assets.raku           refetch every pinned file and refresh sha1 checksums
#   raku tools/vendor-assets.raku --check   verify the on-disk files match the pinned checksums (no network)
#
# To upgrade a component: edit its version in the manifest, run without --check,
# review the diff, then run the test suite. A fetch also regenerates the
# component table in NOTICES.md from the manifest.

sub license-path(%component --> Str) {
  %component<files>.first({ .<path>.ends-with('LICENSE') })<path>
}

sub render-notices-table(@components, Str $destination --> Str) {
  my @rows;

  @rows.push: ['Component', 'Version', 'License', 'Source', 'Bundled license'];

  for @components -> %component {
    @rows.push: [
      %component<title>, %component<version>, %component<license>,
      %component<source>, '`' ~ $destination ~ '/' ~ license-path(%component) ~ '`',
    ];
  }

  my @width = (^5).map(-> $col { @rows.map({ .[$col].chars }).max });

  my sub row(@cells) {
    '| ' ~ (^5).map({ @cells[$_] ~ ' ' x (@width[$_] - @cells[$_].chars) }).join(' | ') ~ ' |'
  }

  my @lines;

  @lines.push: row(@rows[0]);
  @lines.push: '| ' ~ (^5).map({ '-' x @width[$_] }).join(' | ') ~ ' |';
  @lines.push: row(@rows[$_]) for 1 ..^ @rows.elems;

  @lines.join("\n")
}

sub regenerate-notices(IO::Path $notices, @components, Str $destination --> Nil) {
  my $table = render-notices-table(@components, $destination);
  my $text  = $notices.slurp;

  $text .= subst(
    / '<!-- vendored-table:start' .*? '-->' \n .*? '<!-- vendored-table:end -->' /,
    "<!-- vendored-table:start -->\n"
      ~ $table
      ~ "\n<!-- vendored-table:end -->",
  );

  $notices.spurt($text);
}

sub MAIN(Bool :$check = False) {
  my $root          = $?FILE.IO.parent(2);
  my $manifest-path = $root.add('tools/vendored-assets.json');
  my %manifest      = from-json($manifest-path.slurp);
  my $dest-root     = $root.add(%manifest<destination>);

  my $failures = 0;

  for %manifest<components>.list -> %component {
    my $version = %component<version>;

    say "{%component<name>} {$version} ({%component<license>})";

    for %component<files>.list -> %file {
      my $path = $dest-root.add(%file<path>);
      my $url  = %file<url>.subst('{version}', $version, :g);

      if $check {
        unless $path.e {
          note "  MISSING  {%file<path>}";
          $failures++;
          next;
        }

        my $actual = digest-for($path.slurp(:bin));

        if $actual eq %file<sha1> {
          say "  ok       {%file<path>}";
        } else {
          note "  MISMATCH {%file<path>} (pinned {%file<sha1>}, on disk $actual)";
          $failures++;
        }
      } else {
        $path.parent.mkdir;

        my $proc = run 'curl', '-fsSL', '-o', $path.Str, $url, :out, :err;

        unless $proc.exitcode == 0 {
          note "  FAILED   $url";
          $failures++;
          next;
        }

        %file<sha1> = digest-for($path.slurp(:bin));

        say "  fetched  {%file<path>} ({$path.s} bytes)";
      }
    }
  }

  unless $check {
    $manifest-path.spurt(to-json(%manifest, :sorted-keys) ~ "\n");
    say "Refreshed {$manifest-path.relative($root)}";

    regenerate-notices($root.add('NOTICES.md'), %manifest<components>.list, %manifest<destination>);
    say "Regenerated NOTICES.md";
  }

  if $failures {
    note "$failures problem(s)";
    exit 1;
  }
}
