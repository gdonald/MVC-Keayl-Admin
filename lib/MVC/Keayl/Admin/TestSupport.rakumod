use v6.d;
use ORM::ActiveRecord::Adapter::Sqlite;
use ORM::ActiveRecord::DB;
use ORM::ActiveRecord::Model;
use MVC::Keayl::Storage::Service;
use MVC::Keayl::Storage::Repository;
use MVC::Keayl::Storage::Attached;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::DSL;

# Author and Post models and helpers the admin test suites register and
# exercise. This lives under lib/ so prove6 and behave both load it from the
# standard -Ilib path, without a per-spec `use lib 'specs/lib'`. The models are
# defined at load with no database work; each test stands up a fresh in-memory
# database, which also keeps record ids stable per test.

unit module MVC::Keayl::Admin::TestSupport;

%*ENV<DISABLE-SQL-LOG> = True;

class Author is Model is export {
  submethod BUILD {
    self.has-many: posts => class-name => 'Post';

    self.accepts-nested-attributes-for: 'posts',
      allow-destroy => True,
      reject-if     => -> %a { (%a<title> // '').trim eq '' };
  }
}

class Post is Model is export {
  submethod BUILD {
    self.belongs-to: author => %( class-name => 'Author', optional => True );

    self.validate: 'title', { :presence };
  }
}

# A real app declares its models at the top level, where the ORM resolves the
# string class-names in associations (it looks them up in GLOBAL::). These test
# models live in a precompiled module, so alias them into GLOBAL:: at runtime.
GLOBAL::{'Author'} := Author;
GLOBAL::{'Post'}   := Post;

sub setup-admin-db(--> Nil) is export {
  my $adapter = SqliteAdapter.new(database => ':memory:');

  DB.set-shared(DB.new(adapter => $adapter));

  reset-storage;
  set-storage-service(DiskService.new(root => $*TMPDIR.add('keayl-admin-storage-' ~ $*PID)));
  set-storage-repository(MemoryRepository.new);

  $adapter.ddl-create-table('authors', [
    name => { :string, limit => 255 },
  ]);

  $adapter.ddl-create-table('posts', [
    title     => { :string, limit => 255 },
    body      => { :string },
    published => { :boolean, default => False },
    author_id => { :integer },
  ]);
}

sub seed-posts(**@rows --> Nil) is export {
  Post.destroy-all;

  Post.create($_) for @rows;
}

sub seed-authors(**@rows --> List) is export {
  Author.destroy-all;

  my @created;
  @created.push: Author.create($_) for @rows;
  @created.List
}

sub register-posts(Int :$per-page, Bool :$scope-counts --> Nil) is export {
  MVC::Keayl::Admin.register(Post, :$per-page, :$scope-counts, {
    scope('All', :default);
    scope('Published', { .where({ published => True }) });

    column('title', :sortable, :format<link-to-show>);
    column('headline', :display({ .title.uc }));
    column('published', :sortable, :format<boolean>);

    filter('title', :as<string>);
    filter('published', :as<boolean>);

    batch-action('Publish', -> @records { .update({ published => True }) for @records });

    member-action('approve', -> $controller, $record {
      $record.update({ published => True });
      $controller.redirect-to('/admin/posts/' ~ $record.id);
    }, :confirm('Approve this post?'));

    collection-action('publish-all', -> $controller, $relation {
      .update({ published => True }) for $relation.all;
      $controller.redirect-to('/admin/posts');
    });

    attribute('title');
    attribute('body');
    attribute('published', :format<boolean>);
    attribute('author');

    field('title', :as<string>, :placeholder<Headline>, :hint('Keep it short.'));
    field('body', :as<text>);
    field('published', :as<boolean>);
    field('author-id', :as<select>, :collection({ Author.all.all.map(-> $a { $a.id => $a.read-attribute('name') }) }));
    field('cover', :as<file>);

    permit(<title body published author-id>);
  });
}

sub register-authors-nested(--> Nil) is export {
  MVC::Keayl::Admin.register(Author, {
    field('name', :as<string>);

    permit(<name>);

    nested('posts', :multiple, { field('title', :as<string>) });
  });
}

sub register-authors(--> Nil) is export {
  MVC::Keayl::Admin.register(Author, {
    column('name', :sortable);

    attribute('name');
    attribute('posts');
  });
}
