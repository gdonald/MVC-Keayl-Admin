use v6.d;
use MVC::Keayl::Admin::Inflection;

unit module MVC::Keayl::Admin::Generators;

constant REGISTRATIONS = 'app/admin/AdminRegistrations.rakumod';

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

  my $columns = @columns.map({ "    column('" ~ .<name> ~ "');" }).join("\n");

  my $fields = @editable.map(-> %column {
    my $as = field-as(%column<type> // 'string');

    $as eq 'string'
      ?? "    field('" ~ %column<name> ~ "');"
      !! "    field('" ~ %column<name> ~ "', :as<" ~ $as ~ ">);"
  }).join("\n");

  my $filters = @editable.map({ "    filter('" ~ .<name> ~ "', :as<" ~ filter-as(.<type> // 'string') ~ ">);" }).join("\n");

  my $permit = @editable.map({ "'" ~ .<name> ~ "'" }).join(', ');

  fill(Q:to/RAKU/, %( '__CLASS__' => $class, '__COLUMNS__' => $columns, '__FIELDS__' => $fields, '__FILTERS__' => $filters, '__PERMIT__' => $permit ));
      MVC::Keayl::Admin.register(__CLASS__, {
    __COLUMNS__

    __FIELDS__

    __FILTERS__

        permit(__PERMIT__);
      });
    RAKU
}

sub registration-test(Str:D $class --> Str) {
  fill(Q:to/RAKU/, %( '__CLASS__' => $class ));
    use v6.d;
    use lib 'app/admin';
    use lib 'app/models';
    use lib 'app/models/concerns';
    use Test;

    use MVC::Keayl::Admin;
    use AdminRegistrations;

    MVC::Keayl::Admin.reset;
    register-admin;

    ok MVC::Keayl::Admin.registry.all.first(*.model-name eq '__CLASS__').defined,
      '__CLASS__ is registered in the admin';

    MVC::Keayl::Admin.reset;

    done-testing;
    RAKU
}

sub registration-spec(Str:D $class --> Str) {
  fill(Q:to/RAKU/, %( '__CLASS__' => $class ));
    use lib 'app/admin';
    use lib 'app/models';
    use lib 'app/models/concerns';
    use BDD::Behave;
    use MVC::Keayl::Admin;
    use AdminRegistrations;

    describe 'admin registration for __CLASS__', {
      before-each {
        MVC::Keayl::Admin.reset;
        register-admin;
      }

      it 'registers the resource', {
        expect(MVC::Keayl::Admin.registry.all.first(*.model-name eq '__CLASS__').defined).to.be-truthy;
      }
    }
    RAKU
}

sub add-registration(IO() $module, Str:D $class, Str:D $registration, :$out = $*OUT, :$err = $*ERR --> Bool) {
  unless $module.e {
    $err.say("keayl-admin: no $module, run keayl-admin generate admin:install first");
    return False;
  }

  my @lines = $module.slurp.lines;

  if @lines.first(* eq "use $class;").defined {
    $out.say("  exists  $class registration in $module");
    return True;
  }

  my $last-use = @lines.first(:end, :k, *.starts-with('use '));
  @lines.splice($last-use + 1, 0, "use $class;");

  my $sub-end = @lines.first(:end, :k, * eq '}');
  @lines.splice($sub-end, 0, '', |$registration.lines);

  $module.spurt(@lines.join("\n") ~ "\n");

  $out.say("  update  $module");
  True
}

sub wire-application(IO() $application, :$out = $*OUT, :$err = $*ERR --> Bool) is export {
  unless $application.e {
    $err.note("keayl-admin: no $application to load the admin registrations from");
    return False;
  }

  my $text = $application.slurp;

  if $text.contains('register-admin;') {
    $out.say("  exists  admin registrations in $application");
    return True;
  }

  my @lines = $text.lines;
  my $index = @lines.first(:k, *.starts-with('my $app'));

  without $index {
    $err.note("keayl-admin: no 'my \$app' line found in $application");
    return False;
  }

  @lines.splice($index, 0,
    q{use lib 'app/admin', 'app/models', 'app/models/concerns';},
    'use AdminRegistrations;',
    '',
    'register-admin;',
    '');
  $application.spurt(@lines.join("\n") ~ "\n");

  $out.say("  update  $application");
  True
}

# Put the conventional model directories on the repository chain so a model
# named on the command line (and its dependencies) can be loaded and
# introspected. `use lib` would bind at the bin's compile time; this resolves
# against the directory the generator is actually run from.
sub add-model-paths(IO() $root) {
  for <app/models app/models/concerns> -> $relative {
    my $dir = $root.add($relative);
    next unless $dir.d;
    CompUnit::RepositoryRegistry.use-repository(
      CompUnit::RepositoryRegistry.repository-for-spec($dir.absolute));
  }
}

sub generate-admin(Str:D $model-name, :$model, IO() :$root = '.'.IO, :$out = $*OUT, :$err = $*ERR --> Int) is export {
  my $class = $model-name;
  my $under = underscore($model-name);

  my $resolved = $model;
  unless $resolved.^can('columns') {
    add-model-paths($root);
    try require ::($class);
    $resolved = (try ::($class));
  }

  unless $resolved.^can('columns') {
    $err.say("keayl-admin: cannot load model '$class'");
    return 1;
  }

  my @columns = $resolved.columns;

  return 1 unless add-registration($root.add(REGISTRATIONS), $class, registration-source($class, @columns), :$out, :$err);

  emit-file($root.add("t/admin/$under.rakutest"),       registration-test($class), :$out);
  emit-file($root.add("specs/admin/$under\-spec.raku"), registration-spec($class), :$out);

  0
}

sub generate-admin-install(IO() :$root = '.'.IO, :$out = $*OUT, :$err = $*ERR --> Int) is export {
  mount-engine($root.add('config/routes.raku'), :$out, :$err);

  wire-application($root.add('config/application.raku'), :$out, :$err);

  emit-file($root.add(REGISTRATIONS), Q:to/RAKU/, :$out);
    use MVC::Keayl::Admin;
    use MVC::Keayl::Admin::DSL;
    use MVC::Keayl::Admin::Authentication::Basic;

    unit module AdminRegistrations;

    sub register-admin is export {
      MVC::Keayl::Admin.configure(
        site-title => 'Admin',
        mount-path => '/admin',
      );

      MVC::Keayl::Admin.dashboard-block(title => 'Welcome', {
        '<p class="text-muted">Welcome to the admin.</p>'
      });

      # Replace this stub with your own authentication. The admin is unauthenticated
      # until a strategy is installed.
      #
      # MVC::Keayl::Admin.authenticate-with(
      #   MVC::Keayl::Admin::Authentication::Basic.new(
      #     name     => 'admin',
      #     password => 'change-me',
      #   )
      # );
    }
    RAKU

  emit-file($root.add('t/admin/install.rakutest'), Q:to/RAKU/, :$out);
    use v6.d;
    use lib 'app/admin';
    use lib 'app/models';
    use lib 'app/models/concerns';
    use Test;

    use MVC::Keayl::Admin;
    use MVC::Keayl::Admin::Config;
    use MVC::Keayl::Routing;
    use AdminRegistrations;

    ok (routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; }).defined,
      'the admin engine mounts';

    MVC::Keayl::Admin.reset;
    register-admin;

    is MVC::Keayl::Admin::Config.current.site-title, 'Admin',
      'register-admin configures the admin';

    MVC::Keayl::Admin.reset;

    done-testing;
    RAKU

  emit-file($root.add('specs/admin/install-spec.raku'), Q:to/RAKU/, :$out);
    use lib 'app/admin';
    use lib 'app/models';
    use lib 'app/models/concerns';
    use BDD::Behave;
    use MVC::Keayl::Admin;
    use MVC::Keayl::Admin::Config;
    use MVC::Keayl::Routing;
    use AdminRegistrations;

    describe 'admin install', {
      it 'mounts the admin engine', {
        expect((routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; }).defined).to.be-truthy;
      }

      context 'after register-admin runs', {
        before-each {
          MVC::Keayl::Admin.reset;
          register-admin;
        }

        it 'configures the admin site title', {
          expect(MVC::Keayl::Admin::Config.current.site-title).to.be('Admin');
        }
      }
    }
    RAKU

  0
}
