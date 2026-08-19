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

## 2026-08-18 · Onboarding is one document with two halves, not two documents

A contributor and a bank user need the same vocabulary. A distribution is not one thing to a
developer and another to a warehouse manager, and the moment there are two glossaries they
start to disagree — usually within a release.

So `docs/onboarding.md` is one file: part 1 for maintainers, part 2 for users, with a table of
contents at the top that sends you to yours. The user half is deliberately about words rather
than buttons — why a request and a distribution are separate records, what a product drive is
if it is not an intake, why an audit exists when adjustments already do. Buttons change; those
distinctions have not.

## 2026-08-18 · The change log is separate from the decision log

They were nearly merged. They answer different questions, and the questions arrive at different
moments:

- *Why is it like this?* — the decision log, read when you are about to change something.
- *When did it change, and what do I blame?* — the change log, read when something behaves
  differently from last week.

Merging them means every "when" question has to be answered by scanning reasoning, and every
"why" question by scanning dates. `docs/changelog.md` is built from the commit history so it
cannot drift from what actually happened.

## 2026-08-18 · Grep for undefined classes is a first-class check, not a fallback

The migration had two verification tools, and both missed a real defect. `bin/design/status.rb`
asks whether a view contains design system markup — the bank-side profile editor contained
plenty while still passing `fa-edit` into a partial. `bin/design/sweep.js` visits 56 pages in a
browser, and that page is not one of them.

What found it was grepping for classes nothing defines any more. That check is now written into
the verification list in both `design.md` and the migration map, ahead of the tooling rather
than after it. The general point: a tool that asks "does this look migrated?" cannot answer
"is anything here dead?", and the second question is the one that finds defects.

## 2026-08-18 · Inert leftovers get named, not silently left

`class: 'form-horizontal'` survives on 12 forms. It renders nothing — Bootstrap 5 had already
dropped it, so it did nothing before this work either.

Removing it means editing option hashes rather than substituting a token, and that class of
edit has already corrupted markup once on this branch. So it stays, and it is written down in
the migration map as a known inert leftover. The alternative is that someone finds it in a year,
cannot tell whether it matters, and either breaks something removing it or leaves it and
wonders. Naming a thing you chose not to do is cheaper than either.

## 2026-08-18 · One weight for every row action, including destructive ones

Audited all 27 index tables: 17 use `:ghost` throughout, 7 mix weights.
[table-audit.md](table-audit.md) has the measurements.

The rejected alternative was the intuitive one — emphasise the most important action in each
row. It does not survive contact with a real table. On the partner list "Review profile" is
bordered and "Request recertification" is not, but each is the main thing to do for its own row,
so the emphasis is really tracking which action it is, not how much it matters. Read down the
column, the highlight jumps around for no reason the reader can infer.

Destructive actions stay `:ghost` as well, tinted rose. A filled red button in every row trains
people to ignore red, and the confirmation dialog is what actually protects them.

The reason six of the seven deviate is not a style choice: they still call the legacy
`edit_button_to` / `delete_button_to` shims, which map onto `:primary` and `:danger` because
that is what those names meant under AdminLTE. The helper cannot tell a page header from a
table row, so the call site has to.

## 2026-08-18 · Badge the exception, never the norm

Twelve tables badge only the exceptional state — "Inactive", "Expired", "Below minimum" —
attached to the name rather than given a column. Five badge every row. The twelve are right.

A column where every row carries a badge has spent colour on information the reader already
has: they can see it is a list of partners, and "Approved" on most rows tells them nothing. The
cost is not neutral, because the eye learns to skip a column that is always the same, and the
exceptions go with it. The badge that matters is the one in a column that is usually empty.

Left alone deliberately: `/partners` genuinely has six states with no obvious default, so a
status column earns its place there even though every row is badged. What does not earn its
place is badging it *twice* — see the next entry.

## 2026-08-18 · A filter chip must not be built from the status palette

`partners/_statuses.html.erb` builds its filter strip out of `EssentialsUiHelper::PILL_TONES` —
the status palette itself. So the partner list shows 13 pills on a seeded org: seven that filter
the list when clicked, six that report a row's state and do nothing. Same shape, same size, same
colours.

design.md has said since the migration that a pill is "a state, not a control: not focusable,
does not look pressable". Half of these are links. Nothing about them says which half.

This is recorded as a defect rather than fixed in the same breath, because the fix is a visual
change to the busiest screen a bank user has and it should be someone's decision, not a
side-effect of an audit. The options, in preference order: give the chips a control treatment
(bordered, neutral until selected) and keep the status column; or keep the chips and drop the
status column, since the strip already communicates the same six states.

## 2026-08-18 · Filter with the shared filter bar, not with status chips

The partner list filtered with a strip of coloured chips. Two of them — the statuses with no
partners — rendered as greyed, non-interactive spans, which is a disabled control in everything
but name, and design.md rejects those: "a link cannot be disabled".

The obvious fix was to restyle the chips. The right fix was to notice that this app answered
the question fifteen times already. **Fifteen index pages filter with
`shared/essentials/filter_bar`** — a labelled select, a Filter button, Clear filters. Exactly
one page used chips. `/requests` filters by a status enum with a plain select and always has.

So the chips went. The disabled-control problem does not need solving; it needs deleting,
because a select has no notion of a control you can see but not use. A status with no partners
is an ordinary option that yields the "No partners match that status" empty state the app
already renders — honest, and reachable by keyboard like everything else.

The counts moved into the option labels — `Awaiting review (1)` — which is where a count belongs
when it describes the thing you are about to pick. `filter_select` gained an `include_blank:`
label so the unfiltered option can say `Active (6)` rather than being an unexplained empty row.

