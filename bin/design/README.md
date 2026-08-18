# Design tooling

`audit.js` renders a page in headless Chromium as a signed-in bank admin and reports the
things a design migration silently gets wrong: sidebar geometry, the computed h1/card/active-nav
tokens, leftover Bootstrap/AdminLTE class names, Font Awesome icons that render as nothing on a
Tailwind page, and heading order.

```bash
bin/start                                 # or: bundle exec rails s -p 3003
node bin/design/audit.js /dashboard 1400  # path, viewport width
```

Requires `playwright` on the Node path and a dev server on port 3003 seeded with the standard
dev credentials (`org_admin1@example.com` / `password!`).

Read the output as a checklist: `legacyClassesPresent` and `faIcons` must both be empty/zero on
a migrated page, `hOrder` must not skip a level, and `activeNav` must be brand-50 on brand-700.

`sweep.js` does the same checks across every significant page in one run — 56 of them, covering
the bank app, the admin area and the partner portal — and prints only what is wrong.

```bash
bin/start                # or: bundle exec rails s -p 3003
pw bin/design/sweep.js
```

A page is clean when it has no leftover Bootstrap/AdminLTE or Font Awesome classes, exactly one
`<h1>` and one `<main>`, no skipped heading levels, no unlabelled form controls, no buttons
without an accessible name, no stylesheets from outside the app, no console errors, and is
rendering in Figtree.

This complements the specs rather than repeating them. It catches what renders without raising
— and the specs catch what a static walk cannot: a form whose fields end up outside the form,
a Stimulus controller toggling a class that no longer exists, a confirmation that never
appears. Neither on its own is enough; that is the lesson of this migration.

`status.rb` reports which controllers render on a design system layout, resolving layout
inheritance.

```bash
ruby bin/design/status.rb
```
