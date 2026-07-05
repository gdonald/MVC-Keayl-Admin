use lib 'specs/lib';
use BDD::Behave;
use JSON::Fast;
use MVC::Keayl::Admin::Paths;

describe 'admin resource paths', {
  let(:meta, { from-json('META6.json'.IO.slurp) });

  it 'declares the bundled templates and assets as resources', {
    expect(meta<resources>.grep('views/resource/index.html.haml')
      && meta<resources>.grep('views/layouts/admin.html.haml')
      && meta<resources>.grep(*.starts-with('assets/')).elems > 0).to.be-truthy;
  }

  it 'resolves the views path to the bundled templates', {
    expect(views-path().IO.d && views-path().IO.add('resource/index.html.haml').e).to.be-truthy;
  }

  it 'resolves the assets path to the bundled vendored files', {
    expect(assets-path().IO.d && assets-path().IO.add('bootstrap/bootstrap.min.css').e).to.be-truthy;
  }

  context 'materializing resources into the cache directory', {
    let(:work, { my $dir = $*TMPDIR.add("mvc-keayl-admin-paths-spec-$*PID"); $dir.mkdir; $dir });

    after-each {
      .unlink for work.dir;
      work.rmdir if work.e;
    }

    it 'overwrites an existing resource rather than skipping it, so an edit is not masked by a prior install', {
      materialize-resources(work, [ 'admin.html.haml' => 'stale'.encode('utf-8') ]);
      materialize-resources(work, [ 'admin.html.haml' => 'fresh'.encode('utf-8') ]);
      expect(work.add('admin.html.haml').slurp).to.eq('fresh');
    }
  }
}
