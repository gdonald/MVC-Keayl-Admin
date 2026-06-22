use v6.d;

unit module MVC::Keayl::Admin::Url;

sub query-url(Str:D $base, *%params --> Str) is export {
  my @pairs = %params.grep({ .value.defined && ~.value ne '' }).sort(*.key).map({ .key ~ '=' ~ ~.value });

  @pairs ?? "$base?{@pairs.join('&')}" !! $base
}