What is lost is the at-a-glance count of every status without opening the select. That is
acceptable because it was never this page's job: `dashboard/_partner_approvals` already lists
partners awaiting review, with a button. The chips were doing the dashboard's work on a page
whose work is to be a list.

Rejected: keeping chips but hiding the zero-count ones. It removes the rule violation and keeps
the inconsistency, and it makes the strip change width as data changes, so the control you
reached for last time is somewhere else today.

## 2026-08-18 · A submitted-but-blank filter is not a filter

Replacing the partner chips with a select introduced a bug that the chips could not have had.
The first option is "Active", and a select's blank option submits `by_status=""` rather than
omitting the parameter. `PartnersController#index` branched on `filter_params.empty?`, which is
false for `{by_status: ""}`, so it called `class_filter` — and `Filterable#class_filter` skips
blank values, leaving `where(nil)`. Choosing "Active" therefore returned *every* partner,
deactivated ones included: the option showed more than its label promised.

It was invisible in development because the seeded organization has no deactivated partners, so
`.active` and "everything" are the same six rows. A request spec with one deactivated partner
shows it immediately, and that spec is now checked in.

The fix is in the controller, not the helper: `filter_params.to_h.compact_blank`, so an
all-blank filter set means the default view. Doing it in `class_filter` would have changed
behaviour for the fifteen other pages that use it, and doing it in `filter_select` would leave
the next controller to rediscover the same thing.

The general point, which is why this is written down rather than just fixed: a link that is
absent submits nothing, a select that is unset submits an empty string. Swapping one control for
another silently changes what arrives at the controller, and the seed data was too tidy to show
it.

## 2026-08-18 · Apply on change when there is one filter, keep the button when there are several

Asked whether the Filter button was necessary. It depends on how many filters the bar has, and
this app has both shapes: four index pages filter on a single control, twelve filter on between
two and nine — `/donations` has nine.

With one control the button is pure friction: you have already said what you want, and the
button makes you say it twice. With nine, applying on every change fires a query per control
while the user is still assembling the question, and each one throws away the scroll position.

So `auto_submit:` is a per-bar option rather than a global behaviour, and the four single-filter
pages take it. Two of those four filter on a checkbox, which is the clearest case of all: a
checkbox behind an Apply button is a switch that does not switch anything.

The button stays in the markup and is hidden by Stimulus on connect, so the form still works
without JavaScript. It is hidden with an inline `display:none`, not the `hidden` utility: the
button already carries `inline-flex`, and two Tailwind utilities setting `display` resolve by
stylesheet order rather than class order, so `hidden` lost and the button stayed visible. That
was caught by reading the computed style rather than the class list, which is the only way to
catch it.

## 2026-08-18 · "All" is an option, not a Clear button — and it is not the same as the default

Asked whether an "All" option could replace "Clear filters". Yes, and it turned out to be two
separate improvements.

"Clear filters" next to a single select is redundant: the select's first option *is* the reset,
so choosing it clears the filter. Offering two ways to undo one thing means the user has to work
out whether they differ. Single-filter bars now pass `clear: false`.

Separately, the partner list's default view is not "everything" — it hides deactivated partners.
So the first option is `Active (6)` and there is now also `All (7)`, which is a capability the
page did not have: you could see active partners, or deactivated ones, but never both in one
list. That needed a sentinel value in the controller, because "all" is not a Partner status and
has to bypass the default scope rather than be passed to it.

## 2026-08-18 · Drop the icon from a pill that appears on every row

The partner status column carried an icon on all six rows. Two problems, one reported and one
found while fixing it.

Reported: it reads as busy. The icon is decorative — `aria-hidden`, with the word beside it
doing the work — so six of them are six pieces of noise in a column that is already colour-coded.
Icons stay on pills that mark an exception, "Inactive" and "Expired", where they appear on one
row in twenty and help it stand out.

Found: "Recertification required" was wrapping to two lines, and a wrapped pill centres its icon
across both lines, so the icon sat between them looking misaligned. The icon was part of what
pushed it over the width. Pills now carry `whitespace-nowrap` regardless, because a pill is a
label and a label that reflows is a layout accident, not a design.

## 2026-08-18 · Order the status filter by lifecycle, not alphabetically

Asked whether the dropdown should be alphabetical. No — and the reason generalises.

Alphabetical order helps when a list is long and its values have no inherent sequence: countries,
partners, item names. You arrive knowing the label and need to find it. A status enum is the
opposite: six values, and they happen in an order. Uninvited, invited, awaiting review, approved,
recertification required, deactivated is the path a partner actually walks. Alphabetising it
gives approved, awaiting review, deactivated, invited, recertification required, uninvited, which
scatters the sequence and puts the end state third. GitHub, Jira and Linear all keep workflow
states in workflow order for the same reason.

The order is the enum's own declaration order, so the filter cannot drift from the model.

What was wrong was not the order but that three kinds of option sat in one flat list, so "All"
and "Approved" looked like peers. They are now separated with an `<optgroup>`: the default view
and the whole collection at the top, then "By status" over the six. `filter_grouped_select` is
the helper for this shape.

## 2026-08-18 · Hide a progressively-enhanced control in the markup, not on connect

The Filter button flashed on every page load and, because auto-submit navigates, on every
selection. It was rendered visible and hidden by Stimulus on connect, so the browser painted it
and took it away a frame later.

