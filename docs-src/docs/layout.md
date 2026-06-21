# Layout and chrome

Admin pages render inside a Bootstrap 5 layout: a top bar with the site brand, a
collapsible left sidebar, a main content region, a flash area, and breadcrumbs.
On small screens the sidebar becomes an offcanvas panel toggled from the top
bar.

## Rendering a page

Controllers derive from `MVC::Keayl::Admin::Controller` and render through
`render-admin`, which wires the chrome (asset tags, brand, menu, breadcrumbs,
flash) into the layout and renders the named template into the main region.

```raku
use MVC::Keayl::Admin::Controller;

unit class MyAdmin::PostsController is MVC::Keayl::Admin::Controller;

method index {
  self.render-admin(
    'posts/index',
    page-title  => 'Posts',
    breadcrumbs => [ 'Posts' => Nil ],
  )
}
```

- `page-title` sets the document title and the page heading. It defaults to the
  configured site title.
- `breadcrumbs` is a list of `label => url` pairs. A pair whose url is `Nil`
  (or empty) renders as the current, unlinked page. Typically the last crumb.

The template named in the first argument renders into the main content region.
The vendored asset bundle, import map, brand, sidebar menu, and breadcrumbs are
supplied by the layout, so a page template only renders its own content.

## The admin context

The base controller runs a `before-action` that builds a per-request context
available as `admin-context` (site title, mount path, and the current path).
Later phases extend it with the current resource and action.
