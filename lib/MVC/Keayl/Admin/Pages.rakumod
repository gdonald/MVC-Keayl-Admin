use v6.d;
use MVC::Keayl::Admin::Page;

unit class MVC::Keayl::Admin::Pages;

my @pages;

method add(::?CLASS:U: MVC::Keayl::Admin::Page:D $page --> Nil) {
  @pages.push: $page;
}

method all(::?CLASS:U: --> List) {
  @pages.List
}

method by-slug(::?CLASS:U: Str:D $slug --> MVC::Keayl::Admin::Page) {
  @pages.first({ .slug eq $slug })
}

method reset(::?CLASS:U: --> Nil) {
  @pages = ();
}
