# Navigation and dashboard

## Sidebar menu

Every registered resource gets a sidebar entry that links to its index. A `menu`
declaration overrides the label and Bootstrap icon, assigns a group, sets a
`priority`, or hides the resource:

```raku
MVC::Keayl::Admin.register(Post, {
  menu(group => 'Content', label => 'Articles', icon => 'file-text', priority => 1);
});

MVC::Keayl::Admin.register(AuditLog, {
  menu(:hide);
});
```

Resources that share a group render under a collapsible section. Items within a
group are ordered by `priority` (lower first), then by label. The current
resource is highlighted, and the group containing it is expanded.

Group order, custom internal links, and external links are configured on the
admin:

```raku
MVC::Keayl::Admin.menu-group-order('System', 'Content');

MVC::Keayl::Admin.menu-link(label => 'Reports', url => '/reports', group => 'System');
MVC::Keayl::Admin.menu-link(label => 'Docs', url => 'https://example.com/docs', :external);
```

Internal link urls are prefixed with the mount path. External links open in a new
tab. Groups listed in `menu-group-order` come first, in that order; the rest
follow alphabetically.

## Dashboard

The mount root renders a dashboard. Its default block lists every registered
resource as a card showing the record count and a link to the index. Custom
panels are added with `dashboard-block`, whose block returns the panel's HTML:

```raku
MVC::Keayl::Admin.dashboard-block(title => 'Recent activity', {
  '<ul>' ~ Post.all.order('created_at DESC').limit(5).all.map({ '<li>' ~ .title ~ '</li>' }).join ~ '</ul>'
});
```
