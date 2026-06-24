use v6.d;
use MVC::Keayl::I18n;
use MVC::Keayl::Routing::Resources;
use MVC::Keayl::Admin::Inflection;
use MVC::Keayl::Admin::I18n;
use MVC::Keayl::Admin::Column;
use MVC::Keayl::Admin::Attribute;
use MVC::Keayl::Admin::Field;
use MVC::Keayl::Admin::Filter;
use MVC::Keayl::Admin::Scope;
use MVC::Keayl::Admin::MenuEntry;
use MVC::Keayl::Admin::Nested;
use MVC::Keayl::Admin::BatchAction;
use MVC::Keayl::Admin::CustomAction;
use MVC::Keayl::Admin::Panel;
use MVC::Keayl::Admin::ActionItem;

unit class MVC::Keayl::Admin::Resource;

has Mu  $.model is required;
has Str $.slug-override;
has Str $.singular-override;
has Str $.plural-override;
has Int $.per-page-override;
has     $.scope-counts-override;
has     $.filters-override;
has     $.batch-override;

has MVC::Keayl::Admin::Column    @.columns;
has MVC::Keayl::Admin::Attribute @.attributes;
has MVC::Keayl::Admin::Field     @.fields;
has MVC::Keayl::Admin::Filter    @.filters;
has MVC::Keayl::Admin::Scope     @.scopes;
has Str                          @.permitted;
has Str                             $.index-as = 'table';
has                                 &.index-block;
has MVC::Keayl::Admin::Nested       @.nested-attributes;
has MVC::Keayl::Admin::BatchAction  @.batch-actions;
has MVC::Keayl::Admin::CustomAction @.member-actions;
has MVC::Keayl::Admin::CustomAction @.collection-actions;
has MVC::Keayl::Admin::Panel        @.sidebars;
has MVC::Keayl::Admin::Panel        @.panels;
has MVC::Keayl::Admin::Panel        @.tabs;
has MVC::Keayl::Admin::ActionItem   @.action-items;
has MVC::Keayl::Admin::MenuEntry    $.menu-entry is rw;
has Str                             @.enabled-actions = <index show new edit destroy>;
has Str                             $.sort-column;
has Str                             $.sort-dir = 'asc';

constant FIELD-TYPES  = set <string text select boolean date time datetime number password hidden file>;
constant FILTER-TYPES = set <string numeric boolean date date-range select>;
constant INDEX-TYPES  = set <table grid blog>;

sub default-i18n(--> MVC::Keayl::I18n) {
  MVC::Keayl::Admin::I18n.backend
}

method model-name(--> Str) {
  $!model.^name.split('::')[*-1]
}

method slug(--> Str) {
  $!slug-override // dasherize(pluralize(underscore(self.model-name)))
}

method per-page(--> Int) {
  $!per-page-override // 25
}

method scope-counts(--> Bool) {
  $!scope-counts-override // True
}

method filters-enabled(--> Bool) {
  $!filters-override // True
}

method batch-enabled(--> Bool) {
  $!batch-override // True
}

method allows-action(Str:D $name --> Bool) {
  my $key = $name eq 'create' ?? 'new' !! $name eq 'update' ?? 'edit' !! $name;

  return True unless $key (elem) <index show new edit destroy>;

  so $key (elem) @!enabled-actions
}

method default-scope {
  @!scopes.first(*.default) // @!scopes.first
}

method singular-name(MVC::Keayl::I18n :$i18n = default-i18n() --> Str) {
  return $!singular-override with $!singular-override;

  my $key = underscore(self.model-name);

  $i18n.translate("activerecord.models.$key", default => humanize($key))
}

method plural-name(MVC::Keayl::I18n :$i18n = default-i18n() --> Str) {
  return $!plural-override with $!plural-override;

  pluralize(self.singular-name(:$i18n))
}

sub reject-unknown(%extra, Str:D $declaration) {
  die "unknown option '{%extra.keys.sort.join(q{, })}' in $declaration declaration" if %extra;
}

method index(&block?, Str:D :$as = 'table' --> ::?CLASS) {
  reject-unknown(%_, 'index');

  die "unknown index type '$as'" unless INDEX-TYPES{$as};

  $!index-as    = $as;
  &!index-block = &block;

  self
}

method actions(*@only, :$except --> ::?CLASS) {
  reject-unknown(%_, 'actions');

  if @only.elems {
    @!enabled-actions = @only>>.Str;
  } elsif $except.defined {
    my @drop = $except.list>>.Str;
    @!enabled-actions = <index show new edit destroy>.grep({ $_ !(elem) @drop });
  }

  self
}

method sort-order(Str:D $column, Str :$dir = 'asc' --> ::?CLASS) {
  reject-unknown(%_, 'sort-order');

  $!sort-column = $column;
  $!sort-dir    = $dir eq 'desc' ?? 'desc' !! 'asc';

  self
}

