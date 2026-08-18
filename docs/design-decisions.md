# Design decision log

Running log of UI decisions taken while bringing Human Essentials in line with
[`design.md`](../design.md). One entry per decision that **was not already answered by
`design.md`** — where the system was silent, the entry records what was chosen, what industry
practice it follows, and what was rejected.

`design.md` is the spec; this file is the changelog of how the spec grew. When a decision here
becomes a general rule, promote it into `design.md` and link back to the entry.

Format: date · area · decision · rationale · alternatives rejected.

---

## 2026-08-17 · Skip link markup and styling

**Decision.** Add `<a class="skip-link" href="#main-content">Skip to main content</a>` as the
first element inside `<body>` on the two application shells, targeting a
`<main id="main-content" tabindex="-1">` that wraps the yielded page content. Style it in
`custom.scss`: hidden off-screen at `top: -100%`, revealed at `top: 0` on `:focus`.

**Rationale.** WCAG 2.1 AA 2.4.1 (Bypass Blocks). Both shells put a 250px sidebar of 10–16 nav
links plus a navbar ahead of the page content, so a keyboard or screen-reader user tabs through
the entire navigation on every single page. This is the standard remedy and the first item in
`design.md`'s backlog.

**Alternatives rejected.**
- *Bootstrap's `.sr-only-focusable`* — it exists in the bundled Bootstrap 4 and would have been
  the zero-CSS option, but it reveals itself with `position: static`, which pushes the entire
  page down the moment the link takes focus. Absolute positioning is what GOV.UK, USWDS and the
  WAI skip-link pattern all use, precisely to avoid that reflow.
- *A brand-coloured focus ring.* The obvious pick was `$diaper-color-orange-51` (`#f39c12`), the
  app's warning amber, but it is **2.15:1** against white and fails WCAG 1.4.11 (non-text
  contrast, 3:1). The ring is `$diaper-color-neutral-13` (`#222222`) instead, at 15.9:1. Link
  text is `$diaper-color-blue-26` (`#005384`) at 8.06:1 on white.
- *`z-index` left to chance.* Set explicitly to 2000, above AdminLTE's fixed navbar (~1034) and
  sidebar (~1038), so the revealed link is never painted behind the chrome it exists to bypass.

## 2026-08-17 · No skip link on the authentication layout

**Decision.** `layouts/_devise_shared.html.erb` gets `lang`, the viewport fix and a `<main>`
landmark, but **no** skip link.

**Rationale.** 2.4.1 is about bypassing *blocks of content repeated across pages*. The auth
layout is a logo and a single form — there is nothing ahead of the content to skip, and a skip
link that jumps past nothing is noise for the exact users it is meant to serve. Matches how
Polaris, GOV.UK and USWDS scope skip links to pages with navigation.

## 2026-08-17 · `tabindex="-1"` on the skip target

**Decision.** The `<main>` that the skip link targets carries `tabindex="-1"`.

**Rationale.** Without it, Safari and several older browsers scroll to the fragment but leave
focus on the link, so the next Tab returns the user to the top of the navigation — the skip link
appears to do nothing. `tabindex="-1"` makes the element programmatically focusable without
adding it to the tab order. This is the documented WAI workaround.

## 2026-08-17 · One `<main>` per document

**Decision.** The `<main>` landmark lives in the layout. The two page-level `<main>` elements
that already existed (`partners/dashboards/show`, `partners/distributions/index`) were removed.

**Rationale.** Nested `<main>` is invalid HTML and produces two `main` landmarks, which is worse
for landmark navigation than having none. Putting it in the layout also means every page gets one
for free rather than 422 views each having to remember.

**Note.** `static/index` and `static/privacypolicy` render with `layout false`; they are
standalone documents and keep their own single `<main>`.

## 2026-08-17 · Viewport meta: remove the zoom lock outright

**Decision.** `width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no` becomes
`width=device-width, initial-scale=1` on all three live layouts.

**Rationale.** WCAG 1.4.4 (Resize Text) requires 200% zoom; `user-scalable=no` plus
`maximum-scale=1` blocks pinch-zoom entirely on mobile. This app is used on phones in warehouses
by people reading small numbers off dense tables, so the practical cost is real, not theoretical.
iOS has ignored `user-scalable=no` since Safari 10 anyway, so the attribute was mostly harming
Android users only.

