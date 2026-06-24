use v6.d;

unit class MVC::Keayl::Admin::CustomAction;

has Str $.name is required;
has Str $.scope is required;   # 'member' or 'collection'
has     &.block is required;
has Str $.confirm;
