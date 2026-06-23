# Show pages

The show page renders one record from its declared `attribute`s. Each attribute
is a detail row, using the same formatters as the index, so a value renders the
same way in both places.

```raku
attribute('title');
attribute('published', :format<boolean>);
attribute('body',      :display({ .body.substr(0, 200) }));
attribute('author');     # an association
```

A `:display` block computes the row value; otherwise the value is read from the
column and run through the named `:format`.

## Action panel

A sidebar panel holds the per-record actions: Edit (links to the edit form) and
Delete (an HTMX destroy with a confirmation). Custom member actions join this
panel in a later phase.

## Associations

When an attribute names an association, the show page renders it from the
relationship rather than as a column:

- A **belongs-to** (or has-one) attribute renders as a link to the associated
  record's admin show page, when that model is itself a registered resource. A
  missing association renders a dash, never a broken link.
- A **has-many** (or has-and-belongs-to-many) attribute renders as a compact
  sub-table, each row linking into the associated resource, capped with an "and
  N more" line.

Association kind and target are detected through the ORM's reflection, so the
link targets are resolved from the registry by model.
