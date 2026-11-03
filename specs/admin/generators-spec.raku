use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Authentication;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Generators;
use MVC::Keayl::Admin::TestSupport;

class GeneratorSink {
  has Str $.text is rw = '';
  method print(*@args) { $!text ~= @args.join;        Nil }
  method say(*@args)   { $!text ~= @args.join ~ "\n"; Nil }
  method note(*@args)  { $!text ~= @args.join ~ "\n"; Nil }
}

sub scratch(Str:D $label --> IO::Path) {
  state $count = 0;

  my $dir = $*TMPDIR.add("keayl-admin-genspec-$label-$*PID-{$count++}");
  $dir.mkdir;
  $dir
}

sub base-routes(IO() $root) {
  $root.add('config').mkdir;
  $root.add('config/routes.raku').spurt("use MVC::Keayl::Routing;\n\nroutes \{\n  root to => 'home#index';\n\}\n");
}

sub base-application(IO() $root) {
  $root.add('config').mkdir;
  $root.add('config/application.raku').spurt("use MVC::Keayl::Application;\n\nmy \$app = MVC::Keayl::Application.new;\n\n\$app;\n");
}

sub installed(Str:D $label --> IO::Path) {
  my $root = scratch($label);
  base-routes($root);
  base-application($root);

  generate-admin-install(root => $root, out => GeneratorSink.new, err => GeneratorSink.new);
  $root
}

sub registrations-source(IO() $root --> Str) {
  $root.add('app/admin/AdminRegistrations.rakumod').slurp
}

sub widget-model(IO() $root) {
  $root.add('app/models').mkdir;
  $root.add('app/models/Widget.rakumod').spurt(q:to/RAKU/);
  unit class Widget;

  method columns {
    (
      { name => 'id',    type => 'integer' },
      { name => 'name',  type => 'string'  },
      { name => 'notes', type => 'text'    },
    )
  }
  RAKU
}

sub uncommented-authentication(Str:D $module --> Str) {
  my @lines = $module.lines;
  my $from  = @lines.first(:k, *.contains('# MVC::Keayl::Admin.authenticate-with('));
  my $to    = @lines.first(:k, *.contains('# );'));

  @lines[$from .. $to].map(*.subst(/^ \s* '# '/, '')).join("\n")
}

setup-admin-db;

describe 'admin model generator', {
  let(:out-sink, { GeneratorSink.new });
  let(:err-sink, { GeneratorSink.new });

  context 'when the model is passed in', {
    let(:root, { installed('model') });

    before-each {
      generate-admin('Post', model => Post, root => root, out => out-sink, err => err-sink);
    }

    it 'loads the model in the registrations module', {
      expect(registrations-source(root).contains("use Post;\n")).to.be-truthy;
    }

    it 'registers the model inside register-admin', {
      expect(registrations-source(root) ~~ /'MVC::Keayl::Admin.register(Post' .* '}' \s* $/).to.be-truthy;
    }

    it 'emits a column from the schema', {
      expect(registrations-source(root).contains("column('title')")).to.be-truthy;
    }

    it 'emits a text field for a text column', {
      expect(registrations-source(root).contains("field('body', :as<text>)")).to.be-truthy;
    }

    it 'emits the permitted attributes', {
      expect(registrations-source(root).contains('permit(')).to.be-truthy;
    }

    it 'leaves the primary key out of the editable fields', {
      expect(registrations-source(root).contains("field('id')")).to.be-falsy;
    }

    it 'reports the module update', {
      expect(out-sink.text.contains('update')).to.be-truthy;
    }

    it 'generates parallel t/ and specs coverage', {
      expect(root.add('t/admin/post.rakutest').e && root.add('specs/admin/post-spec.raku').e).to.be-truthy;
    }

    it 'puts the model directories on the search path of the generated test and spec', {
      my $test-source = root.add('t/admin/post.rakutest').slurp;
      my $spec-source = root.add('specs/admin/post-spec.raku').slurp;

      expect($test-source.contains("use lib 'app/models'") && $test-source.contains("use lib 'app/models/concerns'")
        && $spec-source.contains("use lib 'app/models'") && $spec-source.contains("use lib 'app/models/concerns'")).to.be-truthy;
    }

    it 'runs the registrations in the generated test and spec', {
      expect(root.add('t/admin/post.rakutest').slurp.contains('register-admin;')
        && root.add('specs/admin/post-spec.raku').slurp.contains('register-admin;')).to.be-truthy;
    }
  }

  context 'when the same model is generated twice', {
    let(:root, { installed('twice') });

    before-each {
      generate-admin('Post', model => Post, root => root, out => out-sink, err => err-sink);
      generate-admin('Post', model => Post, root => root, out => out-sink, err => err-sink);
    }

    it 'adds one registration', {
      expect(registrations-source(root).comb('register(Post').elems).to.be(1);
    }

    it 'reports the existing registration', {
      expect(out-sink.text.contains('exists')).to.be-truthy;
    }
  }

  context 'when the model loads from the conventional app/models directory', {
    let(:root, { installed('load-model') });

    before-each {
      widget-model(root);
      generate-admin('Widget', root => root, out => out-sink, err => err-sink);
    }

    it 'emits a column from the disk-loaded schema', {
      expect(registrations-source(root).contains("column('name')")).to.be-truthy;
    }

    context 'and the application is loaded', {
      before-each {
        MVC::Keayl::Admin.reset;
        indir root, { EVALFILE 'config/application.raku' };
      }

      after-each {
        MVC::Keayl::Admin.reset;
      }

      it 'registers the generated resource', {
        expect(MVC::Keayl::Admin.registry.all.first(*.model-name eq 'Widget').defined).to.be-truthy;
      }

      it 'applies the generated configuration', {
        expect(MVC::Keayl::Admin::Config.current.site-title).to.be('Admin');
      }
    }
  }

  context 'when the model cannot be loaded', {
    let(:root, { installed('unloadable') });
    let(:exit-code, { generate-admin('NoSuchModel12345', root => root, out => out-sink, err => err-sink) });

    it 'exits non-zero', {
      expect(exit-code).to.be(1);
    }

    it 'reports the model on the error stream', {
      exit-code;
      expect(err-sink.text.contains('cannot load model')).to.be-truthy;
    }
  }

  context 'before admin:install has run', {
    let(:root, { scratch('uninstalled') });
    let(:exit-code, { generate-admin('Post', model => Post, root => root, out => out-sink, err => err-sink) });

    it 'exits non-zero', {
      expect(exit-code).to.be(1);
    }

    it 'reports that install is needed', {
      exit-code;
      expect(err-sink.text.contains('generate admin:install first')).to.be-truthy;
    }

    it 'generates no test', {
      exit-code;
      expect(root.add('t/admin/post.rakutest').e).to.be-falsy;
    }
  }
}

