use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::DSL;
use MVC::Keayl::Admin::Engine;
use MVC::Keayl::Admin::Filter;
use MVC::Keayl::Admin::Registry;
use MVC::Keayl::Admin::Resource;
use MVC::Keayl::Admin::View;

describe 'MVC::Keayl::Admin distribution', {
  it 'loads its entry point', {
    expect(MVC::Keayl::Admin.^name).to.be('MVC::Keayl::Admin');
  }

  it 'loads the registry', {
    expect(MVC::Keayl::Admin::Registry.^name).to.be('MVC::Keayl::Admin::Registry');
  }

  it 'loads the resource config', {
    expect(MVC::Keayl::Admin::Resource.^name).to.be('MVC::Keayl::Admin::Resource');
  }

  it 'loads the engine', {
    expect(MVC::Keayl::Admin::Engine.^name).to.be('MVC::Keayl::Admin::Engine');
  }

  it 'loads the base controller', {
    expect(MVC::Keayl::Admin::Controller.^name).to.be('MVC::Keayl::Admin::Controller');
  }

  it 'loads the base view', {
    expect(MVC::Keayl::Admin::View.^name).to.be('MVC::Keayl::Admin::View');
  }

  it 'loads a filter', {
    expect(MVC::Keayl::Admin::Filter.^name).to.be('MVC::Keayl::Admin::Filter');
  }
}
