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

## Rows and actions

Every row ends in an actions column with Show, Edit, and Delete controls. Delete
is wired for HTMX (the destroy flow lands in a later phase). When a resource has
no records, the table shows an empty state instead of rows, and the page carries
a New-record button linking to the new form.