Hiding it server-side with an inline `display:none` and restoring it from a `<noscript>` rule
inverts the default: it is hidden unless JavaScript is *absent*, rather than visible until
JavaScript arrives. Same behaviour without JavaScript, no flash with it.

The general rule: if a control's resting state depends on JavaScript being present, render the
resting state and let `<noscript>` undo it. Anything a controller does on connect happens after
first paint, and the user sees it.

## 2026-08-18 · Known flake: DonationSite CSV export specs query globally

`spec/models/donation_site_spec.rb` asserts on `DonationSite.active` with no organization scope
and then indexes the result positionally (`csv_data.first`, `.second`). Any other spec that
leaves a donation site behind breaks it, and nothing pins the order.

It fails on `--seed 57005` in a full run and passes in isolation on the same seed. Verified
pre-existing: it fails identically on the design branch without any of the filter work, and the
file is untouched by it. Recorded rather than fixed because it belongs to a different piece of
work, and a flake that is written down costs the next person minutes instead of an afternoon.

## 2026-08-18 · No optgroup in the status filter, and labels that state their rule

Asked what rules sort records into "Active" and "All", whether "By status" was a subsection of
them, and whether the optgroup label met contrast requirements. Three questions, one cause.

The rules, which nothing on screen was saying:

| Option | Rule |
| --- | --- |
| Active | `where.not(status: :deactivated)` — five of the six statuses |
| All | no scope — all six |
| A named status | exactly that one |

So the six are **not** a subsection of either. Five of them sit inside Active; the sixth,
Deactivated, only inside All. The `<optgroup>` labelled "By status" asserted a hierarchy that
does not exist, which is why the question came up. It is gone.

On contrast: the optgroup computes to slate-900 on white, 17.9:1, so it passes on paper. That
measurement is worth little, because the options list is drawn by the platform rather than by
this stylesheet — macOS renders optgroup labels in its own grey, near enough slate-400 at 2.6:1,
and no CSS here changes it. A control whose contrast is not ours to set is a control we cannot
promise anything about, which is a second reason to avoid optgroup rather than restyle it.

What replaced it is labels that carry their own rule: "Active — all but deactivated (6)" and
"All statuses (7)", flat, with the six statuses under them in lifecycle order. Longer labels,
no hierarchy to misread, and nothing whose rendering we do not control.

## 2026-08-18 · Empty-state copy names a control, so it goes stale when the control does

"Clear the filter to see everyone" survived the removal of the Clear filters button by three
commits. The instruction was still true in spirit and impossible to follow literally.

Both affected pages now name the option that does the job — "Choose 'All statuses' to see every
partner agency" — which meant giving the audits filter a labelled blank option ("All storage
locations") so there was something to name. That is an improvement anyway: an unexplained empty
first option is a worse control than a named one.

The rule this suggests: copy that names a control is coupled to that control. When a control is
removed, grep the views for its label before assuming the change is done. The twelve pages that
still have a Clear filters button keep the old wording, correctly.

## 2026-08-18 · Short option labels, rules in hint text

"Active — all but deactivated (6)" stated the rule but was the wrong shape for an option label,
and it leaned on an em dash to hold two clauses together.

The ordinary advice across GOV.UK, Polaris and Material is the same: option labels are short
noun phrases, and anything that needs explaining goes in hint text under the control. Two
reasons, and the second is the one that decided it here:

1. An explanation inside an option is re-read on every open, once per option.
2. It is invisible while the list is closed — which is precisely when someone looks at
   "Active (6)" and wonders what it excludes.

So: `Active (6)` and `All statuses (6)`, with hint text underneath reading "Active hides
deactivated partner agencies. All statuses includes them." That sentence is visible without
opening anything, and `aria-describedby` ties it to the select so it is announced with the
control rather than stranded after it.

The hint uses the meta token design.md already defines, `text-xs text-slate-500` — 4.8:1 on
white, which clears AA — and matches the hint styling simple_form applies on every form in the
app, so this is not a new visual idea.

## 2026-08-18 · Icons mark the top level of the sidebar, and only the top level

Reported: the Dashboard item had no icon while the four group headers did, so the top level
looked half-finished.

Two ways to fix that, and the cheap one is wrong. Giving every destination an icon means 34
more glyphs in a 256px rail, in a second column beside the group icons, and once everything is
marked nothing is. The rule instead is that an icon marks a *level*: standalone items, group
headers and the pinned item carry one; items inside a group do not, and are indented instead.

That also settled the other two rails, which are flat and therefore all top level: the admin
rail's ten items and the partner rail's seven all took icons. Before this, only the partner
Dashboard had one, which was the same inconsistency in a smaller rail.

`NavItem` gained an optional `icon:` with a default of nil, so the ~34 sub-items did not have to
change at all.

## 2026-08-18 · Sentence case in the sidebar, including group headers

The four group headers were `uppercase tracking-wide`. design.md has listed nav items under
sentence case since the migration, so this was the app breaking its own rule in the most visible
place it has.

Uppercase micro-type is a real convention, for a *static* section label — a caption over a list.
These are buttons: they collapse, they take focus, they are the same size as the destinations
under them. Styling an interactive control as a caption is the mismatch, and uppercase also
strips word shape, which is exactly what someone scans a rail by.

They are now `text-sm font-semibold text-slate-700` — a peer of the items rather than a caption
over them, distinguished by the icon and chevron instead of by case.

## 2026-08-18 · One glyph, one meaning

The user guide link used `bi-question-circle`, and it read as a warning rather than an offer of
help. That is not a matter of taste: a circled question mark is what this app puts on
"awaiting review", the status that means someone has to act. The same shape cannot mean "you
have a problem" in a table and "here is some help" in the top bar.

