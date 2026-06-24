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
    expect($code == 0 && $source.contains("column('title')") && $source.contains('permit(')).to.be-truthy;
  }

  it 'generates parallel t/ and specs coverage', {
    generate-admin('Post', model => Post, root => root, out => GeneratorSink.new, err => GeneratorSink.new);
    expect(root.add('t/admin/post.rakutest').e && root.add('specs/admin/post-spec.raku').e).to.be-truthy;
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
