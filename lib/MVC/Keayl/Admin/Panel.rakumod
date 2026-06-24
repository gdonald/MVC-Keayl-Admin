use v6.d;

unit class MVC::Keayl::Admin::Panel;

has Str $.title is required;
has     &.block is required;
has Str $.on = 'both';   # 'index', 'show', or 'both'
has Int $.priority = 0;
has Str $.if-can;