The user guide is a book. In-app help is a life ring. Neither collides with a status glyph.

While fixing it: `ESSENTIALS_PARTNER_STATUS` still carried an `icon:` for each status, dead
since the pill stopped rendering one. Removed rather than left, because a dead icon name in a
status map is exactly the sort of thing the next person builds on.

## 2026-08-18 · Fifteen reports become a hub with one rail entry

The Reporting group held 15 of the sidebar's 34 destinations; Operations, Inventory and Network
held 5, 7 and 7. Twelve of the fifteen turned out to be a sparse grid — distributions, donations,
purchases, product drives and requests, each cut as a summary, an itemised breakdown or a
twelve-month trend. The remaining three (activity graph, annual survey, history) belong to no
subject.

A flat list cannot express a grid, and the labels had been compensating: "Distributions —
summary" encoded the grid in the string so the entries at least sorted together. That naming was
a symptom, and it is why the em dashes were there.

So the grid became the layout. One rail entry, "Reports", leading to a hub that groups by
subject and names each report for its cut — under **Distributions**: Summary, Itemized, Trends,
By county. The em dashes are gone as a side effect rather than as an edit.

Costs one click per report. That is only acceptable because reports are periodic — monthly and
annual funder reporting — rather than daily like distributions. **This is an assumption, not a
measurement**, and it is the thing to check with a real bank before treating the hub as settled.
If some report is genuinely a daily habit, it should be promoted back into the rail beside
Dashboard rather than the hub being abandoned.

Deliberately not done in this stage: collapsing the grid itself, so that "Distributions —
summary" and "Distributions — itemized" become one page with a view switcher. It is the
structurally correct end state and a real refactor of twelve pages; the hub proves the grouping
first.

Two judgement calls inside it:

- **Annual survey stays on the hub**, not in the rail, though it is high-stakes for NDBN member
  banks. Permanent rail space is the wrong tool for an annual deadline; a dashboard prompt when
  the filing window opens is the right one, and is not built.
- **History is not a report.** It is the inventory event log, and it sat under Reporting because
  there was nowhere else. It is on the hub under "Everything else" and labelled as an audit
  trail rather than pretending the hub resolved it.

`active_on` for the rail entry lists every controller that renders a report, so the entry stays
current while you are inside one. Without that the rail would say you are nowhere, which is
worse than the group was.

## 2026-08-18 · Uniform cards need a uniform unit

The hub grouped the fifteen reports into six section cards. Cards ran 143px to 378px, because
sections hold between one and four reports, and that was reported as cards that should be the
same size.

Pairing sections by size and stretching got each *row* equal — 4 with 4, 3 with 2, 1 with 1 —
but rows still differed from each other, and no arrangement fixes that while the card is a
variable-length list. Forcing all six to the tallest would have put 235px of dead space under
the one-report sections.

So the unit of the card changed: fifteen tiles, one per report, each holding a name and a
sentence. Content that repeats uniformly makes cards that are uniform. `auto-rows-fr` equalises
rows within a section and a shared `min-h` equalises across sections; measured equal at every
breakpoint from 420px to 1600px.

The general rule, now in design.md: if cards must be equal, make the unit of the card the thing
that repeats. Grouping stays, as headings above each grid, which costs nothing.

## 2026-08-18 · A statistic is not a heading

The summary reports marked their figures up as `<h2>` — six consecutive ones on the purchases
report, each carrying its own label inside the heading text ("Total spent on diapers: $412").
Someone navigating by heading heard the page's statistics as its document structure.

The visual hierarchy ran opposite to the semantic one as well: the largest text on the page was
a `<p>` at `text-2xl font-bold`, while every actual heading was `text-base`. So the markup said
"heading" where the design said "data", and the design said "prominent" where the markup said
"paragraph".

`essentials_stats` renders a description list, which is the real relationship — the label
describes the value. The `<h2>`s that remain are the ones that name a section, "Recent
purchases", which is what a heading is for.

Found in the same pass and fixed: an empty `<h2></h2>` on the activity graph, a stray
`</section>` closing nothing on the donations report, two `style="margin: 40px"` attributes, and
`gradient:`, `footer_options:` and `type:` passed to a partial that has never read any of them.
That last one is AdminLTE vocabulary that outlived the markup.

## 2026-08-18 · A drill-through link names its destination

Every summary report ended in "See more…", which led to the index table for that record type.
From the distributions *report* to the distributions *table*: a different page, about different
things, reached by a link that says neither.

They now say "View all distributions", "View all purchases", and so on. The pattern itself is
fine and common — a report shows a preview and offers the full list — but "see more" implies
more of what you are looking at, and this is not that.

## 2026-08-18 · Four summary reports removed; their figures moved onto the index pages

Asked why summaries have their own page, and why the table with all the information is hidden
behind a link at the bottom of a card. Both answers are the same: the summary report should not
exist.

Measured before deciding. Every index page is a strict superset of its summary report:

| Index | Filters | Columns | Totals row | Its summary report |
| --- | --- | --- | --- | --- |
| `/distributions` | 7 | 13 | yes | 1 filter, 2 figures, a preview list |
| `/donations` | 7 | 10 | yes | 1 filter, 2 figures, a preview list |
| `/purchases` | 3 | 10 | yes | 1 filter, 6 figures, a preview list |
| `/product_drives` | 4 | 10 | no | 1 filter, 3 figures, a preview list |

So each summary was a weaker copy of a page that already existed, whose only addition was a few
aggregates, and which then linked back to the page it copied. The table was not hidden by
accident; it was on the other side of a link from something that added almost nothing.

