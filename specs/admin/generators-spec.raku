use BDD::Behave;
use MVC::Keayl::Admin::Generators;
use MVC::Keayl::Admin::TestSupport;

class GeneratorSink {
  has Str $.text is rw = '';
  method print(*@args) { $!text ~= @args.join;        Nil }
  method say(*@args)   { $!text ~= @args.join ~ "\n"; Nil }
  method note(*@args)  { $!text ~= @args.join ~ "\n"; Nil }
}

sub scratch(Str:D $label --> IO::Path) {
  my $dir = $*TMPDIR.add("keayl-admin-genspec-$label-$*PID");
  $dir.mkdir;
  $dir
}

sub base-routes(IO() $root) {
  $root.add('config').mkdir;
  $root.add('config/routes.raku').spurt("use MVC::Keayl::Routing;\n\nroutes \{\n  root to => 'home#index';\n\}\n");
}

setup-admin-db;

describe 'admin model generator', {
  let(:root, { scratch('model') });

  it 'introspects the schema into an explicit registration', {
    my $code = generate-admin('Post', model => Post, root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    my $source = root.add('app/admin/post.raku').slurp;
    expect($code == 0 && $source.contains("column('title')") && $source.contains('permit(')
      && $source.contains('use MVC::Keayl::Admin::DSL')).to.be-truthy;
  }

  it 'generates parallel t/ and specs coverage', {
    generate-admin('Post', model => Post, root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    expect(root.add('t/admin/post.rakutest').e && root.add('specs/admin/post-spec.raku').e).to.be-truthy;
  }

  it 'puts the model directories on the search path of the generated test and spec', {
    generate-admin('Post', model => Post, root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    my $test-source = root.add('t/admin/post.rakutest').slurp;
    my $spec-source = root.add('specs/admin/post-spec.raku').slurp;
    expect($test-source.contains("use lib 'app/models'") && $test-source.contains("use lib 'app/models/concerns'")
      && $spec-source.contains("use lib 'app/models'") && $spec-source.contains("use lib 'app/models/concerns'")).to.be-truthy;
  }

  it 'loads a model from the conventional app/models directory when none is passed', {
    root.add('app/models').mkdir;
    root.add('app/models/Widget.rakumod').spurt(q:to/RAKU/);
    unit class Widget;

    method columns {
      (
        { name => 'id',    type => 'integer' },
        { name => 'name',  type => 'string'  },
        { name => 'notes', type => 'text'    },
      )
    }
    RAKU

    my $code = generate-admin('Widget', root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    my $source = root.add('app/admin/widget.raku').slurp;
    expect($code == 0 && $source.contains("column('name')") && $source.contains("field('notes', :as<text>)")).to.be-truthy;
  }

  it 'reports a clean error for a model it cannot load', {
    my $err = GeneratorSink.new;
    my $code = generate-admin('NoSuchModel12345', root => root, out => GeneratorSink.new, err => $err);
    expect($code == 1 && $err.text.contains('cannot load model')).to.be-truthy;
  }
}

describe 'admin install generator', {
  let(:root, { my $dir = scratch('install'); base-routes($dir); $dir });

  it 'mounts the engine and writes the scaffolding', {
    my $code = generate-admin-install(root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    expect(
      $code == 0
      && root.add('config/routes.raku').slurp.contains('mount MVC::Keayl::Admin.endpoint')
      && root.add('config/initializers/admin.raku').e
      && root.add('app/admin/dashboard.raku').e
      && root.add('config/initializers/admin_authentication.raku').e
    ).to.be-truthy;
  }

  it 'does not duplicate the mount on a repeated install', {
    generate-admin-install(root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    generate-admin-install(root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    expect(root.add('config/routes.raku').slurp.comb('mount MVC::Keayl::Admin.endpoint').elems).to.be(1);
  }
}
