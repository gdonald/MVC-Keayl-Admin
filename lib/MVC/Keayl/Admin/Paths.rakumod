use v6.d;

unit module MVC::Keayl::Admin::Paths;

# Locate the bundled templates, assets, and helpers whether the dist runs from
# its source checkout or from an install. In the source tree they sit beside the
# lib directory; once installed they are content-addressed resources with no
# directory of their own, so they are materialized into a cached directory that
# the directory-based view renderer and static asset server can read.

sub source-root(--> IO::Path) {
  $?FILE.IO.parent(5).add('resources')
}

sub materialized-root(--> IO::Path) {
  state IO::Path $root;
  return $root with $root;

  my $source = source-root();
  return ($root = $source) if $source.add('views').d;

  my $version = (try $?DISTRIBUTION.meta<version>) // 'dev';
  my $target  = $*TMPDIR.add("mvc-keayl-admin-resources-$version");

  my @names = ($?DISTRIBUTION.meta<resources> // ()).list;
  materialize-resources($target, @names.map({ $_ => %?RESOURCES{$_}.slurp(:bin) }));

  $root = $target;
}

# Write each resource into the target directory, overwriting any existing copy.
# Refreshing every process start rather than skipping files that already exist
# matters because the version-keyed directory name does not change between
# reinstalls of the same release, so a skip would serve stale templates and
# assets after any resource edit. Each file is written to a per-process temp
# path and renamed so a concurrent worker never reads a half-written file.
sub materialize-resources(IO::Path:D $target, @entries) is export {
  for @entries -> $entry {
    my $dest = $target.add($entry.key);
    $dest.parent.mkdir;
    my $tmp = $dest.sibling($dest.basename ~ ".tmp-$*PID");
    $tmp.spurt($entry.value, :bin);
    $tmp.rename($dest);
  }
}

sub dist-root(--> IO::Path) is export {
  materialized-root()
}

sub views-path(--> Str) is export {
  dist-root.add('views').Str
}

sub assets-path(--> Str) is export {
  dist-root.add('assets').Str
}

sub helpers-path(--> Str) is export {
  dist-root.add('helpers').Str
}