Data-dense systems — NetSuite, Odoo, Cin7, QuickBooks Commerce — put the aggregates on the list
page: filters, then the figures those filters produce, then the rows. The figures were already
being computed here, in a `<tfoot>` below a long table, split into "this page" and "all
distributions". Folding them in was mostly promoting numbers that already existed to somewhere
someone would look.

The `<tfoot>` totals went, on the explicit call that the band and the footer saying overlapping
things is worse than either alone. That drops the per-page subtotal, which had no other consumer;
the band answers for the filtered set, which is the question people were asking the footer.

Old report URLs redirect to the index rather than 404, because a report link may sit in a
bookmark or an email to a funder.

## 2026-08-18 · A hub card carries a qualifier, not a sentence and not a bare link

Three attempts before this landed, which is worth recording because the middle two were both
defensible and both wrong.

Bare links in a subject card read as flat — an unstyled list. A sentence per report, as fifteen
uniform tiles, was legible and pushed the whole grid below the fold: a menu you have to scroll is
not doing a menu's job.

What works is a card per subject with one line per report and a two-to-four word qualifier
underneath — "Itemized / by item and partner". Enough that the card is not a list of links,
little enough that six cards fit in a 3×2 grid measuring 659px to the bottom of the grid.

Rejected: an icon per report row. It was in the mock and it was too busy — eleven glyphs in a
grid whose cards already carry one each. One icon per card marks the subject; repeated down the
rows it marks nothing.

Also rejected: a live figure per subject card. It looks best in a screenshot and would have made
a menu run six aggregate queries, duplicated the numbers the index pages now show, and put an
all-time figure next to a date-ranged report.

## 2026-08-18 · A zero is a figure, not a blank

`dollar_value` returns "" for zero. That is a considered choice for a table column, where a
stack of `$0.00` is noise. In a stat band it produced an empty figure under a label, which reads
as broken data rather than as nought — two of them, on donations and product drives, and only
visible by looking at the rendered page.

Bands use `dollar_presentation`, which always renders. `dollar_value` is untouched: the table
cells that use it still want the blank.

## 2026-08-18 · A tab that needs its own action must be its own URL

The partner agencies page had three header actions and a fourth — "New partner group" — in a bar
of its own between the tab strip and the table, where it read as table furniture.

It was there for a reason: the action belongs to the Groups tab, and the header could not follow
the tab because the tabs switched panels in the browser without changing the URL. A header
cannot react to state it does not know about.

So the tabs became links. `/partners` and `/partner_groups` are separate pages, each with its
own primary action: "New partner agency" on one, "New partner group" on the other. Three header
actions on each, never four. This is what GitHub does — Issues gives you "New issue", Pull
requests gives you "New pull request" — and Linear, Jira and Shopify the same.

Two things fell out of it that were worth having anyway. A tab you can link to, bookmark and
reach with the back button. And a partner groups page that exists, rather than a panel that only
appears if you find the tab.

**Not the ARIA tabs pattern.** A new `page_tabs` component sits beside `tabs` rather than
replacing it. `role="tab"` promises a screen reader that activating this swaps a panel in the
current document; when the tab loads a page that promise is false, and the tablist takes the
arrow keys from the browser while it is at it. Page tabs are a `<nav>` of links with
`aria-current`. `tabs` is still right where panels genuinely switch in place — items, storage
locations.

## 2026-08-18 · The button count rule was already being followed, just not written down

Asked what the convention is for multiple buttons at the top of a page. Measured before
answering: six index pages carry exactly three actions, always two secondary and one primary,
and eleven carry two. The app is consistent, and consistent with what Polaris, Carbon, Material
and Atlassian all specify — one primary, at most three, primary last.

The rule simply was not in design.md, whose page header section covered spacing and the back
link and said nothing about actions. That is why a fourth button had nowhere to go and ended up
inside a table: there was no rule to violate, so nobody noticed it was being violated.

Written down now, along with the corollary that a fourth button is a signal rather than a
problem to place — usually a section of the page wanting an action of its own, which is a tab
wanting to be a URL.

## 2026-08-19 · The layout is not the page

40 of 98 form pages hand-rolled their own header, card and inputs while rendering inside a
correct design system layout. `bin/design/status.rb` counted every one of them as migrated,
because it asks whether a view contains design system markup and they all did.

That is the lesson worth keeping: **a page can sit in the right shell and still be unmigrated.**
The shell was the easy half. What took the time was the inside of each form -- fields that mixed
`f.input` with raw `f.label` + `f.text_field`, `class:` passed to `f.input` where simple_form
ignores it, radio groups laid out with `&nbsp;` runs and `<br>`, and card classes pasted inline
so a change to the card could never reach them.

`bin/design/page-audit.rb` now checks for it and exits non-zero, so the gap status.rb leaves is
covered by something.

## 2026-08-19 · Open the page, every time

Every batch turned up at least one defect no class-name audit could have found, and every one
was obvious within seconds in a browser:

- Divs that did not balance, so the browser split one form into two and left the submit button
  outside the fields. Three pages had this. They worked, by the HTML parser's error recovery,
  which is exactly why they survived.
- A stray `intersect?` expression printing `true` onto a page.
- A second `<h1>` inside a form.
- An empty `<button>` — a collapse toggle whose AdminLTE JavaScript had been deleted.
- A "New base item" page whose card header read "Update", with a blank name.

The rule: rewrite a page, then load it. `submitInForm` and a count of fields outside the form
are two cheap assertions that catch the whole unbalanced-markup class, and they are now in the
verification list.

