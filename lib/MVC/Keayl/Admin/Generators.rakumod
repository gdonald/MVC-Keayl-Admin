use v6.d;
use MVC::Keayl::Admin::Inflection;

unit module MVC::Keayl::Admin::Generators;

sub fill(Str:D $template, %subs --> Str) {
  my $result = $template;
  $result = $result.subst(.key, .value, :g) for %subs.pairs;
  $result
}

sub emit-file(IO() $file, Str:D $content, :$out = $*OUT --> Bool) is export {
  if $file.e {
    $out.say("  exists  $file");
    return False;
  }

  $file.parent.mkdir;
  $file.spurt($content);

  $out.say("  create  $file");
  True
}

sub mount-engine(IO() $routes, :$out = $*OUT, :$err = $*ERR --> Bool) is export {
  unless $routes.e {
    $err.note("keayl-admin: no $routes to mount the admin into");
    return False;
  }

  my $text = $routes.slurp;

  if $text.contains('MVC::Keayl::Admin.endpoint') {
    $out.say("  exists  admin mount in $routes");
    return True;
  }

  my @lines = $text.lines;
  my $index = @lines.first(:k, * ~~ / 'routes' \s* '{' /);

  without $index {
    $err.note("keayl-admin: no routes block found in $routes");
    return False;
  }

  @lines.splice($index + 1, 0, q{  mount MVC::Keayl::Admin.endpoint, at => '/admin';});
  $routes.spurt(@lines.join("\n") ~ "\n");

  $out.say("  route   $routes");
  True
}

sub field-as(Str:D $type --> Str) {
  given $type.lc {
    when /text/                                  { 'text' }
    when /bool/                                  { 'boolean' }
    when /int | serial | numeric | float | decimal | real | double/ { 'number' }
    when /datetime | timestamp/                  { 'datetime' }
    when /date/                                  { 'date' }
    when /time/                                  { 'time' }
    default                                      { 'string' }
  }
}

sub filter-as(Str:D $type --> Str) {
  given $type.lc {
    when /bool/                                  { 'boolean' }
    when /int | serial | numeric | float | decimal | real | double/ { 'numeric' }
    when /datetime | timestamp | date/           { 'date' }
    default                                      { 'string' }
  }
}

sub editable(@columns) {
  @columns.grep({ .<name> ne 'id' && .<name> ne 'created_at' && .<name> ne 'updated_at' })
}

sub registration-source(Str:D $class, @columns --> Str) {
  my @editable = editable(@columns);

  my $columns = @columns.map({ "  column('" ~ .<name> ~ "');" }).join("\n");

  my $fields = @editable.map(-> %column {
    my $as = field-as(%column<type> // 'string');

    $as eq 'string'
      ?? "  field('" ~ %column<name> ~ "');"
      !! "  field('" ~ %column<name> ~ "', :as<" ~ $as ~ ">);"
  }).join("\n");

  my $filters = @editable.map({ "  filter('" ~ .<name> ~ "', :as<" ~ filter-as(.<type> // 'string') ~ ">);" }).join("\n");

  my $permit = @editable.map({ "'" ~ .<name> ~ "'" }).join(', ');

  fill(Q:to/RAKU/, %( '__CLASS__' => $class, '__COLUMNS__' => $columns, '__FIELDS__' => $fields, '__FILTERS__' => $filters, '__PERMIT__' => $permit ));
    use MVC::Keayl::Admin;
    use __CLASS__;

    MVC::Keayl::Admin.register(__CLASS__, {
    __COLUMNS__

    __FIELDS__

    __FILTERS__

      permit(__PERMIT__);
    });
    RAKU
}

sub registration-test(Str:D $class, Str:D $under --> Str) {
  fill(Q:to/RAKU/, %( '__CLASS__' => $class, '__UNDER__' => $under ));
    use v6.d;
    use Test;

    use MVC::Keayl::Admin;

    MVC::Keayl::Admin.reset;
    EVALFILE 'app/admin/__UNDER__.raku';

    ok MVC::Keayl::Admin.registry.all.first(*.model-name eq '__CLASS__').defined,
      '__CLASS__ is registered in the admin';

    MVC::Keayl::Admin.reset;

    done-testing;
    RAKU
}

sub registration-spec(Str:D $class, Str:D $under --> Str) {
  fill(Q:to/RAKU/, %( '__CLASS__' => $class, '__UNDER__' => $under ));
    use BDD::Behave;
    use MVC::Keayl::Admin;

    describe 'admin registration for __CLASS__', {
      before-each {
        MVC::Keayl::Admin.reset;
        EVALFILE 'app/admin/__UNDER__.raku';
      }

      it 'registers the resource', {
        expect(MVC::Keayl::Admin.registry.all.first(*.model-name eq '__CLASS__').defined).to.be-truthy;
      }
    }
    RAKU
}

sub generate-admin(Str:D $model-name, :$model, IO() :$root = '.'.IO, :$out = $*OUT, :$err = $*ERR --> Int) is export {
  my $class = $model-name;
  my $under = underscore($model-name);

  my $resolved = $model;
  $resolved = (try ::($class)) unless $resolved.^can('columns');

  unless $resolved.^can('columns') {
    $err.note("keayl-admin: cannot load model '$class'");
    return 1;
  }

  my @columns = $resolved.columns;

  emit-file($root.add("app/admin/$under.raku"),         registration-source($class, @columns), :$out);
  emit-file($root.add("t/admin/$under.rakutest"),       registration-test($class, $under),      :$out);
  emit-file($root.add("specs/admin/$under\-spec.raku"), registration-spec($class, $under),      :$out);

  0
}

sub generate-admin-install(IO() :$root = '.'.IO, :$out = $*OUT, :$err = $*ERR --> Int) is export {
  mount-engine($root.add('config/routes.raku'), :$out, :$err);

  emit-file($root.add('config/initializers/admin.raku'), Q:to/RAKU/, :$out);
    use MVC::Keayl::Admin;

    MVC::Keayl::Admin.configure(
      site-title => 'Admin',
      mount-path => '/admin',
    );
    RAKU

  emit-file($root.add('app/admin/dashboard.raku'), Q:to/RAKU/, :$out);
    use MVC::Keayl::Admin;

    MVC::Keayl::Admin.dashboard-block(title => 'Welcome', {
      '<p class="text-muted">Welcome to the admin.</p>'
    });
    RAKU

  emit-file($root.add('config/initializers/admin_authentication.raku'), Q:to/RAKU/, :$out);
    use MVC::Keayl::Admin;
    use MVC::Keayl::Admin::Authentication::Basic;

    # Replace this stub with your own authentication. The admin is unauthenticated
    # until a strategy is installed.
    #
    # MVC::Keayl::Admin.authenticate-with(
    #   MVC::Keayl::Admin::Authentication::Basic.new(
    #     username => 'admin',
    #     password => 'change-me',
    #   )
    # );
    RAKU

  emit-file($root.add('t/admin/install.rakutest'), Q:to/RAKU/, :$out);
    use v6.d;
    use Test;

    use MVC::Keayl::Admin;
    use MVC::Keayl::Routing;

    ok (routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; }).defined,
      'the admin engine mounts';

    done-testing;
    RAKU

  emit-file($root.add('specs/admin/install-spec.raku'), Q:to/RAKU/, :$out);
    use BDD::Behave;
    use MVC::Keayl::Admin;
    use MVC::Keayl::Routing;

    describe 'admin install', {
      it 'mounts the admin engine', {
        expect((routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; }).defined).to.be-truthy;
      }
    }
    RAKU

  0
}
