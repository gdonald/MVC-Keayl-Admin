use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::DSL;

class FilterDoc { }

sub register-doc {
  MVC::Keayl::Admin.register(FilterDoc, {
    filter('title');
    filter('views', :as<numeric>, :predicate<gteq>);
    filter('author-id', :as<select>, :collection(-> { (1 => 'Ann',) }));
    filter('tag', :as<select>, :predicate<cont>);
  })
}

describe 'MVC::Keayl::Admin filter declarations', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:resource, { register-doc });

  it 'defaults a string filter to cont', {
    expect(resource.filters[0].effective-predicate).to.be('cont');
  }

  it 'keeps an explicit predicate', {
    expect(resource.filters[1].effective-predicate).to.be('gteq');
  }

  it 'keeps a select collection', {
    expect(resource.filters[2].has-collection).to.be-truthy;
  }

  it 'keeps a select search predicate', {
    expect(resource.filters[3].effective-predicate).to.be('cont');
  }
}

describe 'MVC::Keayl::Admin filter validation', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'rejects a select without a collection or a search predicate', {
    expect({ MVC::Keayl::Admin.register(FilterDoc, { filter('category', :as<select>) }) }).to.throw;
  }
}
