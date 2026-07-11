# Changelog

All notable changes to MVC::Keayl::Admin are documented here.

## [0.9.0] - 2026-07-11

Initial public release. A generated administration interface for
[MVC::Keayl](https://github.com/gdonald/MVC-Keayl) applications. The admin
mounts as an engine, delegates the model layer to
[ORM::ActiveRecord](https://github.com/gdonald/ORM-ActiveRecord)
and view rendering to
[Template::HAML](https://github.com/gdonald/Template-HAML),
and ships a Bootstrap 5, Bootstrap Icons, and HTMX frontend served through the
asset pipeline.

### Added

- Engine mounting so the admin attaches to a host MVC::Keayl application without
  the framework depending on the admin.
- Resource registration with an explicit DSL, backed by a registry of declared
  resources.
- Index pages with columns, sorting, and pagination.
- Index presentations and panels for laying out list views.
- Show pages with attribute and panel rendering, including nested `belongs_to`
  associations.
- Forms for create and update, with fields, formatters, and validation surfacing.
- A `:label` option on `column` and `field` to override the humanized column
  header or form label.
- An `:html` flag on `column` and `attribute` so a trusted `display` value renders
  as raw markup instead of being HTML-escaped, honored on the table, grid, and
  blog index presentations and on show-page attributes.
- Filters and search, with association filters that require an explicit
  `collection` so large tables are never enumerated into a dropdown, in an
  offcanvas panel rendered outside the htmx-swapped index body so sorting,
  paging, or filtering never tears down an open panel.
- Scopes for predefined, named record subsets.
- Destroy, batch, and custom actions, with per-action availability and a toolbar
  that groups batch controls on the left with the collection actions, New-record
  button, and Filters button on the right, and a footer row placing pagination
  and the record summary opposite the export links.
- Menu bar actions and a navigable left sidebar with a dashboard landing page.
- Nested resources.
- Data export.
- Authentication, with session and HTTP basic strategies.
- Authorization, with roles, abilities, and policies.
- Layout and chrome: a Django-style left sidebar of grouped, ordered menu
  entries and a right main content area, with page headings that name the current
  page and breadcrumbs limited to a nested resource's ancestor trail.
- Asset pipeline serving vendored Bootstrap 5, Bootstrap Icons, and HTMX, with
  progressive enhancement so every action degrades to a full-page request when
  JavaScript is disabled.
- Internationalization support.
- Inflection and pluralization helpers for generated labels and routes,
  title-casing each word of a label and dropping a trailing `_id` or `_at`
  suffix.
- `keayl generate admin <Model>` generator that reads the schema and writes
  explicit declarations for the developer to edit.
- Test support helpers for exercising admin resources.
