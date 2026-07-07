use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::DSL;
use MVC::Keayl::Admin::Form;
use MVC::Keayl::Admin::TestSupport;

describe 'MVC::Keayl::Admin form field rendering', {
  before-each {
    setup-admin-db;
    MVC::Keayl::Admin.reset;
  }

  let(:form, {
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('title', :as<string>, label => 'Headline');
      field('category-id', :as<select>, :collection({ (1 => 'News', 2 => 'Opinion') }));
      field('tag-ids', :as<select>, :multiple, :collection({ (1 => 'Red', 2 => 'Blue') }));
    });

    MVC::Keayl::Admin::Form.render($resource, Post.build,
      action => '/admin/posts', submit => 'Create', cancel => '/admin/posts')
  });

  it 'renders a belongs-to select from its collection', {
    expect(form.contains('name="category-id"') && form.contains('News')).to.be-truthy;
  }

  it 'renders a has-many multi-select posting an array parameter', {
    expect(form.contains('multiple') && form.contains('name="tag-ids[]"')).to.be-truthy;
  }

  it 'renders the multi-select collection options', {
    expect(form.contains('Red') && form.contains('Blue')).to.be-truthy;
  }

  it 'renders a field with its custom label instead of the humanized name', {
    expect(form.contains('>Headline</label>')).to.be-truthy;
  }
}
