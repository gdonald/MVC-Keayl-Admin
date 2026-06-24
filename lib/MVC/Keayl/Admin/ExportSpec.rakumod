use v6.d;
use MVC::Keayl::Admin::Column;

unit class MVC::Keayl::Admin::ExportSpec;

has MVC::Keayl::Admin::Column @.columns;

method column(Str:D $name, :&display, Str :$format --> ::?CLASS) {
  @!columns.push: MVC::Keayl::Admin::Column.new(:$name, :&display, :$format);

  self
}
