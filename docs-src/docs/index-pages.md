# Index pages

The index page lists a resource's records in a table built from the declared
`column`s. A generic controller resolves the resource from the URL, queries the
model's ORM relation, and renders the table.

## Columns

Each `column` becomes a table column. The header is the humanized column name.
A column renders its value one of three ways:

- a plain attribute read from the record (`column('title')`);
- a `display` block, called with the record, for a computed value
  (`column('author', :display({ .author.name }))`);
- a `format`, applied to the attribute value.

## Formatters

`MVC::Keayl::Admin::Formatter` provides value formatters shared by the index and
the show page: `date`, `time`, `datetime`, `currency`, `boolean`, and
`truncate`. A column with `:format<boolean>` renders Yes/No, `:format<date>`
renders the date portion, and so on.

`:format<link-to-show>` is special: it links the value to the record's show
page, so a title column can double as the row's primary link.

`:format<status-tag>` renders the value as a colored Bootstrap badge, reused on
the show page. A boolean renders as a green Yes or a grey No; a string maps known
states to colors (`active`/`published`/`approved` green, `pending` amber,
`draft`/`inactive` grey, `rejected`/`failed` red) and humanizes the label,
defaulting to grey for an unknown value. Pair it with a `display` block to derive
the state from the record:

```raku
column('state', :format<status-tag>, :display({ .published ?? 'active' !! 'draft' }));
```

## Rows and actions

Every row ends in an actions column with Show, Edit, and Delete controls. Delete
issues an HTMX destroy with a confirmation and removes the row in place; see
[Destroy, batch, and custom actions](actions.md). When a resource has no records,
the table shows an empty state instead of rows, and the page carries a New-record
button linking to the new form. Row controls are hidden when the authorization
policy forbids the action, and the export and batch toolbars sit above the table.

## Sorting

A column declared `:sortable` renders its header as a link. Clicking it sorts the
index by that column, adding an `ORDER BY` to the relation. The sort column and
direction travel in the query string (`?sort=title&dir=desc`); the active column
shows a direction arrow, and clicking it again toggles ascending and descending.
Only declared sortable columns are accepted, so the order clause is never built
from arbitrary input.

## Pagination

The index applies `LIMIT` and `OFFSET` for the current page. The page size
defaults to 25 and is configurable per resource:

```raku
MVC::Keayl::Admin.register(Post, { ... }, per-page => 50);
```

A pagination control renders below the table with a page summary
(`Showing 1–25 of 218`) and page links. The links carry the current sort state
so it survives navigation.

## HTMX

The table and pagination live inside an `#admin-index` container. Sort-header and
pagination links issue an `hx-get` that targets that container, so the table body
swaps in place without a full-page reload. Each link also has a plain `href`, so
with JavaScript disabled the same action degrades to a full-page request.

