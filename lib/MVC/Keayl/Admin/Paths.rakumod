use v6.d;

unit module MVC::Keayl::Admin::Paths;

sub dist-root(--> IO::Path) is export {
  $?FILE.IO.parent(5)
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
