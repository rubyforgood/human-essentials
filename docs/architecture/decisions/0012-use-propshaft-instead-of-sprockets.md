# 12. Use Propshaft instead of Sprockets

Date: 2026-08-20

## Status

Accepted

Follows [11. Adopt the Ruby for Good design system (Tailwind v4)](0011-adopt-the-ruby-for-good-design-system.md)

## Context

Sprockets is a compiler. It concatenates files named by `//= require` directives, preprocesses
ERB and Sass, minifies with a configured compressor, and serves the result from a precompile
manifest. Every one of those jobs used to be load-bearing here.

None of them is any more, and [ADR 0011](0011-adopt-the-ruby-for-good-design-system.md) is why.
After the design system migration this application has:

- **No directives.** The only `//= require`-style file left was `app/assets/config/manifest.js`
  itself, which exists solely to tell Sprockets what to precompile.
- **No ERB assets and no Sass.** sassc-rails is gone; Tailwind v4 compiles the single stylesheet
  through its own standalone CLI, with no Node and no Ruby preprocessing.
- **No bundling.** JavaScript is served unbundled through importmap, which is the point of
  importmap.
- **One stylesheet.** `app/assets/builds/tailwind.css`, already minified by the Tailwind CLI
  before Sprockets ever sees it.

What remained was Sprockets digesting filenames and rewriting `url()` references in CSS —
precisely, and only, what Propshaft does.

The configuration had also become a liability rather than an asset. `config.assets.css_compressor`
had to be explicitly disabled because libsass cannot parse what Tailwind v4 emits; the Tailwind
source directory had to be rejected from the load path in an initializer because Sprockets would
otherwise resolve `application.css` to a file beginning `@import "tailwindcss"`; and
`config/initializers/assets.rb` carried a precompile list that had to be kept in step by hand.
Three pieces of configuration existing to stop a compiler compiling.

## Decision

Replace `sprockets-rails` and `sprockets` with `propshaft`.

The Tailwind source is still kept off the load path, now through Propshaft's own
`config.assets.excluded_paths` rather than by mutating `config.assets.paths` after the fact.

`terser` goes with it. Propshaft does not transform assets, so a JavaScript compressor has
nothing to hook into.

## Consequences

**The precompile list is gone.** Propshaft serves everything on the load path, so
`config.assets.precompile` no longer exists and cannot fall out of date. `manifest.js` is deleted.

**Sprockets-only settings are deleted, not migrated.** `compile`, `debug`, `digest`,
`check_precompiled_asset`, `js_compressor` and `css_compressor` are not Propshaft options. Leaving
them would have been dead configuration that reads as meaningful.

**Development and test no longer need a precompile step.** Propshaft serves from the load path in
both (`config.assets.server`). This inverts a trap that has caught us before: it used to be that
you had to run `assets:precompile` after changing an asset, and now running it *freezes* assets
until `public/assets/.manifest.json` is deleted. `CLAUDE.md` says so.

**JavaScript is no longer minified in production.** It was not bundled either, so what ships is
the same set of files, unminified. The app's own controllers are small; the largest vendored file
is a dist build that is already minified. Compression at the web server (gzip/brotli) covers the
rest, and it is where it belongs — this is a change in who compresses, not whether.

**`url()` references gain quotes.** Propshaft's CSS compiler rewrites `url(/vendor/x)` as
`url("/vendor/x")`. The 12 font URLs in the stylesheet are absolute paths into `public/vendor`,
outside the load path, so their targets are untouched — the served file is 24 bytes larger and
otherwise identical, which is 12 URLs times two quotes.

**Asset resolution is tested through a different API.** `spec/assets/asset_resolution_spec.rb`
used Sprockets' `find_asset`; it now goes through `assets.load_path`, and additionally fetches the
served stylesheet to confirm the font URLs survive compilation.

**Nothing in CI changes.** `tailwindcss-rails` enhances `assets:precompile` with
`tailwindcss:build`, so the existing workflow steps still do the right thing in the right order.
