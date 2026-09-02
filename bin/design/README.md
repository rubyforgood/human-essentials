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

`overlay-audit.js` also looks for **native browser confirms**, which is the one overlay no DOM
query can find.

`window.confirm` is browser chrome, not an element: this audit opens `<dialog>`s and reports
nothing, axe scans the document and has nothing to scan, and the system suite drives it with
Capybara's `accept_confirm`, **which only works on a native dialog** — so a green suite is evidence
*for* it. The same shape as the toastr message below the fold and the frozen-column shadow that drew
nothing: the assertion pins the thing that is wrong.

The only way to see one is to listen for the `dialog` event the browser raises, which is what
`checkNativeConfirms` does. Clicking is safe — the handler dismisses, so nothing is submitted. It
reports **2** today, both on `/transfers`, from the 44 `confirm:` call sites in the app.

`flash-of-hidden-audit.js` finds content that is **painted and then hidden by JavaScript**.

```bash
pw bin/design/flash-of-hidden-audit.js
```

It loads each page with `waitUntil: "commit"` -- before scripts run -- lists everything visible,
then lists it again once the page has settled, and reports what disappeared. A controller that
hides something in `connect()` has already let the reader see it.

Found the reported "ghost button that appears for a second" on `/distributions/new` (the shipping
cost field) and the same defect on `/manage/edit` (the reminder day fields). `<select>` is excluded
because select2 *replaces* one with its own container, which is a swap rather than a hide.

`disclosure-audit.js` checks every **conditionally revealed field** against the rule in design.md.

```bash
pw bin/design/disclosure-audit.js
```

Per reveal: it starts **below** the control that reveals it, **follows** it in the DOM so Tab
reaches it next, is **marked** with the indent and the 4px left rule, and **hangs 6px off** its
trigger's left edge -- which is the check that catches a field parked in a column of its own. It
exits non-zero on a defect.

Reveals are found by asking the page, not the source: anything a control points at with
`aria-controls`, plus the two pre-component target names, so a reveal that has *not* been migrated
still appears in the report rather than dropping out of it. A nested reveal is measured with its
whole ancestor chain un-hidden and then put back -- otherwise it measures 0x0 inside a collapsed
parent and reads as a defect that is not there. Two exemptions, both read from
`data-conditional-reveal` rather than guessed: a **table cell**, whose column *is* the
relationship, and a **plain** reveal, whose content already carries its own box.

Reported as "the location and size of the shipping cost field does not make any sense". Currently
**10 reveals, 0 defects**.

`template-compile-audit.rb` compiles **every view template**, and says which ones will not.

```bash
bin/rails runner bin/design/template-compile-audit.rb
```

One second, and it closes a gap four other checks left open. A sweep that rewrote 55 row actions
interpolated Python's `None` into one of them -- `icon: "bi-check-circle"None` in
`distributions/_pickup_day_row`. `erb_lint` passed, because the ERB *tags* are well formed and it
does not compile the Ruby inside them. `rubocop` passed, because it does not read templates. All
**3,159 specs** passed. And `/distributions/pickup_day` returned **200**, because Rails skips a
partial rendered through `collection:` when the collection is empty and never compiles it -- the page
500s the moment a pick-up exists for the day being looked at, which no spec sets up. Brakeman found
it, as a parse error under a heading nobody reads.

`spec/views/every_template_compiles_spec.rb` runs the same check in CI. Verified to fail: putting the
`None` back reports the file and the line.

A compiled template is a *method body*, so the source is wrapped before compiling -- `<%= yield %>`
is legal there, and treating "Invalid yield" at the top level as a defect reported four healthy
partials on the first run.

`citation-audit.py` classifies the **industry citations** in `design.md` and the decision log.

```bash
python3 bin/design/citation-audit.py          # the summary and the risky ones
python3 bin/design/citation-audit.py --list   # every claim
```

It cannot check whether a claim is *true* -- nothing here can browse. It finds claims whose **form
outruns the checking behind them**: naming an artefact (`OverflowMenu`, `slds-truncate`,
`<Table sticky />`) is evidence a reader can look up and disagree with; asserting that four systems
all do something, with nothing named, is not.

Written after a real error. design.md justified the selection bar covering the filter row with
"three of the four keep it in the toolbar", citing Carbon, Material, GitHub and Gmail -- and only
Carbon takes the filters away. The other three were counted as agreeing by describing them all as
"keeping it in the toolbar", which is true of the category and false of the specific behaviour.
**32 claims were in that form**; all are now evidenced, softened to "observed", or annotated.