## 2026-08-19 · A header replacement can take a warning with it

`users/registrations/edit` kept its staging warning inside the hand-rolled header block. The
header was replaced wholesale with `page_header` and the warning went with it -- a user-facing
notice about not being able to change demo credentials, silently deleted.

`spec/system/account_system_spec.rb` caught it, which is the argument for the assertion existing
at all. But the general point is about mechanical replacement: when a block is swapped out
wholesale, read what was inside it first. A header block is a plausible place for a page to keep
something that is not a header.

## 2026-08-19 · Audit every page kind, and separate defect from debt

The form audit was form-only, so `show` and `index` pages had never been checked. They needed to
be: nine of 31 show pages carried defects, including three cases of malformed markup that the
browser silently repairs into a different tree.

`bin/design/page-audit.rb` replaces `form-audit.rb` and covers show, index, form and partial. One
tool rather than two overlapping ones.

The useful addition is **two severities**, because they are not the same problem:

- **Defect** — the page is wrong now. A class nothing defines, a hardcoded inline style, layout
  built from `&nbsp;`, Title Case, or no `page_header` and therefore no back link.
- **Debt** — the page renders correctly, but the card's classes are pasted inline instead of
  rendering the component, so a change to the card can never reach it.

The script exits non-zero on a defect and reports debt without enforcing it. Conflating them
would mean either failing the build on cosmetics or letting real defects hide among them.

Three exclusions, all deliberate: `shared/essentials/*`, because the components are the
definition rather than a copy of it; mailer templates, where inline style is the only thing email
clients honour; and `static/*`, which the migration map already records as standalone public
documents outside the system.

## 2026-08-19 · A show page is a description list, not a one-row table

Four show pages presented a record as a table with a single row of data — `admin/partners/show`
was three columns and one row, with an empty `<h2>` above it. Two others used a bare `<dl>` with
no styling, so labels and values ran together in a wall of text.

A record's fields are label-and-value pairs, which is what a description list is for. Styled as a
two-column grid it reads better than either, and it does not promise a reader that more rows are
coming.

Also fixed on those pages: `partners/requests/show` set its field labels at `text-2xl font-bold`
above values at `text-lg`, so every label was larger than the thing it labelled — the same
inverted hierarchy the reports had.

## 2026-08-18 · Which modulepreloads to keep

Safari warns "preloaded but not used within a few seconds from the window's load event" for
roughly half the 66 `modulepreload` links this app emits on every page. Most of that warning
list is not a defect. `importmap-rails` 2.x preloads every pin by default, and
`eagerLoadControllersFrom` pulls the controllers in with dynamic `import()`, which does not
consume Safari's preload cache — so every Stimulus controller and everything a controller
imports (highcharts, select2, rrule, tslib) gets warned about even though it is loaded and
used on the very next tick. Turning those preloads off would silence the console and make the
pages slower: the modules would still be fetched, just serially, after the entry point parses.
The same goes for `turbo.min.js`, which `application.js` imports dynamically on purpose.

Two entries in the list were real, and both are gone:

- `pin "@fullcalendar/core/"` — a trailing slash maps a directory. There is no module at
  `https://ga.jspm.io/npm:@fullcalendar/core@6.0.1/`, so the preload could never be consumed
  by anything.
- `pin "sinon"` — 180KB, imported only by the fake-clock script that runs under
  `Rails.env.test?`. Default-on preload put it on every page in production.

The rule this leaves: a preload warning is worth acting on when the module is not part of the
boot graph at all. It is not worth acting on when the module is merely reached through a
dynamic import.

## 2026-08-19 · The date range filter is a preset menu, not a calendar

**Decision.** Litepicker is gone. The date range filter is a preset `<select>` with two native
`<input type="date">` fields revealed for the custom case, built from the design system's own
filter classes. The two unversioned CDN pins are removed.

**Rationale.** The complaint was that the popup "looks really odd", and it did — but it was not
broken, it was foreign. Measured with the calendar open: `-apple-system` rather than Figtree,
12.8px against a scale that has no such step, 5px and 3px radii against our 8px and 16px, a
`0 0 5px #ddd` glow where the app uses directional shadows, `#333` and `#ddd` hardcoded past
the slate scale, and `cursor: default` on the day cells so they did not read as clickable.

Three options were mocked up (`docs/mockups/date-picker-options.html`): two native date inputs;
a preset menu with custom dates behind it; or keeping a calendar and re-theming it.

Re-theming was rejected on the cascade. Litepicker injects **72** CSS rules at runtime, into
`<head>`, unlayered and after our stylesheet — the same trap FullCalendar cost us, where an
unlayered rule beats a layered one whatever the specificity, and every override needs
`!important` or a specificity fight. That buys a widget we maintain the theme for, still on a
CDN, still with a keyboard story we do not control.

Two native inputs alone was rejected because it loses the presets, and the presets are the
common case: a bank filing a funder report wants "last 30 days", not a pair of dates found on a
grid. The preset menu is what Stripe, Shopify, Google Analytics and Metabase all do for
reporting periods, and it matches the design system by construction rather than by being
re-themed — a `<select>` and two date inputs are already components we own.

**What it also fixed.** Two latent bugs, both invisible because Litepicker papered over them:

- The server rendered `@selected_date_range_label` — the *prose* from `#date_range_label`, e.g.
  `"during the period 19 Jun to 19 Sep"` — as the value of the `filters[date_range]` text
  field, and Litepicker overwrote it during setup. Anything that read the field before setup
  finished got a string `strptime` cannot parse. The spec suite knew: `fill_in_date_range` had
  to wait for `.litepicker` to appear or the seed would overwrite what it had typed.
