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

`route-sweep.js` does the same checks across **every HTML screen the router knows about** — 139
of them, as a super admin, a bank admin and a partner — and prints only what is wrong.

```bash
bin/start                # or: bundle exec rails s -p 3003
pw bin/design/route-sweep.js
```

It asks Rails for the list (`route-targets.rb`, which substitutes a real record id for `:id`)
rather than carrying one. **That is the whole point.** `sweep.js`, below, walks a hardcoded list
of 56 paths, and a list goes stale in silence: the three historical trend pages were in the
sidebar and never on it, and they sat with no page header and no `<h1>` for the length of the
migration while every audit reported clean. On its first run `route-sweep.js` found eleven
unlabelled selects in the partner portal, which the old list never visited.

A 404 from `route-sweep.js` is usually a route with no action behind it — `resources :x`
generates seven and most controllers implement four — so those are listed separately from the
design findings rather than mixed in with them.

`sweep.js` is the older 56-path version, kept because it is quicker to run against a subset.

```bash
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

`responsive-audit.js` visits every screen at **320, 375, 639, 641, 767, 769, 1023, 1025, 1280
and 1440**, plus a landscape phone at 740×360, and reports what only goes wrong when a layout is
squeezed: the page scrolling sideways, tap targets below the minimum, text below 11px, content
clipped with no ellipsis to say so, a nav drawer that cannot be opened below `lg`, and fixed
chrome covering more than half a short viewport.

**The widths straddle the breakpoints on purpose.** 639 and 641 are different layouts and only
one of them ever gets looked at by hand; a layout that breaks usually breaks at the switch.

```bash
pw bin/design/responsive-audit.js
WIDTHS=320 ONLY=/items,/donations pw bin/design/responsive-audit.js   # while fixing
```

**It swipes rather than calling `scrollTo`,** and that is the whole reason it finds anything.
The three obvious measurements all lie: `documentElement.scrollWidth` counts clipped content
nobody can reach, `body.scrollWidth` stays at the viewport width even when the page does scroll,
and `window.scrollTo` gets past `overflow-x: clip` when a finger cannot. Only a wheel gesture,
followed by reading where the `<h1>` ended up, answers the question a phone user is asking.

Tap targets are WCAG 2.5.8's 24×24 **with the exceptions applied** — inline in prose, and the
spacing rule — and the target is the control *plus its label*, because clicking a label
activates its control. Without those, the first version reported 28 failures on the dashboard,
every one of them fine, and 109 across the app of which most were select2's leftover 1×1
`<select>`.

`keyboard-audit.js` checks what axe cannot: that tabbing never walks into something invisible,
that everything clickable can be operated from a keyboard, and that nothing uses a positive
`tabindex`.

```bash
pw bin/design/keyboard-audit.js              # 1280
WIDTH=375 pw bin/design/keyboard-audit.js    # and again on a phone
```

**Run it at both widths.** Below `lg` the sidebar is an off-canvas drawer, and a drawer moved out
of sight with a transform is still in the tab order unless something says otherwise. That bug was
invisible at 1280 and 27 tab stops deep at 375.

It knows that `inert` removes a subtree, that an `aria-hidden` scrim and a `<dialog>` backdrop are
decoration rather than controls, and that the keyboard equivalent of a backdrop click is Escape.

`form-validation-audit.js` opens every `new` form, reads how its required fields are marked,
submits it empty and reads what came back.

```bash
pw bin/design/form-validation-audit.js
ONLY=/items/new pw bin/design/form-validation-audit.js
```

Submitting empty is safe — it fails validation, so nothing is created — and `novalidate` is set
first, because otherwise the browser blocks the submit and the server-side path, the one that
has to work, is never exercised.

It knows three things a naive version gets wrong: a radio or checkbox group is marked on its
`<legend>` and not on each option; a conditionally required field says so in words and correctly
has no `aria-required`; and a form that accepts an empty submit had no errors to show, which is
not the same as failing to show them.

`undefined-classes.py` reports every class token in the views that the compiled stylesheet does
not define. A class nothing defines renders as nothing, and this is the only check that finds
one on a page no sweep visits.

```bash
python3 bin/design/undefined-classes.py
```

It sanity-checks its own extractor before reporting anything: Tailwind escapes `.` and `:` in
selectors (`.mt-0\.5`, `.focus\:ring-2`), and a regex that does not unescape them calls every
such utility undefined — the first version produced 186 findings, most of which were Tailwind
working correctly. It also separates deliberate hooks from orphans, because a class can be
meaningful without being styled: `filterrific-periodically-observed` and `form-inputs` belong
to gems and must stay.

`status.rb` reports which controllers render on a design system layout, resolving layout
inheritance.

```bash
ruby bin/design/status.rb
```
