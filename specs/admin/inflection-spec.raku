use BDD::Behave;
use MVC::Keayl::Admin::Inflection;

describe 'MVC::Keayl::Admin::Inflection underscore', {
  it 'splits camel case and lower-cases', {
    expect(underscore('BlogPost')).to.be('blog_post');
  }

  it 'lower-cases a single word', {
    expect(underscore('Post')).to.be('post');
  }
}

describe 'MVC::Keayl::Admin::Inflection dasherize', {
  it 'turns underscores into hyphens', {
    expect(dasherize('blog_post')).to.be('blog-post');
  }
}

describe 'MVC::Keayl::Admin::Inflection humanize', {
  it 'title-cases each word of an underscored name', {
    expect(humanize('blog_post')).to.be('Blog Post');
  }

  it 'title-cases each word of a dashed name', {
    expect(humanize('published-at')).to.be('Published At');
  }

  it 'drops a trailing id suffix', {
    expect(humanize('author_id')).to.be('Author');
  }

  it 'drops a trailing at suffix', {
    expect(humanize('created_at')).to.be('Created');
  }

  it 'keeps a trailing name suffix as a word', {
    expect(humanize('first_name')).to.be('First Name');
  }

  it 'keeps a bare name with no underscore prefix', {
    expect(humanize('name')).to.be('Name');
  }

  it 'keeps a bare id with no underscore prefix', {
    expect(humanize('id')).to.be('Id');
  }
}
