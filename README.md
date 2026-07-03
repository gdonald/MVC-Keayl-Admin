# MVC::Keayl::Admin

A generated administration interface for applications built on
[MVC::Keayl](https://github.com/gdonald/MVC-Keayl), in the spirit of Django
admin and Active Admin.

The admin mounts as an engine and depends on the framework's public surface
only. The model layer is delegated to
[ORM::ActiveRecord](https://github.com/gdonald/ORM-ActiveRecord) and view
rendering to [Template::HAML](https://github.com/gdonald/Template-HAML). It
carries a frontend opinion (Bootstrap 5, Bootstrap Icons, HTMX) that
MVC::Keayl deliberately does not. The dependency runs one way: the admin
depends on MVC::Keayl, never the reverse.

## Status

Early development. See [ROADMAP.md](ROADMAP.md) for the planned surface.

## Vendored assets

The admin vendors Bootstrap 5, Bootstrap Icons, and htmx so it works with no
external requests. These are third-party works under their own licenses,
separate from this distribution's Artistic-2.0 license. See
[NOTICES.md](NOTICES.md).

## Testing

Run the prove6 and behave suites:

```
./bin/test
```

## License

Artistic-2.0. See [LICENSE](LICENSE).