**Alternative rejected.** Raising the cap to `maximum-scale=5` — still an arbitrary ceiling, and
there is no reason for this app to impose one.

## 2026-08-17 · `lang` bound to `I18n.locale`, not hardcoded

**Decision.** `<html lang="<%= I18n.locale %>">` rather than `<html lang="en">`.

**Rationale.** WCAG 3.1.1 (Language of Page). Hardcoding `en` is correct *today* — no locale
switching is wired up anywhere in the app (no `set_locale`, no `default_locale` override), so
every request runs at Rails' `:en` default. But the repo ships `es.yml`, `devise.es.yml` and
`simple_form.es.yml`, so Spanish support is half-built and someone will finish it. Binding to
`I18n.locale` renders `en` today and stays correct the day the switch lands, at zero cost.

**Follow-up noted, not actioned.** Those Spanish translations are currently unreachable. Either
wire up locale selection or delete them; leaving them is a trap for the next contributor.

---

# Ruby for Good design system migration (ADR 0011)

## 2026-08-17 · Build with `tailwindcss-rails`, not `cssbundling-rails` + npm

**Decision.** Tailwind v4 comes from the `tailwindcss-rails` gem's standalone CLI. The
reference implementation of this design system uses
`cssbundling-rails` with an npm `build:css` script; Human Essentials does not.

**Rationale.** This repo has no `package.json`, no `node_modules` and no Node anywhere in its
deploy path (`.cloud66`, `Procfile`). `docs/code_standards.md` is explicit that dependencies need
strong justification. The standalone CLI emits byte-identical Tailwind v4 output with no new
runtime, and `tailwindcss:build` already hooks `assets:precompile`, so deploys need no change.

**Consequence, stated plainly.** The two apps' asset pipelines are no longer copy-pasteable —
only their tokens and components are. That is the intended scope of a shared *design* system.

**Alternative rejected.** Matching the reference implementation's tooling exactly. It would
have meant adding Node to production
for one CSS build, which is a permanent operational cost paid for a one-time consistency win.

## 2026-08-17 · `config.assets.css_compressor = nil`

**Decision.** Turn off Sprockets' CSS compressor application-wide.

**Rationale.** `sassc-rails` defaults it to `:sass` in the test environment, and libsass cannot
parse what Tailwind v4 emits — `@layer`, `@property`, `oklch()`, `color-mix()`. The first request
for `tailwind.css` dies with `SassC::SyntaxError: Internal Error: Not enough space`. Nothing is
lost: the Tailwind CLI minifies its own output, and production has had this line commented out
for years, so only the test environment was applying it at all.

## 2026-08-17 · Data tables are component classes, not utility strings

**Decision.** `.data-table` and friends live in `@layer components` in `application.css`. Tables
are written `<table class="data-table">`, not with a dozen utilities per element.

**Rationale.** Composing tables from utilities is right at a few dozen pages. Human
Essentials has ~90 tables across 393 views. A twelve-class string repeated ninety times is a
copy-paste contract with no enforcement, and it drifts on the first hurried PR — which is exactly
how this codebase ended up with three CSS frameworks. A component class is one definition and
ninety call sites.

**Bonus, and the reason it is safe.** The column classes keep the names the app already uses:
`.numeric` and `.quantity` right-align, `.date` doesn't wrap. Those meant the same thing under
Bootstrap, so a migrated table carries its alignment semantics across instead of re-deciding
them cell by cell.

## 2026-08-17 · Sidebar groups collapse

**Decision.** Each middle nav group is a disclosure, closed by default, opening automatically
when it contains the current page, rather than all groups standing open under static labels.

**Rationale.** A flat rail is readable up to a dozen or so destinations. This one has **34**.
Always-open groups
would make the rail roughly three screens tall, so the pinned settings item and half the
destinations would sit below the fold on a laptop. Collapsing is also closer to what Human
Essentials users already have — the AdminLTE rail used `treeview` accordions — so the muscle
memory survives the reskin. Collapsible nav sections are standard at this density (GitLab, the
Azure and AWS consoles).

**With JS off every group renders open**, so the rail degrades to a plain list rather than to
nothing.

## 2026-08-17 · Information architecture is unchanged; "New X" items are not

**Decision.** The migrated rail has the same destinations, grouping and ordering as the AdminLTE
one. The only removals are the "New donation" / "New purchase" child items.

