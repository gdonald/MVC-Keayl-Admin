use v6.d;

unit class MVC::Keayl::Admin::BatchAction;

has Str $.name is required;
has     &.block is required;