- `filters[date_range_label]` was a hidden copy of that same prose, and nothing ever updated it
  from the calendar. So choosing "Last 30 Days" submitted the *previous* request's prose, which
  matches none of `#date_range_label`'s cases, and every named period collapsed to the generic
  wording after one round trip. The select's own value is now the preset name, so that
  parameter finally means what it says.

**Preset dates are computed server-side**, in `Time.zone`. Litepicker built them in the browser
from luxon's `DateTime.now()`, which is the browser's midnight — so "Today" could be a day out
from the "today" the query was actually filtered on. The controller now does no date arithmetic
at all.

**Which option is selected is decided by matching the dates**, not by reading
`filters[date_range_label]`. That parameter is user-supplied and, as above, was historically
wrong; a bookmarked URL whose label disagrees with its dates must not select an option that
misdescribes what is on screen. A range matching no preset reads as *Custom*.

**Rejected: changing the wire format.** `filters[date_range]` is still one string,
`"June 19, 2026 - September 19, 2026"`, split on `" - "` and parsed with `strptime`. Two ISO
parameters would be cleaner — a localised month name is a fragile thing to parse, and the
rescue silently resets to the default range with a flash. But that touches `DateRangeHelper`,
ten call sites and their specs, and none of it is what makes the control look wrong. Kept as a
follow-up rather than smuggled into a visual fix.

**Validation moved into the page.** Native date inputs cannot hold a non-date, which leaves
exactly one way to build an invalid range: end before start. That is reported in a `role=alert`
paragraph and blocked with `setCustomValidity`. The old control raised a `window.alert()` —
used nowhere else in the app, and a screen reader user meets it with no way back to the field
that caused it.

**Supersedes** the Litepicker halves of *2026-08-17 · Third-party widgets get their accessible
names added on top* and *2026-08-18 · State is read from the DOM, not from a global flag*. Both
still stand for FullCalendar and as general rules; the widget the second one was written about
no longer exists, and `window.isLitepickerActive` is deleted.

## 2026-08-19 · The period is said in words, next to the figures and in the empty state

**Decision.** `date_range_label` feeds two places: a sentence-case caption above the stats band,
and the `:no_results` empty state title. Not a standalone "Showing 13 distributions…" line.

**Rationale.** The band already answers *how many*. What no page answered was *how many of what
window* — the period lived only in the filter control, which is pinned at the top, prints as a
box, and says nothing at all once you have scrolled to the table. The empty state is where the
gap cost the most: "No distributions match those filters" makes the user go back and read the
controls to find out which ones, where "No distributions over the last 30 days" is the answer.

The standalone line was the literal request and is what GitHub, Linear and Stripe do. Rejected
here because this app is not those apps: the stats band sits 40px below the filter bar and its
first tile is the count, so the line would have put the same number on screen twice. The
caption adds the half that was missing and repeats nothing.

`reports/manufacturer_donations_summary` takes no caption: `shared/filtered_card` already states
the period in the page header, and two statements of it is the duplication we just avoided.

**Sentence case, not an uppercase eyebrow.** This slot — small muted text above a group of
figures — usually attracts `uppercase tracking-wide`. design.md's sentence case rule has no
exception for small text, and the distinction it is really making applies here: a period is
*read*, not scanned as a category label. `#upcase_first` rather than `#capitalize`, so the month
name inside the phrase keeps its own capital: "From June 19, 2026", not "From june 19, 2026".

**The helper had to be fixed first, and it was five bugs, not four.** Nothing had ever read
`date_range_label`, so nothing had ever caught them:

| Case | Was | Now |
| --- | --- | --- |
| This year | "during the period 01 Jan to 31 Dec" | "this year" |
| All time | "during the period 19 Aug to 19 Aug" | "across all time" |
| Last 7 days | "over the last week" | "over the last 7 days" |
| Custom ending today | "since 2026-03-03" | "since March 3, 2026" |
| Custom starting today | `""` | "from March 15, 2026 to December 1, 2026" |
| **No parameter at all** | "this year" | "from January 15, 2026 to April 15, 2026" |

Two causes. `selected_range_described` formatted with `to_fs(:short)`, which is Rails'
`"%d %b"` — **no year** — so a hundred-year range collapsed into what reads as a single day.
And *This year* and *All time* had no `when` clause, so they fell through to that same
date-range wording rather than naming themselves.

The last row is the one worth remembering: the method defaulted to `"this year"` when the
parameter was absent, which is the state every index page opens in. It described neither the
default window (two months back, one month ahead) nor anything else on the page. It was
invisible for as long as nothing rendered it, and it went on screen the moment something did.

**The pairing is now tested exhaustively**, not against a hand-kept list: every key in
`date_range_presets` except the default window must produce something other than its own date
description. Add a preset without a clause and the spec fails, which is how *This year* and
*All time* should have been caught.

## 2026-08-19 · The summary band is one card, and the columns follow the figures

**Decision.** `essentials_stats` renders a single card — white, `rounded-2xl`,
`border-slate-200`, `shadow-sm`, the same surface as every other card — with the figures divided
by hairlines rather than each sitting in its own filled `slate-50` box. The column count is
looked up from the number of figures.

**Rationale, on the layout.** The band was `grid gap-4 sm:grid-cols-2 lg:grid-cols-3` whatever
the number of figures, so it orphaned a tile on **every page that had one**, just at different
widths: four figures went 3 + 1 at 1360px, three went 2 + 1 at 900px. The fixed column count was
the whole bug. `STATS_COLUMNS` now maps count to columns so the grid is always full, and it is a
lookup rather than arithmetic because Tailwind scans source text — a computed class name would
not be generated.

