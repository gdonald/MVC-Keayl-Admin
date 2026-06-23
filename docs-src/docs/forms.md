# Forms

New and edit forms are built from declared `field`s. Each field maps by `:as` to
an input type:

| `:as`      | Input                          |
| ---------- | ------------------------------ |
| `string`   | text input                     |
| `text`     | textarea                       |
| `select`   | dropdown (from `:collection`)  |
| `boolean`  | checkbox                       |
| `date`     | date picker                    |
| `time`     | time picker                    |
| `datetime` | datetime-local picker          |
| `number`   | number input                   |
| `password` | password input                 |
| `hidden`   | hidden input                   |
| `file`     | file input                     |

```raku
field('title',     :as<string>, :placeholder<Headline>, :hint('Keep it short.'));
field('body',      :as<text>);
field('published', :as<boolean>);
field('author-id', :as<select>, :collection({ Author.all.all.map(-> $a { $a.id => $a.name }) }));
field('tag-ids',   :as<select>, :multiple, :collection({ Tag.all.all.map(-> $t { $t.id => $t.name }) }));
```

Field labels resolve through I18n (`human-attribute-name`), and a `:hint` and
`:placeholder` render alongside the input. A `select` renders a dropdown from its
explicit `collection`; with `:multiple` it renders a multi-select for a
collection association.

## Persistence

Create and update assign only the attributes named in the resource's `permit`
allowlist, so an unlisted parameter is never mass-assigned. On success the action
redirects to the show page with a flash; on a validation failure it re-renders
the form with the submitted values.

```raku
permit(<title body published author-id>);
```

Because an HTML form cannot issue a `PATCH`, the engine also accepts a plain
`POST` to the member path for the update action, so editing works without
JavaScript.

## Validation errors

A failed save re-renders the form. ORM validation errors show inline beneath each
field and in a summary at the top, using the ORM's `full-messages`.

## Not yet covered

Nested attributes for associations (`accepts-nested-attributes-for`) and file
uploads backed by Active Storage are planned and not yet implemented; the `file`
input renders but is not wired to storage.
