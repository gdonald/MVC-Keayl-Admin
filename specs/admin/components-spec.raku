use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Engine;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::View;
use MVC::Keayl::Admin::Filter;
use MVC::Keayl::Engine;
use MVC::Keayl::Controller;
use MVC::Keayl::View;

describe 'MVC::Keayl::Admin engine', {
  it 'isolates the admin namespace', {
    expect(MVC::Keayl::Admin::Engine.new.namespace).to.be('MVC::Keayl::Admin');
  }

  it 'is built by the entry point', {
    expect(MVC::Keayl::Admin.engine ~~ MVC::Keayl::Admin::Engine).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin base classes', {
  it 'derives the controller from the framework controller', {
    expect(MVC::Keayl::Admin::Controller.new ~~ MVC::Keayl::Controller).to.be-truthy;
  }

  it 'derives the view from the framework view', {
    expect(MVC::Keayl::Admin::View.new ~~ MVC::Keayl::View).to.be-truthy;
  }
}

describe 'MVC::Keayl::Admin filter', {
  it 'defaults to the string type', {
    expect(MVC::Keayl::Admin::Filter.new(:name<title>).as).to.be('string');
  }

  context 'with a predicate', {
    let(:filter, { MVC::Keayl::Admin::Filter.new(:name<title>, :predicate<cont>) });

    it 'records the predicate', {
      expect(filter.predicate).to.be('cont');
    }
  }
}