**Rationale.** Which items exist in the navigation is a product decision affecting 200+
organizations' muscle memory; a design system governs how they *look and behave*. Conflating the
two would smuggle a product change into a styling PR. Re-grouping the rail may well be worth
doing — it is a separate change with separate review.

The "New X" removals are the exception because they are a design-system rule rather than a
product change: a create action belongs on its index page as the primary CTA, where it sits next
to the thing it creates, not duplicated in the rail. Both destinations are one click from the
index.

## 2026-08-17 · `essentials_form_for` rather than per-call-site wrappers

**Decision.** Migrated forms use `essentials_form_for`, which applies `wrapper: :essentials` and
the wrapper mappings for you. The Bootstrap `simple_form` wrappers are untouched.

**Rationale.** The failure mode of forgetting `wrapper:` is silent and ugly: simple_form falls
back to the Bootstrap wrapper, which emits `form-group` and `form-control` markup onto a page
that loads no Bootstrap CSS, so the form renders as unstyled browser defaults. A helper that
cannot be called wrongly is better than a convention that must be remembered 57 times.

**Note.** The wrapper mappings are a constant in `EssentialsUiHelper`, not a method added to
`SimpleForm`. The first attempt monkeypatched the gem's module, which worked but put app
configuration somewhere no contributor would think to look.

## 2026-08-17 · Password visibility toggle is a real button

**Decision.** The show/hide password control on the sign-in form is a `<button type="button">`
with `aria-label`, not a `<span>` wrapping an icon.

**Rationale.** The original was a `<span class="toggle-password">` with a click handler: not
focusable, not operable by keyboard, and announced as nothing. This is a control, so it is a
button. The icon inside is `aria-hidden`, and the button carries the name.

## 2026-08-17 · Dropped the dead staging modal from the password reset page

**Decision.** `users/passwords/new` shipped a "Demo Site Reminder" Bootstrap modal gated on
`document.URL == "https://diaperbase.org/users/sign_in"`. Not migrated — deleted.

**Rationale.** The condition can never be true: it tests for the *sign-in* URL on the *password
reset* page, and on a domain the app no longer uses. The staging warning that actually works is
the one in `layouts/_devise_shared`, gated on `Rails.env.staging?`. Migrating dead code just
moves it.

## 2026-08-17 · UiHelper, IconHelper and FilterHelper were rewritten, not replaced

**Decision.** The three legacy view helpers keep their names, signatures and options
(`type:`, `size:`, Font Awesome icon names) and emit design system markup instead. They were
not deprecated in favour of the `essentials_*` helpers.

**Rationale.** Between them they have ~100 call sites. Replacing the API means touching all of
them in the same change that migrates the views, which is how a mechanical migration turns
into a rewrite. Mapping `type: "success"` onto `variant: :primary` and `fa fa-plus` onto
`bi-plus-lg` inside the helper keeps every existing call site working *and* meaning the same
thing, and leaves a single place to change later.

The mapping is deliberately lossy in one direction: AdminLTE had seven contextual colours and
the design system has four variants, so `info` and `warning` both land on `:secondary`. The
distinction they encoded was decorative — the button's label already said what it did.

## 2026-08-17 · An unavailable action is not a disabled link

**Decision.** `UiHelper#_link_to` with `enabled: false` renders a non-interactive `<span>`
carrying `aria-disabled="true"`, not an `<a class="disabled">`. Form actions render a real
`disabled` `<button>`.

**Rationale.** There is no such thing as a disabled link. `<a class="disabled">` is still in
the tab order, still activates on Enter, and announces as an ordinary link. Bootstrap's
`.disabled` only ever applied `pointer-events: none`, which does nothing for a keyboard user.
A `<button disabled>` is genuinely inert and announced as unavailable; where the action is a
navigation rather than a submission, the honest rendering is not a control at all.

## 2026-08-17 · The dialog controller lives on the app shell

**Decision.** `data-controller="dialog"` is on the shell layouts, and triggers name their
dialog with `data-dialog-id-param`.

**Rationale.** The alternative is scoping a controller element around each trigger *and* its
dialog. That works when they are adjacent and breaks as soon as the trigger is in a table row
and the dialog is at the end of the page — which is the common case here. One instance on the
shell resolves any dialog by id, and a trigger that names nothing is visibly wrong.

