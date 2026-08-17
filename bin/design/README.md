# Design migration tooling

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
