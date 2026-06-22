# Registering resources

A resource is declared by hand with `register`. Everything the admin shows for a
model is stated explicitly. Nothing is inferred at request time.

```raku
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::DSL;

Keayl::Admin.register(Post, {
  menu(:group<Content>, :label<Posts>, :priority(10), :icon<file-text>);

  scope('All', :default);
  scope('Published', { .where(:published(True)) });

  column('title', :sortable);
  column('author', :display({ .author.name }));
  column('published-at', :format<date>);

  filter('title',      :as<string>,  :predicate<cont>);
  filter('published',  :as<boolean>);
  filter('author-id',  :as<select>, :collection({ Author.all.map({ .id => .name }) }));

  attribute('title');
  attribute('body');
  attribute('author');

  field('title',     :as<string>);
  field('body',      :as<text>);
  field('author-id', :as<select>, :collection({ Author.all }));
  field('published', :as<boolean>);

  permit(<title body author-id published>);
});
```

The declaration vocabulary comes from `MVC::Keayl::Admin::DSL`. Each call records
a declaration on the resource config:

| Declaration | Records                                                        |
| ----------- | ------------------------------------------------------------- |
| `column`    | an index column (`:sortable`, `:display`, `:format`)          |
| `attribute` | a show-page row (`:display`, `:format`)                       |
| `field`     | a form input (`:as`, `:collection`, `:hint`, `:placeholder`)  |
| `filter`    | a search control (`:as`, `:predicate`, `:collection`)         |
| `scope`     | a named scope, one markable `:default`                        |
| `permit`    | the strong-params allowlist                                   |
| `menu`      | the sidebar entry (`:group`, `:label`, `:priority`, `:icon`)  |

## Validation

Declarations are validated when `register` runs. An unknown option, an unknown
`field`/`filter` type, or a malformed declaration raises at registration time
rather than failing later on a request.

## Names and slug

Each resource derives a URL slug, a singular human name, and a plural human name
from the model. The slug is the dasherized plural (`BlogPost` becomes
`blog-posts`). The human names resolve through I18n, falling back to a humanized
form of the model name. Override any of them on `register`:

```raku
Keayl::Admin.register(Post, { ... }, slug => 'articles', singular => 'Article', plural => 'Articles');
```

The registry indexes resources by model and by slug, with `by-model`, `by-slug`,
and an `all` listing in registration order.

## Routes and URL helpers

Registering a resource generates the seven routes (index, show, new, create,
edit, update, destroy) under the engine. `path-for` builds the mount-prefixed URL
for any resource action, usable from controllers and views:

```raku
Keayl::Admin.path-for('posts');           # /admin/posts
Keayl::Admin.path-for('post', 5);         # /admin/posts/5
Keayl::Admin.path-for('edit-post', 5);    # /admin/posts/5/edit
Keayl::Admin.path-for('new-post');        # /admin/posts/new
```
