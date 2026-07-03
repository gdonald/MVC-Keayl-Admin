# Changelog

All notable changes to MVC::Keayl::Admin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- An `:html` flag on `column` and `attribute` so a trusted `display` value renders
  as raw markup instead of being HTML-escaped. Honored on the table, grid, and
  blog index presentations and on show-page attributes.

## [0.9.0] - 2026-06-25

Initial public release. A generated administration interface for
[MVC::Keayl](https://github.com/gdonald/MVC-Keayl) applications, in the spirit
of Django admin and Active Admin. The admin mounts as an engine, delegates the
model layer to [ORM::ActiveRecord](https://github.com/gdonald/ORM-ActiveRecord)
and view rendering to [Template::HAML](https://github.com/gdonald/Template-HAML),
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
- Filters and search, with association filters that require an explicit
  `collection` so large tables are never enumerated into a dropdown.
- Scopes for predefined, named record subsets.
- Destroy, batch, and custom actions, with per-action availability and a toolbar.
- Menu bar actions and a navigable left sidebar with a dashboard landing page.
- Nested resources.
- Data export.
- Authentication, with session and HTTP basic strategies.
- Authorization, with roles, abilities, and policies.
- Layout and chrome: a Django-style left sidebar of grouped, ordered menu
  entries and a right main content area.
- Asset pipeline serving vendored Bootstrap 5, Bootstrap Icons, and HTMX, with
  progressive enhancement so every action degrades to a full-page request when
  JavaScript is disabled.
- Internationalization support.
- Inflection and pluralization helpers for generated labels and routes.
- `keayl generate admin <Model>` generator that reads the schema and writes
  explicit declarations for the developer to edit.
- Test support helpers for exercising admin resources.

[0.9.0]: https://github.com/gdonald/MVC-Keayl-Admin/releases/tag/v0.9.0
