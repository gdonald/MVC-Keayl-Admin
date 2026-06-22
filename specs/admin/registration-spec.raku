use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Resource;
use MVC::Keayl::Admin::DSL;

class TestModel { }

sub register-sample {
  MVC::Keayl::Admin.register(TestModel, {
    menu(:group<Content>, :label<Posts>, :priority(10), :icon<file-text>);

    scope('All', :default);
    scope('Published', { .grep(*.published) });

    column('title', :sortable);
    column('author', :display({ .author-name }));

    attribute('title');
    attribute('body');

    field('title', :as<string>);
    field('published', :as<boolean>);

    filter('title', :as<string>, :predicate<cont>);
    filter('author-id', :as<select>, :collection({ <a b> }));

    permit(<title body published>);
  })
}

describe 'MVC::Keayl::Admin registration', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:resource, { register-sample });

  it 'returns a resource config', {
    expect(resource() ~~ MVC::Keayl::Admin::Resource).to.be-truthy;
  }

  it 'reports the model name on the resource', {
    expect(resource.model-name).to.be('TestModel');
  }

  context 'after a model is registered', {
    before-each {
      register-sample;
    }

    it 'adds the resource to the registry', {
      expect(MVC::Keayl::Admin.registry.all.elems).to.be(1);
    }
  }

  context 'after a reset', {
    before-each {
      register-sample;
      MVC::Keayl::Admin.reset;
    }

    it 'clears the registry', {
      expect(MVC::Keayl::Admin.registry.all.elems).to.be(0);
    }
  }
}

describe 'MVC::Keayl::Admin recorded declarations', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:resource, { register-sample });

  it 'records columns with a sortable flag', {
    expect(resource.columns[0].sortable).to.be-truthy;
  }

  it 'records a column display block', {
    expect(resource.columns[1].display.defined).to.be-truthy;
  }

  it 'records attributes', {
    expect(resource.attributes.elems).to.be(2);
  }

  it 'records a field input type', {
    expect(resource.fields[1].as).to.be('boolean');
  }

  it 'records a filter predicate', {
    expect(resource.filters[0].predicate).to.be('cont');
  }

  it 'records a filter collection block', {
    expect(resource.filters[1].collection.defined).to.be-truthy;
  }

  it 'records a default scope', {
    expect(resource.scopes[0].default).to.be-truthy;
  }

  it 'records the permit allowlist', {
    expect(resource.permitted).to.be(<title body published>);
  }

  it 'records the menu priority', {
    expect(resource.menu-entry.priority).to.be(10);
  }
}

describe 'MVC::Keayl::Admin registration validation', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  it 'rejects an unknown field type', {
    expect({ MVC::Keayl::Admin.register(TestModel, { field('title', :as<bogus>) }) }).to.throw;
  }

  it 'rejects an unknown filter type', {
    expect({ MVC::Keayl::Admin.register(TestModel, { filter('title', :as<bogus>) }) }).to.throw;
  }

  it 'rejects an unknown declaration option', {
    expect({ MVC::Keayl::Admin.register(TestModel, { column('title', :unknown-option) }) }).to.throw;
  }
}
