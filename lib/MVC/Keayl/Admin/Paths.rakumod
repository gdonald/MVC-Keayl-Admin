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

  for ($?DISTRIBUTION.meta<resources> // ()).list -> $name {
    my $dest = $target.add($name);
    next if $dest.e;
    $dest.parent.mkdir;
    $dest.spurt(%?RESOURCES{$name}.slurp(:bin), :bin);
  }

  $root = $target;
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
