# Third-party notices

`MVC::Keayl::Admin` vendors a frontend asset bundle so the admin works with no
external requests. The Raku code in this distribution is licensed under
Artistic-2.0 (see [LICENSE](LICENSE)). The vendored assets below are separate
works, each under its own license. Their license texts are bundled next to the
assets under `assets/` and ship with the distribution.

<!-- vendored-table:start -->
| Component       | Version | License         | Source                                 | Bundled license                  |
| --------------- | ------- | --------------- | -------------------------------------- | -------------------------------- |
| Bootstrap       | 5.3.3   | MIT             | https://github.com/twbs/bootstrap      | `assets/bootstrap/LICENSE`       |
| Bootstrap Icons | 1.11.3  | MIT             | https://github.com/twbs/icons          | `assets/bootstrap-icons/LICENSE` |
| htmx            | 2.0.4   | Zero-Clause BSD | https://github.com/bigskysoftware/htmx | `assets/htmx/LICENSE`            |
<!-- vendored-table:end -->

## Compliance notes

- **MIT (Bootstrap, Bootstrap Icons)** requires that the copyright notice and the
  permission notice be retained in copies. The minified CSS and JS keep their
  upstream copyright banners, and the full `LICENSE` text is bundled with each
  component.
- **Zero-Clause BSD (htmx)** places no conditions on redistribution. The
  `LICENSE` is bundled for completeness.

## Upgrading

The bundle is pinned in `tools/vendored-assets.json` (versions, source URLs, and
sha1 checksums). To upgrade a component, change its version there, run
`raku tools/vendor-assets.raku` to refetch the files and the bundled `LICENSE`
and refresh the checksums, then review the diff and run the test suite. Update
the version and license columns above in the same change.
`raku tools/vendor-assets.raku --check` verifies the on-disk files still match
the pinned checksums without touching the network.