## 2026-08-17 · Third-party widgets get their accessible names added on top

**Decision.** Litepicker's month navigation buttons and FullCalendar's toolbar buttons are
given names after the widget renders — `nameMonthButtons()` on init/render/show, and
FullCalendar's `buttonHints` plus a fallback `aria-label` pass.

**Rationale.** Both ship buttons with no accessible name, and neither exposes a supported
option that fixes it completely. Patching the rendered output is ugly but it is the only lever
available short of replacing the widget, and a nameless button is a hard failure of WCAG 4.1.2.

## 2026-08-17 · Mechanical view transforms must match whole elements and assert balance

**Decision.** Any scripted edit across many views substitutes a *whole element* — opening tag,
content and closing tag — and asserts that tags still balance in each file before writing.
Substitutions that rebuild an entire `class="…"` attribute are banned.

**Rationale.** Learned three times in one session, each more expensive than the last. Changing
`<div>` to `<dl>` on the opening tag alone left `</div>`. Rewriting `<h3>` openers alone left
`</h3>`. Worst, a transform that rebuilt each class attribute from its tokens corrupted every
`class="<%= "p-5" if padded %>"` in the tree, because the regex stopped at the ERB's own quote
— and the "tidy up the whitespace afterwards" step that came with it reformatted 389 files.
Reverting was the only sane response.

The rule that holds: match whole elements, substitute tokens rather than attributes, never
"tidy" as a side effect, and check the diff is the size you expected before believing it.

## 2026-08-17 · Data tables and pagination are component classes

**Decision.** `.data-table` and `.pagination-link` are defined in `@layer components` rather
than composed from utilities at each call site.

**Rationale.** Composing tables from utilities is right at a few dozen pages.
This app has ~78 tables across 393 views and six kaminari partials. A twelve-class string
repeated 78 times is not a system, it is 78 opportunities to drift. The column semantics
(`.numeric`, `.quantity`, `.date`) additionally carry meaning the utilities cannot: they say
*why* a column is right-aligned, and they were already the names the app used.

## 2026-08-17 · System specs are part of the migration, not a follow-up

**Decision.** A migrated area is not done until its system specs pass.

**Rationale.** The request suite (941 examples) and a 39-page browser sweep both passed while
every one of the 21 dashboard system specs failed. Two different causes, neither visible to
the other checks: the specs asserted on copy and section ids the migration had changed, and —
far worse — they were all failing on a *stale precompiled bundle* in `public/assets` that
still imported `admin-lte`, throwing before any page rendered. Request specs never load JS and
the sweep ran against the dev server, so neither could see it.

If system specs fail with `Failed to resolve module specifier`, the answer is
`bin/rails assets:clobber assets:precompile`, not a change to the code.

## 2026-08-18 · The browser's clock has to follow Rails' clock in tests

**Decision.** The design system's `<head>` injects sinon's fake timer in the test
environment, initialised from `Time.now`, exactly as the AdminLTE layout did.

**Rationale.** It was dropped in the migration, and nothing failed loudly. `travel_to` moves
only Ruby's clock; anything computed in the browser — the reminder and deadline dates, for one
— stays on real time, so the two disagree by however far the spec travelled. The shared
example's own comment says "there isn't an easy way to spoof the current time in the test
browser". There is, and this was it.

## 2026-08-18 · Confirmations go through rails-ujs, not Turbo

**Decision.** Destructive actions carry `data-confirm`, not `data-turbo-confirm`.

**Rationale.** This app loads rails-ujs, and every spec drives confirmations with
`accept_confirm`, which needs a native `window.confirm`. Turbo only acts on its own attribute
where Turbo Drive is enabled, and `@turbo` is set per action here — so switching to
`data-turbo-confirm` quietly removed "are you sure?" from destructive actions on every page
with Turbo off.

## 2026-08-18 · Specs address behaviour and accessibility contracts, never styling

**Decision.** Where a spec named a Bootstrap class, it now names the thing that makes the
element what it is:

| Was | Is |
| --- | --- |
| `.alert`, `.alert-danger` | `[data-flash]`, `[data-flash-tone='danger']` |
| `.modal-content`, `.modal-title` | `dialog[open]`, `dialog[open] h2` |
| `button[data-bs-target='#x']` | `button[aria-controls='x']` |
| `#x.accordion-collapse.collapse` | `#x` with `visible: :hidden` |
| `a.btn.btn-success[href*='…']` | `a[href*='…']` |
| `have_button('X', class: 'disabled')` | `have_button('X', disabled: true)` |
| `.sidebar`, `.main-header` | `#essentials-sidebar`, `header` |

