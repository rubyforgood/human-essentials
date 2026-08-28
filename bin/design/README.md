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

`route-sweep.js` does the same checks across **every HTML screen the router knows about** — 142
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

A 404 from `route-sweep.js` is listed separately from the design findings rather than mixed in
with them. It used to mean a route with no action behind it — `resources :x` generates seven and
most controllers implement four — and 13 of the sweep's targets were that. They are gone; use
`dead-routes.rb` for that question now. What is left in the bucket is the sweep's own
approximations: a path whose `:partner_id` was filled with a user's id, and two records the role
being used cannot see.

`page-audit.rb` reads the templates rather than rendering them, and is the only audit here that
needs neither a browser nor a server. It reports two severities — a DEFECT is wrong now (a class
nothing defines, an inline style, layout built from `&nbsp;`, Title Case in a heading, a page
with an `<h1>` and no `page_header`), and DEBT renders correctly but has a component's classes
pasted inline, so a change to the component will never reach it. It exits non-zero on a defect
and reports debt without enforcing it.

```bash
bin/rails runner bin/design/page-audit.rb          # all kinds
bin/rails runner bin/design/page-audit.rb action   # one kind
```

**Five kinds, and the fifth is a catch-all on purpose.** `show`, `index`, `form` and `partial`
are the RESTful shapes; `action` is everything else, which means a template named after a
collection action — `items/inventory.html.erb` — cannot fall out of the audit by being named
oddly. It could before: those four patterns were treated as exhaustive, and 25 views matched
none of them and were scanned by nothing. Adding the catch-all also surfaced that the mailer
exclusion knew about `*_mailer/` but not Devise's `users/mailer/`, so six HTML emails were being
audited as app pages.

**The hand-rolled card check matches a surface, not a string.** A card is white, hairline
border, `rounded-2xl`, `shadow-sm`; the check looks for those four tokens inside one `class`
attribute, in any order. It used to compare against the exact
`rounded-2xl border border-slate-200 bg-white shadow-sm` substring **and** skip any file that
also rendered `shared/essentials/card` — two holes that between them hid every hand-rolled card
in the app. One padding utility (`bg-white p-4 shadow-sm`) defeats a substring, and a file can
render the component properly in one place and paste it in another.

It is **not** a per-kind check. It sweeps `app/views`, `app/helpers`, `app/javascript` and
`app/components`, including `shared/essentials/`, because the last two copies were in exactly the
places the per-kind scan cannot reach: `essentials_stats` is a helper, and `_disclosure` is a
design system partial that every other check skips as "the definition, not a copy". Since
`.card-surface` exists there is no definition left to protect — the component uses the class like
everybody else. It reports 0, and the remedy for a finding is always the same: use the class.

**A second sweep asks the same question of the icon tile.** A tone-coloured, fixed-size rounded
box that is not `rounded-full` should have come from `essentials_icon_tile`. `rounded-full` is the
whole discriminator, and it is doing real work: a circle is an avatar or a numbered step badge,
which design.md keeps deliberately disjoint from tiles, and both appear in the app. The reports
hub was the one copy, and it had drifted on size, radius *and* text colour — 28px/`rounded-lg`/
`text-brand-700` against the helper's 36px/`rounded-xl`/`text-brand-600` — which is what a single
hand-rolled component looks like after a while. The helper takes `size: :sm` now and the hub uses
it.

The bare-`card` check moved from `/class="[^"]*\bcard\b[^"]*"/` to a class-token split at the same
time. `\b` does not stop at a hyphen, so that pattern matched inside `card-surface`,
`content-card` and `data-card` — harmless while nothing legitimate contained the substring, and
then every card in the app reported as a dead Bootstrap class the moment one did.

**How to test it.** The script proves the detector before it reports anything, the same way
`undefined-classes.py` proves its extractor: a table of markup fragments with expected answers,
including the padding-interleaved case that used to slip through and a split-across-two-elements
case that must *not* match. Break the detector and the script refuses to run —

```
card detector is wrong: "<div class=\"…bg-white p-4 shadow-sm\">" => false, expected true.
Fix it before trusting any result below.
```

and exits 1 without printing a report, because a check that silently reports zero is the failure
mode that looks like success. To exercise it end to end, add
`<div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">` to any view and
re-run: that file should appear under `debt`. Debt does not change the exit code — only defects
do.