```bash
python3 bin/design/citation-audit.py --check   # fails if the unevidenced count has grown
python3 bin/design/citation-audit.py --bless   # record the current count as the baseline
```

`--check` is the part that prevents a repeat. It holds a baseline in `citation-baseline.json` and
exits non-zero when the number of claims asserting agreement across four or more systems, with no
artefact named, goes **up**. It cannot tell whether a claim is true -- nothing here can open another
product -- but it can stop the count growing unnoticed. Verified to fail: adding one sentence of the
old form takes it from 2 to 3 and exits 1.

The two claims still counted are the proximity test's known limit, and it says so in its own output:
an absolute about *this app* ("every tab's controller goes in `active_on`") sitting within 90
characters of a system's name. Both are measured claims about our own code, which is where an
absolute belongs. The standard they are measured against is **"Citing another system"** in design.md.

`layout-shift-audit.js` scores **what moves after it is drawn**, on every screen.

```bash
pw bin/design/layout-shift-audit.js
pw bin/design/layout-shift-audit.js --width=390   # a phone, where tables stack into cards
```

It reads Chrome's own `layout-shift` performance entries -- the same ones Cumulative Layout Shift is
scored from, thresholds **0.1 good, 0.25 poor** -- and names the elements that moved. **Run it at a phone
width as well as a desktop one**: the biggest shift in the app was only visible at 390px, where
tables stack into cards. Shifts the
reader *caused* are excluded by the browser (`hadRecentInput`), so opening a disclosure or applying a
filter does not count; the dev-only profiler and Bullet badges are filtered out here, because they
are not in production and have fooled a DOM-reading audit on this project before.

Found three things no other audit could see: the historical trend charts at **CLS 0.352**, because an
empty container was inflated to 850px on connect; the donation form's four source selects, drawn and
then hidden for **100px** of reflow; and, at 390px, **six screens past "poor"** -- `/admin/base_items`
at **0.658** -- because tables were restacked into cards by JavaScript after paint. All three are
fixed; the worst score in the app is now **0.068** at 390 and **0.007** at 1400. The second was invisible to `flash-of-hidden-audit.js`
because that audit excused every `<select>` for select2's sake -- it now recognises the actual swap
instead.

`tab-set-audit.js` checks that a **set of page tabs behaves as one place**.

```bash
pw bin/design/tab-set-audit.js
```

Two invariants, neither of which any other check here asks about. **The strip does not move**: every
tab in a set puts its tab strip at the same height, so arriving somewhere does not shift the thing
you just clicked. **The rail still says where you are**: a tab living under a sidebar entry keeps
that entry marked and its group open.

Both were broken. Measured before: `/partners` at y=228 against `/partner_groups` at y=174, a 54px
jump, because the filter bar sat above the card holding the strip; and on `/partner_groups` and
`/item_categories` *no sidebar group was open at all*, because `active_on` named only the first
tab's controller. Currently **7 tabs across 3 sets, no findings** -- and verified to report the 54px
spread when a filter bar is moved back above its card.

`tooltip-audit.js` checks that an **icon-only control says what it is, the app's way**.

```bash
bin/rails runner bin/design/route-targets.rb > /tmp/targets.json
pw bin/design/tooltip-audit.js
```

Per control: it has an accessible name, it has `data-tooltip`, it has **no `title`** -- which would
draw the browser's own tooltip on top of ours a second later -- and the two strings agree. Then,
once in a real browser: the bubble appears on **keyboard focus**, is `aria-hidden` so the action is
not announced twice, and Escape dismisses it. None of that is visible to a class-name check, and the
keyboard case is the one `title` cannot do at all.

Two exclusions, both declared on the element rather than guessed at. The kebab trigger, because
`aria-haspopup` already identifies it and "More actions for <this row>" repeated down every row is
noise rather than help; and a chip's dismiss, marked `data-chip-dismiss`, because the label it
removes is right beside it.

**It used to read `main .cell-actions` on 25 hardcoded pages and report 0 defects while there were
14.** The rule is about an icon-only control, not about where one sits, so a funnel in a data cell
on `/events` was never looked at; and a hardcoded list goes stale in silence, so nine `/new` and
`/edit` forms with an untooltipped barcode-scan button were never visited. It reads the route
targets now, like `route-sweep.js` and `icon-audit.js`, and takes every control whose visible text
is empty. Currently **640 icon-only controls across 153 screens, 0 defects**.

`wcag-manual.js` covers the criteria axe cannot see, and has **two scopes**.