method action-item(Str:D $label, &block, :$only, :$except, Str :$if-can --> ::?CLASS) {
  reject-unknown(%_, "action-item '$label'");

  my @only   = $only.defined   ?? $only.list>>.Str   !! ();
  my @except = $except.defined ?? $except.list>>.Str !! ();

  @!action-items.push: MVC::Keayl::Admin::ActionItem.new(:$label, :&block, :@only, :@except, :$if-can);

  self
}

method visible-action-items(Str:D $action, $abilities --> List) {
  @!action-items
    .grep({ .shows-on($action) })
    .grep({ !.if-can.defined || !$abilities.defined || $abilities.can(.if-can) })
    .List
}

method column(Str:D $name, Bool :$sortable = False, :&display, Str :$format --> ::?CLASS) {
  reject-unknown(%_, "column '$name'");

  @!columns.push: MVC::Keayl::Admin::Column.new(:$name, :$sortable, :&display, :$format);

  self
}

method attribute(Str:D $name, :&display, Str :$format --> ::?CLASS) {
  reject-unknown(%_, "attribute '$name'");

  @!attributes.push: MVC::Keayl::Admin::Attribute.new(:$name, :&display, :$format);

  self
}

method field(Str:D $name, Str :$as = 'string', :&collection, Str :$hint, Str :$placeholder, Bool :$multiple = False --> ::?CLASS) {
  reject-unknown(%_, "field '$name'");

  die "unknown field type '$as' for field '$name'" unless FIELD-TYPES{$as};

  @!fields.push: MVC::Keayl::Admin::Field.new(:$name, :$as, :&collection, :$hint, :$placeholder, :$multiple);

  self
}

method filter(Str:D $name, Str :$as = 'string', Str :$predicate, :&collection --> ::?CLASS) {
  reject-unknown(%_, "filter '$name'");

  die "unknown filter type '$as' for filter '$name'" unless FILTER-TYPES{$as};

  die "filter '$name' is a select without a collection or a search predicate"
    if $as eq 'select' && !&collection.defined && !$predicate.defined;

  @!filters.push: MVC::Keayl::Admin::Filter.new(:$name, :$as, :$predicate, :&collection);

  self
}

method scope(Str:D $name, &block?, Bool :$default = False --> ::?CLASS) {
  reject-unknown(%_, "scope '$name'");

  @!scopes.push: MVC::Keayl::Admin::Scope.new(:$name, :&block, :$default);

  self
}

method permit(*@names --> ::?CLASS) {
  reject-unknown(%_, 'permit');

  @!permitted.append: @names;

  self
}

method nested(Str:D $name, &block, Bool :$multiple = False --> ::?CLASS) {
  my $nested = MVC::Keayl::Admin::Nested.new(:$name, :$multiple);

  {
    my $*KEAYL-ADMIN-RESOURCE = $nested;
    block();
  }

  @!nested-attributes.push: $nested;

  self
}

method batch-action(Str:D $name, &block --> ::?CLASS) {
  reject-unknown(%_, "batch-action '$name'");

  @!batch-actions.push: MVC::Keayl::Admin::BatchAction.new(:$name, :&block);

  self
}

method member-action(Str:D $name, &block, Str :$confirm --> ::?CLASS) {
  reject-unknown(%_, "member-action '$name'");

  @!member-actions.push: MVC::Keayl::Admin::CustomAction.new(:$name, scope => 'member', :&block, :$confirm);

  self
}

method collection-action(Str:D $name, &block, Str :$confirm --> ::?CLASS) {
  reject-unknown(%_, "collection-action '$name'");

  @!collection-actions.push: MVC::Keayl::Admin::CustomAction.new(:$name, scope => 'collection', :&block, :$confirm);

  self
}

method sidebar(Str:D $title, &block, Str :$on = 'both', Int :$priority = 0, Str :$if-can --> ::?CLASS) {
  reject-unknown(%_, "sidebar '$title'");

  die "unknown sidebar placement '$on'" unless $on eq any('index', 'show', 'both');

  @!sidebars.push: MVC::Keayl::Admin::Panel.new(:$title, :&block, :$on, :$priority, :$if-can);

  self
}

method panel(Str:D $title, &block, Int :$priority = 0, Str :$if-can --> ::?CLASS) {
  reject-unknown(%_, "panel '$title'");

  @!panels.push: MVC::Keayl::Admin::Panel.new(:$title, :&block, on => 'show', :$priority, :$if-can);

  self
}

method tab(Str:D $title, &block, Int :$priority = 0, Str :$if-can --> ::?CLASS) {
  reject-unknown(%_, "tab '$title'");

  @!tabs.push: MVC::Keayl::Admin::Panel.new(:$title, :&block, on => 'show', :$priority, :$if-can);

  self
}

method menu(Str :$group, Str :$label, Int :$priority = 0, Str :$icon, Bool :$hide = False --> ::?CLASS) {
  reject-unknown(%_, 'menu');

  $!menu-entry = MVC::Keayl::Admin::MenuEntry.new(:$group, :$label, :$priority, :$icon, :$hide);

  self
}

method parse(&block --> ::?CLASS) {
  my $*KEAYL-ADMIN-RESOURCE = self;

  block();

  self
}
