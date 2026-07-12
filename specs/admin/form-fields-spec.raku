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

  it 'sizes a textarea to the configured rows', {
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('body', :as<text>, :rows(8));
    });
    my $rendered = MVC::Keayl::Admin::Form.render($resource, Post.build,
      action => '/admin/posts', submit => 'Create', cancel => '/admin/posts');
    expect($rendered.contains('<textarea') && $rendered.contains('rows="8"')).to.be-truthy;
  }

  it 'formats a date value for the native date input', {
    my $on = Date.new(2026, 5, 25);
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('due', :as<date>, :value({ $on }));
    });
    my $rendered = MVC::Keayl::Admin::Form.render($resource, Post.build,
      action => '/admin/posts', submit => 'Create', cancel => '/admin/posts');
    expect($rendered.contains('value="2026-05-25"')).to.be-truthy;
  }

  it 'formats a time value for the native time input', {
    my $at = DateTime.new(:year(2026), :month(5), :day(25), :hour(9), :minute(7), :second(0));
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('remind-at', :as<time>, :value({ $at }));
    });
    my $rendered = MVC::Keayl::Admin::Form.render($resource, Post.build,
      action => '/admin/posts', submit => 'Create', cancel => '/admin/posts');
    expect($rendered.contains('value="09:07"')).to.be-truthy;
  }

  it 'formats a datetime value for the native input without a timezone offset', {
    my $when = DateTime.new(:year(2026), :month(5), :day(25), :hour(15), :minute(3), :second(0), :timezone(-18000));
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('happened-at', :as<datetime>, :value({ $when }));
    });
    my $rendered = MVC::Keayl::Admin::Form.render($resource, Post.build,
      action => '/admin/posts', submit => 'Create', cancel => '/admin/posts');
    expect($rendered.contains('value="2026-05-25T15:03"')).to.be-truthy;
  }

  it 'passes a pre-formatted string date value through unchanged', {
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('due', :as<date>, :value({ '1999-12-31' }));
    });
    my $rendered = MVC::Keayl::Admin::Form.render($resource, Post.build,
      action => '/admin/posts', submit => 'Create', cancel => '/admin/posts');
    expect($rendered.contains('value="1999-12-31"')).to.be-truthy;
  }

  it 'renders an empty value for a date field with no value', {
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('due', :as<date>, :value({ Nil }));
    });
    my $rendered = MVC::Keayl::Admin::Form.render($resource, Post.build,
      action => '/admin/posts', submit => 'Create', cancel => '/admin/posts');
    expect($rendered.contains('type="date" name="due" value=""')).to.be-truthy;
  }

  it 'computes a field value from the record with a :value block', {
    my $post = Post.create({ title => 'hello' });
    my $resource = MVC::Keayl::Admin.register(Post, {
      field('shout', :as<string>, :value({ .read-attribute('title').uc }));
    });
    my $rendered = MVC::Keayl::Admin::Form.render($resource, $post,
      action => '/admin/posts/1', submit => 'Update', cancel => '/admin/posts');
    expect($rendered.contains('value="HELLO"')).to.be-truthy;
  }
}