```bash
pw bin/design/wcag-manual.js          # expensive checks over a sample, cheap ones over all. ~40s
pw bin/design/wcag-manual.js --all    # every check over every screen, all three roles. ~4.5 min
```

Reflow, 200% zoom, text spacing and a full tab traverse each resize the viewport two or three
times, so they cost seconds per page where a title or a `lang` attribute costs milliseconds. The
default samples them; `--all` does not.

**Sampling is least defensible for exactly the expensive checks.** Reflow and text-spacing failures
come from one page's content -- a wide table, a long unbroken string -- so eight pages say almost
nothing about the other hundred and forty. Widening the *cheap* checks took 2.4.2 from "0 failures
on 8 pages" to **14 on 92**, and the first `--all` run found ten more on the admin and partner
screens that a single-role pass had never visited.

One definition of each check, with the scope as an argument: a second script for the thorough run
would be a copy, and a copy drifts.

`targets.js` is the seam between the audits and the application, and the only file that knows this
is a Rails app. It supplies the list of screens, the three roles, `signIn` and `visit`.

It replaced **21 hand-copied `signIn` functions**, seven copies of the role predicates and six of the
targets-file read. Four of the copies had drifted: one did not sign out first, so a second role
silently reused the first one's session, and one waited on `networkidle`, which never settles on the
slowest screens here.

The targets file regenerates itself when it is missing or older than `config/routes.rb`, so an audit
cannot quietly run against a stale list of screens. `TARGETS_CMD` overrides the command that builds
it — that one line is the whole Rails dependency.

`audit-selftest.js` tests the audits, by breaking a page on purpose and by leaving it alone on
purpose.

```bash
pw bin/design/audit-selftest.js
```

Two controls per check. **Positive**: the page is broken in the way the criterion is about, and the
check must report — this catches a check that examines nothing. **Negative**: the page is changed in
a way that is not a violation, and the check must stay silent.

**The negative control is the one that was missing.** Five checks reported failures the app did not
have, each of them "verified" by planting the defect it catches, and each of them passed that test:
a check that fires when it should not still fires when it should. All five would have been caught by
a benign control — a table that only just overflows, a region already scrolled, a longer page, an
`sr-only` label, a transitioned focus ring.

**It runs in CI on every push and pull request** — `.github/workflows/audit-selftest.yml`, the only
workflow that boots a real server and drives it with Playwright. Run it yourself before pushing a
change to a check; it takes eleven seconds.

The controls **build the structures they need** rather than relying on the page having them. They
first ran against a development database with a session's worth of data, where `/distributions`
overflows and grows a scroll rail; on a freshly seeded database it does not, `.table-rail-track` was
null, and half the controls threw. A self-test that depends on how much data happens to exist is not
a test — and in CI it would have been a red build about nothing.

Currently **11 controls over 5 checks, 0 wrong**.

`wcag22-audit.js` covers the **six criteria WCAG 2.2 added at A and AA**, five of which nothing
else here checked.

```bash
bin/rails runner bin/design/route-targets.rb > /tmp/targets.json
pw bin/design/wcag22-audit.js
```

2.4.11 Focus Not Obscured, 2.5.7 Dragging Movements, 3.2.6 Consistent Help, 3.3.7 Redundant Entry
and 3.3.8 Accessible Authentication. (2.5.8 Target Size, the sixth, was already a design system
rule.) `wcag-audit.js` runs axe against **2.1** and reported zero for months — accurately, against a
version of the standard superseded in October 2023.

On its first run it found **2.4.11 failing on five screens**: the scroll rail is fixed at the bottom
of the window, and the browser scrolls a newly focused element only far enough to touch that edge.

**Three of its own first findings were wrong**, and each is written up in the file so the mistake is
not repeated: a 2.5.7 click aimed at a fixed fraction of the rail landed on the thumb where the
thumb filled 95% of the track; 3.2.6 measured the help link's position as a *fraction* of the page's
focusables, so the same link on a long page and a short one looked like two places; and 3.3.7 was
listed in the header and printed in the pass line with **no check behind it at all**. Every check
here has since been proved to fire by planting the defect it is meant to catch.

`address-audit.js` checks that **every screen collecting an address asks for it the same way**.

```bash
bin/rails runner bin/design/route-targets.rb > /tmp/targets.json
pw bin/design/address-audit.js
```

Per field: the WCAG 1.3.5 `autocomplete` token for its role, a state chosen from a list rather than
typed, a ZIP as text with a numeric inputmode rather than `type="number"`, a label ending in the
app's word for that part, and an accessible name at all.