**Rationale, on the fill.** Four filled boxes read as four objects; a summary band is meant to be
one reading. Removing the fill and putting the figures on one surface is what Stripe, Shopify and
Linear do for a metric strip. It also fixed a smaller inconsistency: the tiles were
`rounded-xl` (12px) where every card in the app is `rounded-2xl` (16px).

**The separators are a `gap-px` grid over a backdrop**, not `divide-x`. `divide-*` borders by DOM
order, not grid position, so in any arrangement of more than one row it draws lines in the wrong
places — the second cell of a 2×2 gets a top border because it is the second *child*, not because
it is below anything. A 1px gap showing a `slate-200` parent through it puts a hairline between
every pair of actual neighbours, rows included, and needs no per-breakpoint reset.

The trade this makes: an **empty grid cell now shows as a grey block** rather than as whitespace,
because the backdrop shows through wherever a cell is missing. That is why the count and the
columns have to agree, and why it is written down in `design.md` next to the table rather than
left as a property of the implementation.

**Rejected: the minimal fix** — keeping the filled tiles and only correcting the column count.
It removes the orphan, which was most of the complaint, and it is one line. Rejected because it
leaves the other half: four grey boxes floating on the page in no container, which is what
prompted the question.

**Rejected: `divide-y` stacked with `lg:divide-x lg:divide-y-0`.** Simpler, and correct at both
ends, but it gives up the tablet range: between 640px and 1024px four figures stay a tall stack
where there is room for two abreast.

The caption stays above the card. It names the period the whole band covers, so inside the first
cell it would read as belonging to one figure.

## 2026-08-19 · Known flake: Partner#impact_metrics does not order its zipcodes

`spec/models/partner_spec.rb:328` asserts `family_zipcodes_list` equals
`["45612-123", "45612-126"]`. The method is `families.pluck(:guardian_zip_code).uniq` — **no
`ORDER BY`** — so Postgres is free to return the rows either way round, and on a full run it
sometimes returns them reversed.

It failed on `--seed 12807` in a full run and passes in isolation. Verified as nothing to do with
the summary band work: that change touches no model, query, service or migration, only
`essentials_ui_helper.rb` and views.

Recorded rather than fixed, on the same reasoning as the `DonationSite` flake above. The fix is
either an `.order(:guardian_zip_code)` in the model or a `match_array` in the spec, and choosing
between those is a decision about the model's contract — whether the list is a set or a sequence —
which belongs to whoever owns that feature.

## 2026-08-19 · The filter bar is a grid, and the summary card says its own scope

**Decision, on the bar.** `grid-cols-1 sm:2 lg:3 xl:4` with `min-w-0` cells, replacing
`flex flex-wrap` with per-cell `min-w-[13rem]` boxes. The date range cell takes `sm:col-span-2`;
the actions move to their own `col-span-full` row, right-aligned.

**Rationale.** A flex item sizes to its *content*, and the content here is the longest option in
the menu. So the controls came out 208, 224, 247, 278, 285 and 289px across four pages — six
widths for the same kind of control — and `flex-wrap` packed each line left and left the
remainder: 337px on `/distributions`, 793px on `/donations`, 852px on `/purchases`, and three
ragged lines on `/requests`. Both halves of that are the same bug, and a grid fixes both because
the width comes from the breakpoint rather than the text. Measured after, on nine pages at 1360,
900 and 390: one width throughout plus the date range's deliberate span, and no cell overflowing
its column at any width.

A bar with one filter now renders that control at a quarter width with three empty columns beside
it. That is correct, not a regression: it is the same width as the same control on every other
page, which is the point.

**Decision, on the card.** `essentials_stats` takes `title:` and `subtitle:` and renders a header
inside the card. `essentials_stats_scope(count, noun)` builds the subtitle.

**Rationale.** The figures had no title at all, so the period sitting above them was doing two
jobs and read as though it might belong to the table underneath. The missing information was not
a name, though — it was **scope**: that these numbers describe the filtered view rather than the
whole database. The sentence carries all three: how many, whether the filters are narrowing it,
and over what period.

Two things it gets right that the obvious version does not. It says "matching these filters" only
when something *other than the date range* is set — a date range is always set, so counting it
would make every page claim to be filtered when the user has touched nothing. And there is no
leading "The", because that does not survive the edges: "The 1 donation" and "The 0 donations"
both read as though a machine wrote them. Zero gets "No".

**Rejected: "13 of 214 donations."** The most informative version, and the only one needing a
second unfiltered `COUNT` on every page load. Not worth a query per request unless we specifically
want people to see how much the filter is hiding.

**`reports/manufacturer_donations_summary` still takes no header** — `shared/filtered_card`
states the period in its page header, and two statements of it is the duplication this avoids.

**`date_range_caption` is deleted.** It was added a commit earlier for the standalone-caption
design, and the header supersedes it: the scope sentence uses `date_range_label` mid-sentence,
where it stays lower case, so nothing needs the capitalised form. Its only remaining caller was
its own spec.

**Relabelled** `Default (recent and upcoming)` to `Last 2 months and next month`. The old label
said neither what it included nor how far it reached. Behaviour is unchanged: the window still
runs into the future on purpose, because a distribution can be scheduled before it happens and a
range ending today would hide everything already booked in. The spec that checks every preset has
a phrase now identifies the default window by its dates rather than by its name, so a future
rename cannot silently drop it from that check.