**Rationale.** Pinning the new class string would re-create the same brittleness against a
different framework. `aria-controls`, `aria-current`, `disabled` and `dialog[open]` are
contracts the app owes its users; a class name is an implementation detail. Where a hook was
genuinely needed and no semantic one existed — the flash's tone, a dashboard card's identity —
it is a `data-` attribute or an id, named for what it means.

## 2026-08-18 · Boolean partial locals need an explicit nil check

**Decision.** `remote = true if defined?(remote).nil? || remote.nil?`, never `remote ||= true`.

**Rationale.** `||=` cannot express "default true": it turns an explicitly passed `false` into
`true`. The admin barcode dialog passed `remote: false` and got a remote form, which submitted
over AJAX to an action with no JS response — the dialog just sat there.

## 2026-08-18 · A partial owns the elements it opens

**Decision.** A partial never closes a tag its caller opened, and never leaves one open for the
next partial to close.

**Rationale.** Three partner profile partials were written the AdminLTE way: close the parent's
wrappers, open the next card's. That left the document one `</div>` ahead, and the browser
resolved the mismatch by closing the `<form>` early — so the served-areas fieldset, the
remaining profile sections and the submit button all ended up outside the form. Nothing below
that point could be submitted, and "Add another county" did nothing because the Stimulus
controller could not see a template that was no longer in its subtree. The page looked fine.

## 2026-08-18 · A cold-start empty state does not repeat the header's button

**Decision.** The empty state's action says what it starts — "Record your first donation" —
rather than repeating the page header's "New donation".

**Rationale.** Eighteen index pages had the same label twice on the same page. That is ambiguous
for a reader deciding where to click, ambiguous for anything that clicks by name, and the
cold-start wording is better copy: it says this is the first one.

## 2026-08-18 · Stimulus actions read `currentTarget`

**Decision.** An action handler reads `event.currentTarget`, not `event.target`.

**Rationale.** `target` is whatever was clicked — the icon inside the button as often as the
button — and the icon carries none of the data attributes the handler needs. `currentTarget` is
always the element the action is bound to.

## 2026-08-18 · State is read from the DOM, not from a global flag

**Decision.** The date range field asks the calendar whether it is open (its computed display)
rather than reading `window.isLitepickerActive`.

**Rationale.** The flag is global and is cleared only by Litepicker's own `hide` event.
Navigate away with the calendar open and it stays true for the rest of the session, and the
field silently stops validating. A flag that outlives the thing it describes is a bug waiting
for the right order of events.

## 2026-08-18 · The documentation describes this app, not its lineage

**Decision.** No document explains a choice by comparison to the project this design system was
ported from. That now includes the ADRs.

**Rationale.** A specification should stand on its own: a reader shouldn't need a second
codebase to understand why tables are component classes here. The arguments survive the edit
intact — "a flat rail is readable up to a dozen destinations; this one has 34" says what the
comparison said, without the dependency.

**Revised.** I first exempted the ADRs, on the grounds that an ADR records why a decision was
made at a point in time and editing it falsifies the record. Asked again, I applied it there
too — but with an editorial note appended to ADR 0011 saying the text was edited and that the
decision itself is unchanged. That keeps the record honest, which was the real objection; the
wording was never the part worth protecting.

## 2026-08-18 · The four documents are maintained as part of the work

**Decision.** `design.md`, `docs/design-decisions.md`, `docs/migration-map.md` and
`docs/onboarding.md` are updated in the same change that makes them wrong, not afterwards.
Recorded in CLAUDE.md so it survives a change of author.

**Rationale.** Each of these already drifted once during this migration: design.md described
the Bootstrap system for a week after Bootstrap was deleted, and CLAUDE.md claimed `Discard`
was the deletion strategy when three models use it. A stale document is worse than no document,
because the next person trusts it and is wrong with confidence.

**Corollary.** Numbers in these documents are measured, not estimated. Every count in the four
was read off the code with `grep`, `bin/design/status.rb` or the specs — and two were wrong on
the first pass and corrected before the commit landed.
