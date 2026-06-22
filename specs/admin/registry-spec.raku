use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Resource;
use MVC::Keayl::Admin::DSL;
use MVC::Keayl::I18n;

class BlogPost { }
class Category { }

describe 'MVC::Keayl::Admin resource names', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:posts, { MVC::Keayl::Admin.register(BlogPost, { ; }) });

  it 'derives the slug as the dasherized plural', {
    expect(posts.slug).to.be('blog-posts');
  }

  it 'derives the singular human name', {
    expect(posts.singular-name).to.be('Blog post');
  }

  it 'derives the plural human name', {
    expect(posts.plural-name).to.be('Blog posts');
  }

  it 'pluralizes a trailing y', {
    expect(MVC::Keayl::Admin.register(Category, { ; }).slug).to.be('categories');
  }
}

describe 'MVC::Keayl::Admin registry lookup', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:posts,      { MVC::Keayl::Admin.register(BlogPost, { ; }) });
  let(:categories, { MVC::Keayl::Admin.register(Category, { ; }) });

  it 'finds a resource by slug', {
    posts; categories;
    expect(MVC::Keayl::Admin.registry.by-slug('blog-posts')).to.be(posts);
  }

  it 'finds a resource by model', {
    posts; categories;
    expect(MVC::Keayl::Admin.registry.by-model(BlogPost)).to.be(posts);
  }

  it 'preserves registration order in the listing', {
    posts; categories;
    expect(MVC::Keayl::Admin.registry.all[0]).to.be(posts);
  }
}

describe 'MVC::Keayl::Admin name overrides', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:custom, { MVC::Keayl::Admin.register(BlogPost, { ; }, slug => 'articles', singular => 'Article', plural => 'Articles') });

  it 'overrides the slug', {
    expect(custom.slug).to.be('articles');
  }

  it 'overrides the singular name', {
    expect(custom.singular-name).to.be('Article');
  }

  it 'overrides the plural name', {
    expect(custom.plural-name).to.be('Articles');
  }
}

describe 'MVC::Keayl::Admin name resolution through i18n', {
  before-each {
    MVC::Keayl::Admin.reset;
  }

  let(:i18n, {
    my $backend = MVC::Keayl::I18n.new(default-locale => 'en');
    $backend.store-translations('en', { activerecord => { models => { blog_post => 'Journal entry' } } });
    $backend
  });

  it 'resolves the human name through i18n', {
    my $resource = MVC::Keayl::Admin.register(BlogPost, { ; });
    expect($resource.singular-name(i18n => i18n)).to.be('Journal entry');
  }
}
