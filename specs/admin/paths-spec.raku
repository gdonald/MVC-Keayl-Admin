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
}
