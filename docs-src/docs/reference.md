# Configuration reference

The methods called on `MVC::Keayl::Admin` to set the admin up, in one place. Each
links to the page covering it in detail. The per-resource declarations used
inside a `register` block are tabulated in [Registering resources](registration.md).

## Mounting and configuration

| Method | Purpose |
| ------ | ------- |
| `endpoint()` | Returns the engine dispatcher for the host to `mount`. See [Mounting](mounting.md). |
| `config()` | Returns the shared configuration object. |
| `configure(:mount-path, :site-title, :logout-path)` | Sets the mount path, site title, and navbar logout link path. See [Mounting](mounting.md). |
| `registry()` | Returns the resource registry (`by-model`, `by-slug`, `all`). |

## Resources and pages

| Method | Purpose |
| ------ | ------- |
| `register(Model, { ... }, :slug, :singular, :plural, :per-page, :scope-counts)` | Registers a resource. See [Registering resources](registration.md). |
| `page(slug, &block, :title, :group, :label, :priority, :icon, :hide)` | Registers a standalone page. See [Customization](customization.md). |
| `path-for(name, *args)` | Builds the mount-prefixed URL for a resource action. See [Registering resources](registration.md). |

## Navigation and dashboard

| Method | Purpose |
| ------ | ------- |
| `menu-link(:label, :url, :group, :priority, :icon, :external)` | Adds a custom menu link. See [Navigation](navigation.md). |
| `menu-group-order(*groups)` | Orders the menu groups explicitly. See [Navigation](navigation.md). |
| `dashboard-block(&block, :title)` | Adds a custom dashboard panel. See [Navigation](navigation.md). |

## Authentication and authorization

| Method | Purpose |
| ------ | ------- |
| `authenticate-with($strategy)` | Installs an authentication strategy. See [Authentication](authentication.md). |
| `authorize-with($policy)` | Installs an authorization policy. See [Authorization](authorization.md). |

## Assets, theming, and localization

| Method | Purpose |
| ------ | ------- |
| `use-stylesheet($url)` | Layers a host stylesheet after the bundle. See [Assets](assets.md). |
| `view-path($dir)` | Adds a host view path searched before the engine's. See [Customization](customization.md). |
| `load-locales($dir)` | Loads locale files into the I18n backend. See [Customization](customization.md). |
| `locale($code)` | Selects the active locale. See [Customization](customization.md). |

## Generators

The `keayl-admin` command scaffolds the admin from the shell, not from Raku:

| Command | Purpose |
| ------- | ------- |
| `keayl-admin generate admin:install` | Mounts the engine and writes the initializer, dashboard, and auth stubs. |
| `keayl-admin generate admin <Model>` | Emits an explicit registration introspected from the model's schema. |

See [Installation](installation.md).
