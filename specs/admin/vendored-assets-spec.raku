use BDD::Behave;
use JSON::Fast;
use MVC::Keayl::Assets;

my $root     = $?FILE.IO.parent(3);
my %manifest = from-json($root.add('tools/vendored-assets.json').slurp);
my $dest     = $root.add(%manifest<destination>);

my @manifest-paths = %manifest<components>.list.map({ .<files>.list.map(*.<path>) }).flat;

my @served = <
  bootstrap/bootstrap.min.css
  bootstrap/bootstrap.bundle.min.js
  bootstrap-icons/bootstrap-icons.min.css
  htmx/htmx.min.js
>;

describe 'MVC::Keayl::Admin vendored bundle', {
  for %manifest<components>.list -> %component {
    for %component<files>.list -> %file {
      it "ships {%file<path>} matching its pinned sha1", {
        my $path = $dest.add(%file<path>);
        expect($path.e && digest-for($path.slurp(:bin)) eq %file<sha1>).to.be-truthy;
      }
    }
  }

  for @served -> $logical {
    it "pins the served asset $logical in the manifest", {
      expect(@manifest-paths.grep($logical).elems > 0).to.be-truthy;
    }
  }
}

my @notices-lines = $root.add('NOTICES.md').lines;

describe 'MVC::Keayl::Admin notices file', {
  for %manifest<components>.list -> %component {
    it "records {%component<title>} {%component<version>} ({%component<license>})", {
      expect(@notices-lines.first({
        .contains(%component<title>) && .contains(%component<version>) && .contains(%component<license>)
      }).defined).to.be-truthy;
    }
  }
}