**Roles are read off the field's name, not from a list of screens**, so a form that adds an address
field is audited the day it is written -- the lesson from `tooltip-audit.js`, which carried a
hardcoded page list and reported zero while there were fourteen. It found two things a manual sweep
of the views had missed: a guardian ZIP on the family form, and a program ZIP still rendering as
`type="number"`.

`autocomplete="off"` is reported separately rather than failed: it declares an address belonging to
somebody other than the person filling the form in.

**A single freeform `address` input is a finding.** Four models stored an address that way until
2026-09-01 and none does now, so one appearing again means a form has gone back to the shape the app
moved away from. Currently **50 address fields, 0 findings**.

`row-actions-audit.js` reads a table's *actions column*, which no other check here asks about.

```bash
pw bin/design/row-actions-audit.js
```

`table-audit.js` checks the visual weight of a row action and how many badges a row carries. Both
can be perfect while the column itself is a mess: three buttons inline on one table and two behind a
kebab on the next, 349px of actions column on one page and 60px on another, and — the case that gets
reported — a column whose shape changes as you read *down* it, because the actions are picked by a
`case` on the row's status.

It reports three failures — `3+ inline, no menu`, `varies row to row`, `mixed control heights` —
and one **advisory**, `menu for 2 or fewer`.

**The advisory is advisory on purpose.** design.md collapses a table when three or more actions are
possible *or* when which actions exist depends on state. This reads one render of one seed, so it
sees the count and not the variance: `/items` builds Delete, Deactivate or a disabled Deactivate from
the item's state, and on seed data every row lands in the same branch. Reported as a failure it said
`/items` was wrong, and `/items` is right. Six tables sit in that bucket and all six are correct;
the `case` in the row partial is what settles it.

**It keys off the actions column header**, now that all 43 are the identical
`<th scope="col" class="text-right"><span class="sr-only">Actions</span></th>`. Reading the last cell
of every table instead treats a data cell of conditional links as a ragged actions column, which is
how `/events` — which has no actions at all — was reported as varying row to row.

**It counts the actions inside a closed menu, not just the visible ones.** The panel is in the DOM
while hidden, so it can be read without opening it — and without that a kebab row reads as "1
action", which made `/distributions` (three behind the menu, correct) indistinguishable from
`/items` (two behind the menu, which is the defect).

`wayfinding-audit.js` asks whether a screen can be **left**, not just reached.

```bash
pw bin/design/wayfinding-audit.js
```

Every screen, in three roles, must be one of: a link in the sidebar or top bar, a page carrying a
breadcrumb, or a page whose tabs link a sibling section. Anything else has exactly one way out --
the browser's back button -- and nothing else in this repo checks for that. It found ten, of which
five were the entire reports section: every report is reached from the hub, none is in the sidebar,
and none of them linked back.

It also reports a **destination in two navigation surfaces**. "Organization" sat in the sidebar's
pinned footer and in the account menu behind the identical gate. Neither entry looks wrong on its
own, which is precisely why it survived: every check the app has asks whether a page is reachable,
and none asked whether it is reachable *twice*.

Three things it had to learn, each of which produced a wrong answer first:

- **Judge the URL it landed on, not the one asked for.** Several sweep targets redirect, because
  `route-targets.rb` fills `:family_id` and friends with approximations. Comparing against the
  requested path reported `/partners/authorized_family_members/new` as orphaned when it had
  redirected to the families index, which is a nav root.
- **Page tabs count.** They are lateral rather than up, but a tab strip linking a sibling section is
  still a way out -- `/item_categories` and `/partner_groups` are reached and left that way.
- **Signed-out and standalone screens are excluded**, listed with reasons at the top of the file:
  the landing page, the legal documents (`layout false`), the account-request flow and Devise's
  invitation acceptance have no app chrome for a breadcrumb to sit in.

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

`serve-mockup` puts a design preview somewhere the person reviewing it can actually open.

```bash
bin/design/serve-mockup request-units
# => http://localhost:3000/request-units.html
bin/design/serve-mockup                  # lists all 44
```

Mockups are written self-contained so they open by double-clicking, and **that is not enough**:
when the app runs in a container or behind a tunnel, the reviewer's browser reaches the dev server
and nothing else, so a `file:///` path shows them nothing. Three previews have been unviewable for
this reason. The script copies the mockup into `public/`, where Rails serves it ahead of the router,
refreshes `mockup.css` for the older ones that link it, warns if the served copy is not gitignored,
and prints the URL to send.

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