`shell-first-audit.rb` asks the question none of the others do. Every audit above answers *is
anything from the old system still present?* This one answers *is this built the way the new system
builds things?* — which is what a **shell-first** page fails: page header, card, no Bootstrap class,
no console error, and inside the card a body nobody migrated.

```bash
ruby bin/design/shell-first-audit.rb
```

No browser, no server, no database; it reads the templates. Eight checks: a `<table>` that is not
`.data-table`, a bare `<hr>`, `float-*`, a `<br>` standing in for a margin, four or more flat `<p>`
label pairs where a `<dl>` belongs, a hand-written card header, button classes pasted inline, and a
Font Awesome icon. Exits non-zero on any finding.

**Read the narrowings before adding a check**, because four of these eight started as false-positive
factories and the reasons are the useful part. Mailers and `static/` are skipped — HTML email needs
tables, and the legal pages are standalone documents with their own `<style>`. A `<br>` inside an
`<address>` is correct HTML, so only a doubled one or one right after a block closes counts;
unnarrowed it reported 31 and 29 were fine. A detail pair must carry `font-medium` and there must be
four, or a stat card's caption matches. And a hand-written card header only counts when the file
actually contains a card, because a modal's header is the same markup — matching markup alone
reported all fourteen modals in the app, and three of those keep their `<dialog>` in
`confirmation_controller.js`, so no amount of looking for `<dialog>` would have helped.

It proves its detectors against a probe table first and aborts if one is wrong, the same as
`page-audit.rb` and `copy-audit.rb`. That caught its own first bug: `'\n'` in a single-quoted Ruby
string is two characters, so the card-header probe failed before the audit could report a false zero.

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

`dead-routes.rb` needs no browser and no server. It asks of every route whether the request
would raise, and exits non-zero if any would.

```bash
bin/rails runner bin/design/dead-routes.rb
```

It decides with `recognize_path` rather than by reading each route's own controller and action,
because another route can answer first — `POST /users` looks dead, and Devise handles it. When
recognition raises, which it does for a route behind a constraint that needs a real request, it
falls back to the declared target instead of skipping: skipping is how the first version lost
`/partners/donations`, a dead route that had already been found by eye.

It reports **shadowed** routes separately: declared, but another route answers that path first.
That is a different defect with the same symptom — `/requests/partner_requests` resolved to
`requests#show` with an id of `"partner_requests"`, because a second `resources :requests`
declared a collection route below the first one's `/requests/:id`.

`dead-code.rb` asks the opposite question to `dead-routes.rb`: not routes with no code behind
them, but code with nothing in front of it — no route, no render, no caller.

```bash
bin/rails runner bin/design/dead-code.rb
```

It covers controllers, actions, templates, partials, helper methods, services, queries, jobs,
mailers, events, concerns, Stimulus controllers, importmap pins and `public/`. **Read the
exemptions at the top of the file before adding a check.** There are thirteen and every one is a
false positive that was reported, investigated and disproved — including the one that would have
recommended deleting Figtree and Bootstrap Icons, which are named only by `@font-face` in the
stylesheet and by nothing in Ruby or ERB.

Its findings are a list to work through, not a build failure. It exits non-zero anyway, so wire
it into anything at your own risk.

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

It proves its own extractor before reporting anything: Tailwind escapes `.` and `:` in
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

`copy-audit.rb` reads the app's *words* and checks the things axe cannot: link text that says
nothing out of context (WCAG 2.4.4), instructions that depend on position (WCAG 1.3.3), gendered
and ableist wording, "please", and all-capital shouting.

```bash
ruby bin/design/copy-audit.rb
ruby bin/design/copy-audit.rb --verbose
```

It reads **copy**, not source, and it distinguishes a **link** from a **heading** — both of which
it had to learn. A grep cannot tell a sentence from an identifier: the first `he/she` pattern
matched `render "organizations/header"`. And WCAG 2.4.4 is about link labels alone, so run over
all copy the vague-text check reported all sixteen cards titled "Details", which are headings and
perfectly fine. A short label carrying an `aria-label` that extends it is treated as named, which
is the WCAG 2.5.3 way of keeping a compact visible label — and that exemption is itself probed,
because it would otherwise be a hole.

Its probe table caught a bug review would not have: in a Ruby `/x` regex literal spaces are
stripped, so `VAGUE_LINK` was quietly looking for `clickhere`. Every multi-word branch now uses
`\s+`, and every branch has a probe. Break any check and the script refuses to run.
