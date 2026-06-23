use v6.d;
use ORM::ActiveRecord::Adapter::Sqlite;
use ORM::ActiveRecord::DB;
use ORM::ActiveRecord::Model;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::DSL;

# A Post model and helpers the admin test suites register and exercise. This
# lives under lib/ so prove6 and behave both load it from the standard -Ilib
# path, without a per-spec `use lib 'specs/lib'`. The model is defined at load
# with no database work; each test stands up a fresh in-memory database, which
# also keeps record ids stable per test.

unit module MVC::Keayl::Admin::TestSupport;

%*ENV<DISABLE-SQL-LOG> = True;

class Post is Model is export { }

sub setup-admin-db(--> Nil) is export {
  my $adapter = SqliteAdapter.new(database => ':memory:');

  DB.set-shared(DB.new(adapter => $adapter));

  $adapter.ddl-create-table('posts', [
    title     => { :string, limit => 255 },
    body      => { :string },
    published => { :boolean, default => False },
  ]);
}

sub seed-posts(**@rows --> Nil) is export {
  Post.destroy-all;

  Post.create($_) for @rows;
}

sub register-posts(Int :$per-page --> Nil) is export {
  MVC::Keayl::Admin.register(Post, :$per-page, {
    column('title', :sortable, :format<link-to-show>);
    column('headline', :display({ .title.uc }));
    column('published', :sortable, :format<boolean>);

    filter('title', :as<string>);
    filter('published', :as<boolean>);
  });
}
