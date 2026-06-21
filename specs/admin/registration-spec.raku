use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Resource;

class TestModel { }

describe 'MVC::Keayl::Admin registration', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:resource, { MVC::Keayl::Admin.register(TestModel, { ; }) });

  it 'returns a resource config', {
    expect(resource() ~~ MVC::Keayl::Admin::Resource).to.be-truthy;
  }

  it 'reports the model name on the resource', {
    expect(resource.model-name).to.be('TestModel');
  }

  context 'after a model is registered', {
    before-each {
      MVC::Keayl::Admin.register(TestModel, { ; });
    }

    it 'adds the resource to the registry', {
      expect(MVC::Keayl::Admin.registry.all.elems).to.be(1);
    }
  }

  context 'after a reset', {
    before-each {
      MVC::Keayl::Admin.register(TestModel, { ; });
      MVC::Keayl::Admin.reset;
    }

    it 'clears the registry', {
      expect(MVC::Keayl::Admin.registry.all.elems).to.be(0);
    }
  }
}

describe 'MVC::Keayl::Admin resource declarations', {
  let(:resource, { MVC::Keayl::Admin::Resource.new(:model(TestModel)) });

  context 'with a recorded declaration', {
    before-each {
      resource.declare('column', 'title', :sortable);
    }

    it 'returns declarations of a given kind', {
      expect(resource.declarations-of('column').elems).to.be(1);
    }

    it 'records the positional arguments', {
      expect(resource.declarations-of('column')[0]<args>[0]).to.be('title');
    }

    it 'records the named options', {
      expect(resource.declarations-of('column')[0]<opts><sortable>).to.be-truthy;
    }
  }
}
