use v6.d;

unit module MVC::Keayl::Admin::Inflection;

sub underscore(Str:D $word --> Str) is export {
  $word.subst(/<?after .> <:Lu>/, { '_' ~ $/.Str }, :g).lc
}

sub dasherize(Str:D $word --> Str) is export {
  $word.subst('_', '-', :g)
}

sub humanize(Str:D $word --> Str) is export {
  my $text = $word.subst(/ '_id' $ /, '').subst(/<[_\-]>/, ' ', :g);

  $text.subst(/^ . /, *.uc)
}
