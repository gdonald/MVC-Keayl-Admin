use v6.d;

unit role MVC::Keayl::Admin::DSL;

has @.declarations;

method declare(Str:D $kind, *@args, *%opts) {
  @!declarations.push: %( :$kind, :@args, :%opts );

  self
}

method declarations-of(Str:D $kind --> List) {
  @!declarations.grep(*.<kind> eq $kind).List
}