describe 'admin install generator', {
  let(:out-sink, { GeneratorSink.new });
  let(:err-sink, { GeneratorSink.new });

  context 'in an application with routes and an application file', {
    let(:root, { my $dir = scratch('install'); base-routes($dir); base-application($dir); $dir });
    let(:module-source, { registrations-source(root) });
    let(:application-source, { root.add('config/application.raku').slurp });

    before-each {
      generate-admin-install(root => root, out => out-sink, err => err-sink);
    }

    it 'mounts the engine in the routes', {
      expect(root.add('config/routes.raku').slurp.contains('mount MVC::Keayl::Admin.endpoint')).to.be-truthy;
    }

    it 'writes a registrations module exporting register-admin', {
      expect(module-source.contains('sub register-admin is export')).to.be-truthy;
    }

    it 'configures the admin in register-admin', {
      expect(module-source.contains('MVC::Keayl::Admin.configure(')).to.be-truthy;
    }

    it 'adds a dashboard block in register-admin', {
      expect(module-source.contains('dashboard-block')).to.be-truthy;
    }

    it 'runs register-admin in the application before building the app', {
      expect(application-source() ~~ /'use AdminRegistrations;' \s+ 'register-admin;' \s+ 'my $app'/).to.be-truthy;
    }

    it 'puts app/admin on the search path of the application', {
      expect(application-source.contains("use lib 'app/admin'")).to.be-truthy;
    }

    it 'writes no initializer files', {
      expect(root.add('config/initializers').e).to.be-falsy;
    }

    it 'generates parallel t/ and specs coverage', {
      expect(root.add('t/admin/install.rakutest').e && root.add('specs/admin/install-spec.raku').e).to.be-truthy;
    }

    context 'when the authentication stub is uncommented and run', {
      before-each {
        MVC::Keayl::Admin.reset;
        EVAL 'use MVC::Keayl::Admin; use MVC::Keayl::Admin::Authentication::Basic; ' ~ uncommented-authentication(module-source);
      }

      after-each {
        MVC::Keayl::Admin.reset;
      }

      it 'installs a Basic strategy with the stub name', {
        expect(MVC::Keayl::Admin::Authentication.strategy.name).to.be('admin');
      }
    }
  }

  context 'run twice', {
    let(:root, { my $dir = scratch('idempotent'); base-routes($dir); base-application($dir); $dir });

    before-each {
      generate-admin-install(root => root, out => out-sink, err => err-sink);
      generate-admin-install(root => root, out => out-sink, err => err-sink);
    }

    it 'does not duplicate the mount', {
      expect(root.add('config/routes.raku').slurp.comb('mount MVC::Keayl::Admin.endpoint').elems).to.be(1);
    }

    it 'does not duplicate the application wiring', {
      expect(root.add('config/application.raku').slurp.comb('register-admin;').elems).to.be(1);
    }
  }

  context 'without an application file', {
    let(:root, { my $dir = scratch('no-application'); base-routes($dir); $dir });

    it 'reports the missing application file', {
      generate-admin-install(root => root, out => out-sink, err => err-sink);
      expect(err-sink.text.contains('config/application.raku')).to.be-truthy;
    }
  }

  context 'with an application file that has no my $app line', {
    let(:root, {
      my $dir = scratch('no-app-line');
      base-routes($dir);
      $dir.add('config/application.raku').spurt("use MVC::Keayl::Application;\n");
      $dir
    });

    it 'reports the missing app line', {
      generate-admin-install(root => root, out => out-sink, err => err-sink);
      expect(err-sink.text.contains(q{no 'my $app' line})).to.be-truthy;
    }
  }
}
