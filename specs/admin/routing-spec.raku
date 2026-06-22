use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::DSL;

class Widget { }

describe 'MVC::Keayl::Admin per-resource routes', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.register(Widget, { ; });
  }

  let(:router, { MVC::Keayl::Admin.engine.router });

  it 'generates the index route', {
    expect(router.recognize('GET', '/widgets').action).to.be('index');
  }

  it 'generates the new route', {
    expect(router.recognize('GET', '/widgets/new').action).to.be('new');
  }

  it 'generates the create route', {
    expect(router.recognize('POST', '/widgets').action).to.be('create');
  }

  it 'generates the show route', {
    expect(router.recognize('GET', '/widgets/5').action).to.be('show');
  }

  it 'captures the id on the show route', {
    expect(router.recognize('GET', '/widgets/5').params<id>).to.be('5');
  }

  it 'generates the edit route', {
    expect(router.recognize('GET', '/widgets/5/edit').action).to.be('edit');
  }

  it 'generates the update route', {
    expect(router.recognize('PATCH', '/widgets/5').action).to.be('update');
  }

  it 'generates the destroy route', {
    expect(router.recognize('DELETE', '/widgets/5').action).to.be('destroy');
  }
}

describe 'MVC::Keayl::Admin url helpers', {
  before-each {
    MVC::Keayl::Admin.reset;
    MVC::Keayl::Admin.register(Widget, { ; });
  }

  it 'builds the collection path', {
    expect(MVC::Keayl::Admin.path-for('widgets')).to.be('/admin/widgets');
  }

  it 'builds the member path', {
    expect(MVC::Keayl::Admin.path-for('widget', 5)).to.be('/admin/widgets/5');
  }

  it 'builds the new path', {
    expect(MVC::Keayl::Admin.path-for('new-widget')).to.be('/admin/widgets/new');
  }

  it 'builds the edit path', {
    expect(MVC::Keayl::Admin.path-for('edit-widget', 5)).to.be('/admin/widgets/5/edit');
  }

  context 'with a configured mount path', {
    before-each {
      MVC::Keayl::Admin.configure(mount-path => '/manage');
    }

    it 'reflects the mount path', {
      expect(MVC::Keayl::Admin.path-for('widgets')).to.be('/manage/widgets');
    }
  }
}
