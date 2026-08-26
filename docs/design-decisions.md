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

## 2026-08-19 · Known flake: the donation site factory can generate the same name twice

`spec/models/organization_stats_spec.rb:66` calls `create_list(:donation_site, 3, ...)` and
sometimes fails with "Name must be unique within the organization".

`DonationSite` validates `name` unique per organization, and the factory sets
`name { Faker::Company.name }` — a random pick, not a sequence. Enough donation sites in one
organization and Faker repeats itself. Whether it fails depends on how many other specs in the
run have already created sites in that organization, so it is order-dependent.

Passes in isolation. Verified as nothing to do with the filter work: that change touches no
model, query, service or migration.

Recorded rather than fixed, on the same reasoning as the two flakes above. The fix is a sequence
in the factory, and changing a factory that 40-odd specs build on belongs to its own change with
its own full run.

## 2026-08-19 · Filters apply on change, into a Turbo Frame

**Decision.** No Filter button anywhere. A filter bar passed `frame:` submits into that Turbo
Frame, so only the results are replaced. Sixteen bars, plus the report card and two pages that
had hand-rolled their own form.

**Rationale.** Applying on change is what Linear, GitHub, Notion and Stripe do, and the button
was an extra click on every filter. The app already did both — five bars applied on change,
eleven did not — so the inconsistency was the real defect.

But the button was not an oversight. `application.js` sets `Turbo.session.drive = false`, so a
plain submit reloads the whole document: sidebar, assets, scroll position, focus. Auto-applying
nine filters that way is up to nine reloads while someone is still deciding. The frame is what
makes applying on change affordable, so it had to come first rather than being a nicety on top.

**Four details are load-bearing, and each was found by breaking it.**

`target="_top"` on the frame. Without it every link *inside* the frame navigates the frame, so a
row action fetches a page containing no matching frame and Turbo discards the response —
*"The response (200) did not contain the expected `<turbo-frame id="items-results">`"*. That took
out 66 specs in one run: every Edit, View, Restore and Deactivate on every index.

`data-turbo="true"` on the form. Turbo only ignores `drive: false` for elements *within* a frame
(`Session#elementIsNavigatable`), and these forms sit outside the frame they target. Without the
opt-in Turbo declines the submit and the browser reloads the whole page — **silently**, because
the filter still works and only the scroll position gives it away.

`turbo_action: "advance"` so the URL keeps up. A filtered view has to stay bookmarkable; that is
the reason filters are GET in the first place.

The form stays **outside** the frame. Inside it, the controls are replaced on every change and
focus is lost mid-filtering.

**The export link had to be rebuilt in JavaScript.** It lives in the page header, outside the
frame, so applying a filter in place left it pointing at the previous query. Exporting the wrong
rows is a worse failure than a stale table: the file looks correct and nothing on screen
contradicts it. `auto_submit_controller` now rebuilds its query string from the form on every
frame load, keeping the link's own path so the `.csv` format survives.

**Announcing the change.** Applying in place is silent to a screen reader — nothing navigates and
focus does not move. The bar renders a `role="status"` region *outside* the frame and the
controller writes the new result summary into it; a live region that is itself replaced does not
announce its new contents. Where a page has a summary card the announcement is its scope
sentence. Where it does not, it is a row count — but only when the page is unpaginated, because
announcing "51 results" when 51 is merely the page size is worse than saying nothing precise.
Paginated pages get "Results updated".

**Waiting, in specs.** `wait_for_filters` waits on **network idle**, not on the frame's `busy`
attribute. Turbo only marks a frame busy when its own controller handles the navigation; with the
form outside and `target="_top"`, the session handles it instead and the attribute is never set.
Measured on `/transfers`: request at +11ms, frame rendered at +93ms, no attribute mutation at any
point. The quiet period is 300ms, which has to exceed the gap between the change event and the
request leaving, or "idle" is satisfied by the moment before anything has started.

**Two pages were rebuilt rather than converted**, because their filters were hand-rolled:
`events` had the tag closing its form block sitting after the div closing its card, plus two
stray empty columns and a Title Case header row; `distributions_by_county/report` was a bespoke
card inside three nested empty divs with a `<br>` between the date filter and its button. Neither
was visible to `page-audit.rb`, which reports both files as clean — nothing in them used a class
that no longer exists. That is the same lesson as before, in a new place: the layout is not the
page.

`UiHelper#filter_button` is deleted. It had one caller left and now has none.

## 2026-08-19 · The date range is one column wide, and a dense bar collapses

**Two defects first**, both introduced by the grid work a commit earlier.

The date range cell carried `sm:col-span-2` permanently, because it holds three controls once
*Custom* is chosen. It holds three controls only when Custom is chosen; the rest of the time it
was one select in a cell twice the width of its neighbours. The custom dates now stack inside a
one-column cell. Two date inputs abreast in one column would leave about 119px each against a
natural width of 149.

The actions sat on `col-span-full`, which cost a whole grid row on every page with a bar,
including `/partners`, which has one filter and now fits on one line. They are an ordinary cell
with `self-end`.

**The industry answer to the date range is a popover** — Stripe, Shopify and Google Analytics all
put the presets and the custom range in a floating panel behind a single-width trigger, which is
how they keep one cell's width whatever state it is in. Rejected for now: it needs anchoring, a
focus trap, escape and click-outside, none of which this design system has, and stacking gets the
same width discipline out of markup we already own. Written down rather than silently skipped,
because it is the thing to build if the date filter ever needs to be richer.

**Then the density.** Five filters or more and the bar collapses behind a Filters button. Four or
fewer is one row at desktop and hiding one row behind a click costs more than it saves. Measured:
`/donations` 264px to 38px, `/distributions` and `/requests` 188px to 38px; `/transfers` and
`/items` stay open and drop to 64px from the two fixes alone.

The threshold is counted **in the partial**, from the element children of the yielded block
(Nokogiri, 26µs), so no call site decides it and the behaviour cannot drift from one page to the
next.

**A collapsed filter set has to say what is active.** That is the whole condition on collapsing:
filters that narrow the data with nothing on screen to show for it are how someone concludes their
records have disappeared. So the collapsed bar carries a count on the button and a dismissible
chip per active filter, and the panel does *not* open itself when the page arrives filtered —
the chips already say what is applied, and opening automatically would give the space back on
exactly the pages where it was worth saving.

The chips are built **in the browser**, not rendered by the server. The bar sits outside the
results frame, so it does not re-render when a filter applies; anything the server put there
would be one filter behind. That is the same bug the export link had.

The date range counts as active only when it differs from the range the page would have shown
anyway, which its select declares in `data-default-value`. Without that every page would claim to
be filtered before the user touched anything.

**A thing that cost an afternoon, worth writing down.** Clearing the flash when a filter applies —
which restores what a full page reload used to do — lifts everything below it. Cuprite clicks by
coordinates, so a spec that clicks a row action straight afterwards lands where the button was,
and reports it as a missing confirmation dialog rather than a mis-click. The spec now waits for
the flash to go before clicking. The same reflow is a small hazard for a real user, and it is the
reason to be wary of removing anything above the fold in response to an unrelated action.

Two other things the same investigation turned up: `turbo:frame-load` also fires when a frame is
**first connected**, so clearing the flash there deleted the message on every ordinary page load
until it was guarded; and `wait_for_filters` must use a quiet period longer than the 400ms text
debounce, or "idle" is satisfied by the pause before the request has been sent.

## 2026-08-20 · One filter pattern, a date range popover, and every dialog was in the corner

**The threshold is gone.** Every filter bar collapses, whatever its size. Two behaviours across
sixteen pages is worse than one whichever one it is: someone who learns the filter bar on
donations and then meets something else on transfers has learned nothing transferable. The
argument for the threshold — that hiding a single row behind a click costs more than it saves —
was true in isolation and wrong in aggregate.

**Every modal in the app opened in the top-left corner.** Not one page: twenty-eight files. A
native `<dialog>` opened with `showModal()` is centred by the browser's own `margin: auto`, and
Tailwind's preflight resets `margin: 0` on every element. Measured on `/requests`: `:modal` true,
`top: 0, left: 0`, `margin: 0px`. One rule in `@layer base` fixes all of it, along with the
`max-height` and `max-width` preflight also takes, without which a long dialog grows past the
viewport and its top scrolls out of reach.

**That bug is the more useful finding.** It survived `page-audit.rb`, which reads markup, and
`wcag-audit.js`, which scans pages as loaded, because **neither had ever opened anything**. Both
reported these pages clean while every dialog on them was unusable. `bin/design/overlay-audit.js`
now opens all of them — 3 dialogs and 14 popovers — and checks centring, viewport fit, accessible
name, Escape, focus return and surface, and runs axe on the opened overlay. It found one more
real thing on its first run: a `max-h-96 overflow-y-auto` list inside the calculate-totals dialog
that could not be scrolled by keyboard, WCAG 2.1.1.

**The date range is a popover**, which is how Stripe, Shopify, Google Analytics, Metabase and
Linear all handle a custom range inside a filter set. The reason is layout, and it is measurable:
inline, choosing *Custom* turned a 64px grid cell into a 216px one and added 152px to the bar at
every width, with an empty column beside it above 1360px. A panel is over the page, so it costs
nothing. It also lets both dates be applied together, which removes the intermediate request the
inline version fired after the first field.

**Popovers now share one controller**, and the account menu moved onto it from `shell`. The
contract is written down in `design.md` because each clause is something a hand-rolled version
gets wrong: Escape closes and returns focus; an outside click closes but does *not* pull focus
back, because the click has already placed it; `aria-expanded` tracks state and the panel is
`hidden` rather than merely invisible; and it flips above the trigger rather than off the bottom
of the screen. Positioning is measured from the trigger's rectangle rather than done in CSS,
because anchor positioning is still Chrome-only.

A popover is deliberately **not** a modal: no focus trap, no inert background. You are meant to
see what you are filtering while you filter it.

**One elevation for anything above the page.** `POPOVER_SURFACE_CLASSES` is the dialog's surface.
The account menus used `shadow-lg`, a third step in a two-step scale that nothing else shared.

**One Clear.** "Clear all" beside the chips and "Clear filters" inside the panel did the same
thing, and the second is invisible exactly when the panel is shut.

**Calculate product totals** was rendered inside the filter bar, so it was laid out as a filter
cell — the misalignment — and once the bar collapsed it was hidden behind the Filters button. It
is a page action and now sits in the header.

**Capybara's default wait went from 2s to 5s.** Filtering is asynchronous now, and a
request-and-render under a full suite exceeds two seconds often enough to produce failures that
read as wrong row counts rather than as timeouts. It only lengthens the path to a genuine
failure; a passing assertion still returns as soon as it is true. Three specs were chasing this
before the cause was clear.

## 2026-08-20 · Nav weight follows the level, and the two bottom strips are one band

**Decision.** Every top-level sidebar item is `font-semibold text-slate-700`, whether it expands
or not; nested items are `font-medium text-slate-600`. The rail's pinned item and the page footer
are both `h-14` with a full-bleed top border.

**Rationale, on the weight.** Dashboard, Reports and My organization were at the *child* weight —
500/slate-600 — sitting at the same indent as Operations, Inventory and Network at 600/slate-700.
Measured, all six at `left: 12`. So a top-level destination looked like a child that had lost its
parent, which is what "the typography does not match" turned out to mean.

The mistake underneath it is that the styling encoded **behaviour** (does this expand?) rather
than **hierarchy** (how deep is this?). GitHub, Linear, Notion, Jira, Stripe and Vercel all do the
opposite, and the reason is that a rail is scanned by indentation and weight: an affordance marks
what a thing does, type marks where it sits. Dashboard only ever looked right because it was the
active page and picked up the active weight by accident.

**Rationale, on the strips.** The rail's pinned item and the page footer both sit at the bottom of
the screen, 12px apart — their rules at y=831 and y=843. Twelve pixels is too little to read as a
deliberate separation and too much to read as a line, so it reads as a mistake. Both are `h-14`
now and their rules meet at y=844; the rail's `-mx-3` takes its border to the rail edge, where the
`border-r` carries it into the footer's. Measured: 0→255 and 256→1440, one line.

They keep different type on purpose. The rail item is a destination at `text-sm`; the footer is a
colophon at `text-xs`. Matching them would make the credit look like a fourth navigation item.

**Not done: moving Reports.** It sits at the top beside Dashboard because grouping the two leaf
items was tidy when the reports hub replaced the fifteen-item Reporting group. The convention —
Stripe, Shopify, Xero, QuickBooks — is home, then the work, then read-only views of the work, then
the pinned account item, ordered by how often each is wanted. By that rule Reports belongs after
`Network`. Left in place pending a decision, because nav order is the sort of thing a particular
bank may have a reason about, and the rule is now written into design.md either way.

## 2026-08-20 · Spacing follows the section, and the flash no longer clears on filter

**Reports moved** below the working groups, per the ordering rule recorded yesterday.

**Spacing was the same mistake as weight, one layer down.** *Dashboard* and *Reports* shared one
`<ul class="space-y-0.5">` — the spacing for items *inside* a section — so they sat 2px apart
while every other top-level entry was 16px away. Measured: 2px, then 16, 16, 16. They were in one
list only because both happened to be leaves, which is not what makes a section. Now a single
`space-y-4` separates every top-level entry and the group partial carries no margin of its own.

**The flash no longer clears when a filter applies, and that reverses a decision made yesterday.**
Restoring what a full page load used to do seemed right, but removing 56px from above the results
moves everything below it — under a cursor that is often already over a row action. It is a
layout shift in response to an unrelated action, which is a hazard for a person, and it broke
three specs that click a row action after filtering: storage locations, vendors and items, each
failing in a full run and passing alone. A message about something that did happen is the cheaper
problem, and it clears on the next real navigation.

Worth naming: the first two of those three failures were treated as spec timing and patched with
waits before the common shape became visible. The pattern only resolved once all three were on
the table at once. A flake in one spec is a timing story; the same flake in three is a design
one.

**A real bug the specs caught on the way.** `auto_submit_controller` resolved its frame with
`document.getElementById` in `connect()`. The form is parsed *before* the frame it targets, so
that could return null — and then the export link was never rebuilt and the result was never
announced, silently. It held in a browser and not under Cuprite, which is exactly the kind of
difference that hides a real bug inside a timing story. It now listens on the document and
resolves the frame when it needs it.

**And one spec that was asserting the wrong thing.** After reactivating a storage location the row
shows *Deactivate* — but disabled, whenever the location holds inventory. `have_button` requires
an enabled button, so it is not a signal. *Reactivate* disappearing is the outcome, and waiting
for that is what made the test deterministic.

## 2026-08-20 · Propshaft instead of Sprockets

**Decision.** Replace `sprockets-rails` and `sprockets` with `propshaft`. Recorded in full as
[ADR 0012](architecture/decisions/0012-use-propshaft-instead-of-sprockets.md); this is the short
version and what it superseded.

**Rationale.** Sprockets is a compiler, and after the design system migration there was nothing
left here for it to compile. No `//= require` directives — the only file with any was
`manifest.js`, which exists to feed Sprockets. No ERB assets. No Sass. No bundling, because
importmap serves JavaScript unbundled. One stylesheet, already minified by the Tailwind CLI before
Sprockets saw it. What remained was digesting filenames and rewriting `url()` in CSS, which is
Propshaft's entire job.

The configuration made the case on its own: three separate pieces of it existed to stop the
compiler compiling. `css_compressor = nil` because libsass cannot parse Tailwind v4 output; an
initializer rejecting `app/assets/tailwind` from the load path so `application.css` would not
resolve to `@import "tailwindcss"`; and a precompile list kept in step by hand.

**Supersedes** *2026-08-17 · `config.assets.css_compressor = nil`*. Propshaft has no CSS
compressor, so the setting is not disabled — it does not exist. The reasoning in that entry still
explains why libsass and Tailwind v4 cannot be combined, which is worth keeping.

**Measured, not assumed.** The served stylesheet is byte-identical to the build apart from
Propshaft quoting `url()` values: 12 font URLs, two quotes each, 24 bytes. All twelve still point
at `public/vendor` and all twelve files exist. Figtree and Bootstrap Icons load, icons render, 70
JS modules resolve, no failed requests and no console errors across four pages.

**The development trap inverted, which is worth knowing.** It used to be that assets went stale
until you precompiled. Propshaft serves from the load path in development and test, so
precompiling is what makes them stale — Rails then serves `public/assets/.manifest.json` until it
is deleted. `CLAUDE.md`, `design.md` and `docs/onboarding.md` all said the old thing and now say
the new one.

**One trap that is not Propshaft's.** `tailwindcss-rails` enhances `assets:clobber` with its own
`tailwindcss:clobber`, which deletes `app/assets/builds/*.css`. Clobbering without rebuilding
leaves every page 500ing on a missing `tailwind.css`. That was true under Sprockets too; it just
took this migration to walk into it.

---

## 2026-08-20 · Page size is banded by row height, not set once

**The measurement that decided it.** Row heights in this app differ by 4.5×, measured at
1440×900: 45px on `/users`, 121px on `/items`, 155px on `/distributions`, 205px on
`/purchases`, where a row carries a wrapped list of line items. One page size cannot serve
that spread. At 50 everywhere, `/purchases` is a 10,250px page — eleven screens. At 15
everywhere, `/users` needs five clicks to show what fits on one.

So `Pagination` names three bands — `TALL` 15, `MEDIUM` 25, `COMPACT` 50 — and each index says
which one it is. Every band lands a full page between 1.8 and 3.4 screens.

**Rejected: a rows-per-page select.** It is what Material, Ant Design and AG Grid ship, and it
was the obvious alternative. It hands the user a decision the bands exist to settle, and to be
worth anything it has to be remembered per table and per user, which is a preference store, a
permitted param and a migration for a problem the design can just answer. It also adds a fourth
control to a strip that already competes with the filter bar above it.

**Rejected: load more / infinite scroll.** These are working tables. People print a
distribution, Ctrl-F an item and send someone a link to what they are looking at. An appended
row cannot be linked to, the browser's find only sees what has been loaded, and the page footer
retreats every time the user reaches it.

**Band by measuring, not by looking.** `/broadcast_announcements` reads as a dense table and
its rows are 85px, because the message body wraps. It was banded `COMPACT` on appearance,
measured at 4,225px — 4.7 screens — and moved to `MEDIUM`.

**Kaminari's default was 5 in development and staging, 50 elsewhere.** That is the more
interesting half of this change. A page under review never looked like the page in production:
a reviewer saw a pager under a five-row table and never saw the table that was actually long.
It is one number now, 25, in every environment.

**The scope that was not taken.** Eight index tables are still unpaginated and are listed with
their measured row heights in `migration-map.md`. Two of them are unbounded by construction and
should be next: `/admin/partners` lists every partner across every organization, and
`/admin/ndbn_members` is a national roster. They were left out because this change was scoped to
page *size*, and widening it silently is as much a problem as narrowing it.

## 2026-08-20 · The pager's chrome belongs to the card, not to the pager

Three defects, each present on every page that used the component, and each invisible to the
audits because all three are about a box that is empty or doubled rather than markup that is
wrong.

**Two hairlines.** The card footer draws `border-t border-slate-200 px-5 py-3` and the
pagination partial drew the same thing inside it — two rules twelve pixels apart, 24px of
padding where there should be 12. The partial no longer draws chrome. The one place the pager
is not a card footer, the item list's tab panel, supplies it inline, because a card footer
there would show the item pager under the Kits tab.

**An empty strip.** Call sites passed `footer: capture { concat(render(...)) }` and the card
tested the result for blankness. That is correct in production and wrong in development:
`annotate_rendered_view_with_filenames` puts `<!-- BEGIN ... -->` in the buffer, so a partial
that rendered nothing still captured something, and nine pages carried an empty bordered strip
under the table. Fixed by moving the decision out of the template —
`essentials_pagination_footer` returns `nil`, which is unambiguous in every environment.

The general lesson is the one the environment-split page size gave too: **a rule that reads
the rendered output will read a different thing in development than in production.** Decide in
Ruby, on the data.

**A whole-page visit.** Kaminari's link templates had no `data-turbo-frame`, so with Drive off
a page link left the frame and reloaded the page, losing the scroll position. Every link
carries `data: {turbo_frame: "_self"}` now. Verified on `/requests`: a marker set on `window`
survives the page change, so the document is not replaced; the rows change, the label goes
"Page 1 of 10" to "Page 2 of 10", `aria-current` moves to 2, the URL advances to `?page=2`,
and the scroll position holds to within 29px — the drift is the two pages' rows not being the
same height, not a reset.

## 2026-08-20 · Two more system-suite flakes, recorded rather than chased

Three full runs of the suite while landing the page-size bands, and each disagreed with the
others. Written down so the next person does not spend an afternoon deciding whether they
matter.

**The first run's 20 failures were self-inflicted** — Playwright probes and an axe run were
going against the dev server at the same time, and Cuprite times out under that contention. The
give-away was 18 of the 20 failure screenshots being the login page at exactly 47,153 bytes: a
`sign_in` that timed out, not a page that rendered wrong. All 62 examples in those three files
pass in 44 seconds when run alone. **Do not run the browser audits and the system suite at the
same time.**

The two runs after that gave one failure each, in different places, neither reproducible:

- `request_system_spec.rb:55` — `have_css("table tbody tr", count: 5)` found one node and six
  `<<ERROR>>`s. `<<ERROR>>` is Capybara failing to read a node it had already matched, which
  means the frame swapped underneath the query. Passes 5 of 5 in isolation and 27 of 27 in its
  own file.
- `storage_location_system_spec.rb:167` — the reactivation flash, asserted after the frame that
  carries it is replaced. This one had already been hardened once this week and still flakes.
  **Measured on 21 August: it fails 4 times in 8 on a clean `HEAD` and 3 times in 8 with the
  pagination work applied**, so it is a coin flip and not attributable to that work — but it is
  much worse than "intermittent" and will fail CI about half the time. It deserves its own
  piece of work rather than a sleep buried in someone else's commit.

  What the captured page shows, so the next person does not start from nothing: at the moment of
  failure the flash still reads "Storage Location deactivated successfully", the single row is
  still marked Inactive, and `include_inactive_storage_locations` is unchecked. The confirm
  assertion on the line above passes, so the dialog appeared with the right text and was
  accepted — the PUT simply never lands. The suspicion is the interaction between a row action
  and Turbo with Drive off: `data-turbo-confirm` shows a native `window.confirm`, and on accept
  the submission has to survive `elementIsNavigatable` returning false for a form outside a
  frame.

Neither is attributable to the pagination change. `/storage_locations` is not paginated, no file
under it changed, and it renders the card without a `footer:` local — so the one shared edit that
could have reached it (`if footer` becoming `if footer.present?`) evaluates identically for that
page, `nil` either way.

## 2026-08-20 · The pager says how many rows matched

Four designs were put up in `docs/mockups/pagination-designs.html` and **A** was chosen: keep
the numbered pager, and replace "Page 3 of 19" with "Showing 31–45 of 272 requests".

The reason is that a page number is a proxy for the thing people want to know. It changes
meaning whenever the page size does — and the page size had just been banded three ways, so
"Page 3 of 19" means something different on `/purchases` than on `/adjustments`. More to the
point, an index page in this app opens with a filter bar and a date range; the question that
raises is *how much matched*, and the pager was the only place on the page that could answer it
and did not.

**Rejected: a rows-per-page select** (Material, Ant Design, AG Grid). It hands the user the
decision the bands exist to settle, and to be worth anything it has to be remembered per table
and per user — a preference store and a migration for something the design can just answer. It
also puts a fourth control on a strip that already competes with the filter bar above it.

**Rejected: load more / infinite scroll.** These are working tables. People print a
distribution, Ctrl-F an item, and send a colleague a link to what they are looking at. An
appended row cannot be linked to, the browser's find only sees what has been loaded, and the
footer retreats every time the user reaches it.

**Kept, against the mockup.** The A panel drew the pager without `« First` and `Last »`,
reaching the last page through an ellipsis and the final page number instead. Both are kept:
jumping to the oldest record is a real task on the audit and event tables, and a page number
that moves as the result set changes is a worse click target than a button that does not. The
prose beside option A described it as "one change: the label", which is what was built — the
panel's pager was drawn idealised and that was an inconsistency in the mockup, not a decision.

**The noun is lowercased word by word, not with `downcase`.** Kaminari's `entry_name` returns
the humanised model name, which is capitalised and which an i18n entry may have set by hand —
`ProductDrive` reads "Product Drive". A word keeps its case if it carries an internal capital,
so `/admin/ndbn_members` will read "NDBN members" when it gets a pager rather than "ndbn
members".

## 2026-08-21 · The pager is always there, and so are its controls

Option A of three in `docs/mockups/pagination-count-options.html`. The strip renders for any
table with rows, and a control that leads nowhere is drawn disabled rather than removed.

**Two reflows, not one.** The question was about single-page tables — nine of sixteen index
pages showed no strip at all, so nothing said how many rows matched. Measuring it turned up the
same fault on multi-page tables: `« First` and `‹ Prev` were not rendered on page 1 and `Next »`
and `Last »` were not rendered on the last, so `/requests` was 7 controls on page 1, 14 on page
5 and 8 on page 10. The row of buttons changed width as you used it, which moves a target out
from under the cursor of the person clicking it.

**This is the majority convention** for dense admin tables: Stripe, Shopify Polaris (whose docs
say pagination should stay visible for consistency), Material UI `TablePagination`, Ant Design
(`hideOnSinglePage` defaults to false), AG Grid, Atlassian.

**With Stripe's control set rather than the full one.** `‹ Prev` and `Next ›` always; `« First`
and `Last »` only when there is more than one page. Four dead controls under a three-row table
is chrome that does nothing, and on a single page First and Last do not name anything at all.

**Rejected: the count in the card header** (GitHub, Salesforce Lightning, Linear). It is the
better idea in the abstract — the count reads before the table rather than after it, which is
the order you want when the question is "did that filter do anything?" — but sixteen index
cards in this app have no header, and would grow a 57px one directly below a summary card that
already carries a scope sentence. Two counts, 60px apart.

**Disabled is `<span aria-disabled="true">`, not a disabled link.** An `<a>` cannot be disabled:
it stays focusable and announces nothing. This is already the rule here — `ui_helper.rb:226`
renders an unavailable action as a non-focusable span for exactly that reason. Styling hangs off
the attribute so markup and appearance cannot disagree. `opacity: 0.6` on slate-600 measures
2.88:1 against white where a live link is 7.56:1. `slate-300` was tried first and is 1.48:1,
which is not inactive so much as gone.

**Kaminari renders nothing for one page, deliberately.** `Paginator#render` is
`instance_eval(&block) if @options[:total_pages] > 1`, and returns `nil` so the call site can
supply fall-back HTML — the gem's own comment says so. The single-page control set is therefore
written out in `_pagination.html.erb` rather than in `app/views/kaminari/`, which is why those
three controls appear in two places in the codebase.

**Two bugs this surfaced, both of which had been passing.**

`/product_drives` read "Showing 1–2 of 2 product drive". Kaminari's `entry_name` calls
`model_name.human(count:)`, and Rails only pluralises a locale entry written as a `one`/`other`
hash — `product_drive: "Product Drive"` in `en.yml` is a plain string, so it came back
unchanged. The helper forces the number itself now. `donation_site` is the other one written
that way and would have had the same fault.

`admin/organizations_system_spec` had a context called "there are no organizations" that
asserted `Next ›` and `Last »` were absent. Both claims were wrong: the super admin factory
creates an organization of its own, *after* the `Organization.delete_all` in the `before` block,
so the list held one row — and the assertion passed only because a single page drew no Next.
The context now filters to nothing, which is the only way to get an empty list on that page, and
asserts there is no strip at all.

## 2026-08-21 · The row action was Turbo's, and should not have been

`storage_location_system_spec:167` had been failing about half the time for a week. It was
recorded twice as an intermittent flake and measured at 4 runs in 8 on a clean `HEAD`. It was
not a flake; it was a real defect in every row action in the app, showing up half the time.

**What the evidence said, in order.** The failing and passing runs made *identical* server
requests, so it was not the backend. A probe on the real spec showed that on a failure the page
never changed at all: same filtered URL, previous flash still above the table, Reactivate still
on screen three seconds after the confirm was accepted. Listening for rails-ujs events showed
`confirm:complete answer=true` and a `submit` event with the right action on failures as well as
passes — so the confirm was accepted and the form *was* submitted.

**The cause.** Row actions are `button_to` forms, and the tables sit inside a results
turbo-frame. Turbo's `elementIsNavigatable` returns true for anything inside a frame **even when
Drive is off**, which it is app-wide here. So Turbo intercepted the submission, fetched the
redirect, and then had to promote it to a top-level visit because the frame carries
`target="_top"`. That promotion is where it came apart.

**The fix** is `data: {turbo: false}` in `essentials_action_button`, so the browser submits the
form itself. A row action is a whole-page navigation ending in a redirect and a flash, not a
frame update, so opting out is what it wanted all along. 0 failures in 20 runs, against 4 in 8
before. The full suite passes.

**What this says about the earlier judgement.** Writing it down as "a pre-existing flake, not
mine" was true and verifiable — it did fail on a clean `HEAD` — and it was still the wrong
place to stop. A test that fails half the time is not noise, it is a defect with a poor
reproduction, and the reproduction here took about twenty minutes of instrumenting rather than
re-running. The rule worth keeping: measure the rate before attributing, then, if the rate is
high, treat it as a bug rather than a flake.

## 2026-08-21 · Inert class names removed rather than documented

Twenty-three class names that styled nothing and that no JavaScript, spec or gem selected were
deleted. They had been written up as known-harmless leftovers a day earlier, on the principle
that a documented leftover costs nothing.

That principle is right when the list is long and uncertain. It was wrong here, for one reason:
**a permanently non-zero audit is one people stop reading.** With 26 known-and-fine findings in
the output, the twenty-seventh — a real one — arrives invisible. Zero is the only count that
makes the next defect stand out, and the documentation of what was removed lives in the change
log and in `migration-map.md` either way.

Three of the twenty-six turned out not to be inert at all, and each would have been deleted if
the script had been trusted rather than the individual entries checked:
`filterrific-periodically-observed` and `form-inputs` belong to gems, and `filter-bar-submit` is
defined in an inline `<style>` inside a `<noscript>` — it is what makes the filter bar work
without JavaScript. The script now scans gem `lib/` directories and inline `<style>` blocks, and
those three are reported as hooks.

**Not removed: the pulse animation's intent.** `animate-pulse-once` is gone, but restoring the
effect on the partner request success and error messages is a `@keyframes` and one class. That
is a design decision, so it is offered rather than taken.

## 2026-08-21 · Responsive: three measurements that lie, and one that does not

The app was audited at 320, 375, 768, 1024 and 1440 — 700 page/width combinations. The
interesting part was not the defects; it was that finding them at all required throwing away
the obvious way to measure.

**`document.documentElement.scrollWidth` over-reports.** It counts content clipped inside a
scroll container. A data table in `.table-scroll` makes it read ~1141px on a 320px screen even
when the table is properly contained. A previous author had already found this and written it
down in `wcag-manual.js`.

**`document.body.scrollWidth` under-reports.** It sat at exactly 320 on a page that really did
scroll 821px sideways. That is what let `/items` ship broken: the check tested `bodyOverflow`,
which was 0.

**`window.scrollTo(9999, 0)` over-reports, differently.** It scrolls past `overflow-x: clip`,
which a finger cannot. It is also the measurement `wcag-manual.js` took, stored in a variable
called `scrolled`, and then never read. Wiring that variable up reported four pages nobody can
actually scroll.

**Swiping and reading where the `<h1>` ended up is the only one that matches the user.** Both
audits do that now.

### What the swipe found

`/items` at 320px could be swiped 821px to the right: the heading went from `left: 16` to
`left: -805`, and the user was left looking at blank space with every control off screen. The
screenshot at rest is 33KB; the screenshot scrolled right is 5KB, and the only thing painted in
it is the dev profiler badge.

The cause is a genuine Chrome behaviour: content clipped inside a scroll container still counts
towards the *root's* scrollable overflow. The table was in a working `overflow-x: auto`
container, inside an ancestor with `overflow: hidden`, and the page scrolled anyway.
`min-width: 0` on the flex ancestors changes nothing. Only clipping the root does:
`html { overflow-x: clip }`.

`clip` rather than `hidden`, because `hidden` makes the root a scroll container and can break
`position: sticky` descendants — the sidebar is `lg:sticky`. Both were measured against the
sticky sidebar at 1440 and both held in Chrome, but `clip` is the one that is correct by
construction. `overflow-x: hidden` stays in front of it for Safari below 16.

### Tap targets, and the cost of a check that cries wolf

WCAG 2.5.8 (AA) is 24×24, and a naive implementation of it is worse than none. The first pass
reported 28 failures on the dashboard and 109 across the app. Almost all were wrong:

- **28 on the dashboard** were date links in table cells that pass the *spacing* exception.
- **Most of the rest** were select2's leftover native `<select>`, which it leaves in the DOM at
  1×1 while drawing its own control beside it. Not a target anyone can hit.
- **The checkbox findings** measured a 16×16 box and ignored its label. Clicking a `<label for>`
  activates its control, so the target is the union of the two.

With inline, spacing, and label-union applied, 109 findings became 8, and all 8 were real.

**Where the 24px floor is not the standard.** A control that only exists on touch gets 44×44 —
Apple's HIG and Material both say so, and 24px is a floor for things that happen to be small,
not a target to design to. The drawer's open and close buttons were `p-2` and `p-1`, giving
32×32 and 22×32; both are `size-11` now.

## 2026-08-21 · The date range applies itself, and reorders itself

Three changes to the date range filter, all of them removing something.

**The Apply button is gone.** It was a second click for something the user had already said.
Stripe, Shopify, Linear and Notion all commit a date range on selection; Google Analytics is the
well-known exception, and the Apply button is the thing people complain about in it.

The argument for keeping it was real and is recorded in the old comment: with two separate date
fields rather than a calendar, committing on `change` means setting From and then To costs two
requests, and the first one queries a range nobody asked for. That is a timing problem, and the
answer is a 350ms debounce, not a second click.

Two details make it work:

- **The panel stays open** while custom dates are edited, so the range can be adjusted without
  reopening it; only choosing a preset closes it, because a preset is a complete answer. The
  spec helper `open_date_range` had to become idempotent — clicking a trigger that an open panel
  is covering is a Cuprite failure, not a no-op.
- **The From/To fields stop their `change` event bubbling.** They sit inside the filter bar's
  form, and the bar submits on any change that reaches it — so before this, editing a date fired
  a query carrying the *previous* range from the hidden field, then a second one when the
  debounce committed the new one. Measured on `/donations`: three requests for one edit, now
  one, and the one carries the right range.

**An end before a start is reordered rather than refused.** It used to show "The end date must
be on or after the start date." and do nothing until the user fixed it. Google Flights, Airbnb,
Booking and Material's range picker all reorder or reset; none of them argue with you. There is
no error state left in the control, which is also one fewer thing to keep accessible.

**The trigger shows US short dates.** Spelled out, a custom range read "June 19, 2026 to
September 19, 2026" and needed 233px inside a 223px button, so it was truncated — the one thing
the control exists to tell you was the part cut off. `6/19/2026 – 9/19/2026` is 134px in the same
button. The wire format is untouched: `filters[date_range]` still carries "%B %-d, %Y" because
that is what `strptime` on the server is waiting for, and `:date_picker_short` is display only.

## 2026-08-21 · Second responsive pass: the breakpoints themselves, and what a squeezed page loses

The first pass checked three things at five widths and came back clean. Widening the question —
"works correctly at all viewport sizes" is more than "does not scroll sideways" — found one real
defect and taught the audit four things.

**Test the two sides of each breakpoint, not the middle of each range.** The widths are now 320,
375, 639, 641, 767, 769, 1023, 1025, 1280 and 1440. 639 and 641 are different layouts and only
one of them ever gets looked at by hand; a layout that breaks does it at the switch.

**Overlays have to be opened at phone size.** `overlay-audit.js` ran everything at 1360×900,
where an overlay is least likely to overflow. At 320×640 the date range popover ran **143px off
the bottom** on three pages. Its controller already flipped above the trigger when there was more
room there — but at 320 there was 307px below and 301 above, so neither side fit and it did not
flip. When neither side fits it caps its height and scrolls now, which is what Stripe and
Material do before falling back to a full-screen sheet.

**Four false-positive sources, each of which would have made the audit unreadable.** This keeps
happening, and the pattern is worth naming: a new check is nearly always wrong the first time,
and the wrongness always looks like a pile of findings.

| Reported | Actually |
| --- | --- |
| 43 findings of "text clipped with no ellipsis" | `<option>` elements inside select2's leftover 1×1 `<select>`. Nothing is clipped; the select is hidden by design. |
| "no drawer toggle" on three pages | The auth shell and the static pages have no sidebar, so there is no navigation for a drawer to open. |
| "sidebar is on screen below lg" | Measured 120ms after a resize, mid-way through the sidebar's `duration-200` slide back off-canvas. |
| "fixed chrome covers 360px of a 360px viewport" | reCAPTCHA's overlay at `z-index: 2147483640`. The app's own highest is `z-40`; anything past 100 belongs to somebody else. |

**One thing reported here that turned out to be nothing, and how the probe fooled itself.** This
entry first said reCAPTCHA rendered a challenge overlay over `/account_requests/new` and blocked
the name field at every width. It does not, and there is no defect.

`#account_request_name` is hidden until an account type is chosen — the form opens on "I am an
Essentials Bank" / "I am a Partner Agency" and reveals its fields after. The probe filled the
field without choosing, so it timed out on a hidden element whose rect is `[0, 0, 0, 0]`; then
`elementFromPoint(0, 0)` returned whatever sits in the top-left corner of the screen, which is
**rack-mini-profiler's badge** at `z-index: 2147483643`. A huge z-index was read as reCAPTCHA's
and the story was built from there.

Verified after choosing the account type: the field fills at 1440×900, 740×360 and 320×640, and
the reCAPTCHA widget is present and blocking nothing. The site key in `.env` is Google's official
always-pass test key, which is exactly the right thing for development.

The lesson is about the probe rather than the app: **`elementFromPoint` on an element with a zero
rect is a question about the origin of the viewport, not about that element.** Check that a
target has a size before asking what covers it.

## 2026-08-21 · Required fields and validation errors: three fixes in the system, four in controllers

Every form audited by opening it, reading how its required fields are marked, submitting it
empty and reading what came back — `bin/design/form-validation-audit.js`. **All 32 forms had
findings.** Two changes to the design system cleared 19 of them; the rest were per-controller.

### The systemic three

**`aria-required`.** simple_form derives the `required` attribute from
`required_field? && SimpleForm.browser_validations`, and browser_validations is off here —
deliberately, because the server validates and a browser bubble competing with a rendered error
is two answers to one question. Turning it off also removed the only programmatic signal that a
field is required. The label's `<abbr title="required">*</abbr>` is read by most screen readers
as "star". `EssentialsInputAria` puts the state back without the browser's UI.

**`aria-describedby`.** simple_form rendered the error text into a `<p>` with no id, so nothing
tied it to the field: a screen reader user tabbing into an invalid field heard the label and
nothing else. The message is now wrapped in a span with an id and the input points at it. The
`<p>` cannot carry it — wrapper options are static and the id has to be per-field.

**The asterisk had nothing saying what it meant**, on 27 forms. `abbr@title` covers a screen
reader; a sighted user got a bare glyph. `essentials_form_for` renders the legend now, hidden by
`form:has(label abbr[title="required"])` so it cannot be forgotten on a new form and cannot lie
on a form with nothing required. Scope the `:has()` to `label`, or the legend's own `abbr`
satisfies it and the line shows everywhere.

### What the controllers were doing

**Rebuilding the record that failed.** `items`, `kits` and `admin/users` each caught a failure
and rendered a *fresh* object built from the same params, with the real errors flattened into a
flash sentence. Every field came back clean — no message, no red border, no `aria-invalid` — and
the only sign of trouble was a line at the top of the page. Re-render the record that failed.

**`/admin/questions` returned a 500 on every invalid submission.** The failure branch called
`@question.punctuate(@question.errors.to_a)`, and `punctuate` exists nowhere in the app. Both
`create` and `update` did it. The form now shows its errors and the flash is gone.

**The error summary did not link to anything**, while its own comment said it did — "links each
message to its input so a keyboard user can jump straight to the problem" above a plain `<li>`.
It links now, which is the GOV.UK pattern and the reason a summary is worth having.

### What the audit had to be taught

The same lesson as every other audit this week, and it is now four for four: **a new check is
wrong the first time and the wrongness looks like findings.**

- A radio or checkbox is marked on its group's `<legend>`, not on each option. Flagging all three
  delivery-method radios was wrong; "Delivery method *" is right.
- A conditionally required field cannot carry a truthful marker. Product drive participants need
  a business name *or* a contact name and say so in words; none of them is required alone, so
  none should have `aria-required`.
- A form that accepts an empty submit, or one whose fields are hidden until a choice is made, is
  not a form that fails to show errors — there were none to show. Reported separately.

### The last four, finished

**`partners/users` redirected on failure**, so the entered name and email were thrown away along
with the errors and the form came back empty under a flash. It re-renders now. Its view was also
the last form in the app built from `form_for` with hand-rolled `label`/`text_field` pairs, which
is why it had no required marker, no `aria-required` and no inline errors — it is
`essentials_form_for` with `f.input` like everything else.

**`partners/family_requests` did the same** and additionally had nowhere to show an error: the
view never rendered `@errors`. It re-renders and shows them.

**`/audits/new` and `/account_requests/new` were not defects.** The probe could not drive either:
the audit form's submit carries `data-confirm`, and a dialog nobody accepts cancels the
submission; the account request form hides its fields until an account type is chosen, so an
empty submit never leaves the page. Driven by hand, audits shows a summary, one inline message
and `aria-invalid`; account requests re-renders with "Invalid captcha submission", which is
reCAPTCHA declining a headless submit rather than the form failing.

Both taught the tool something. It accepts dialogs now, and it sets a marker on `window` before
submitting so "the form did not submit" can be told from "the form submitted and came back with
nothing" — and it reports the forms it could not exercise **even when there are no findings**,
because a form the probe cannot drive is not a form that passed, and hiding that behind a clean
result is how a green audit lies.

One thing removed while there: `audits_controller#handle_audit_errors` built a flash out of the
same errors the summary and the fields now show, and became dead code.

## 2026-08-21 · Accessibility and keyboard: the drawer nobody could see, and 91 pages axe was not looking at

### axe was auditing 61 pages of 152

`wcag-audit.js` walked four hand-kept lists. `route-targets.rb` enumerates 163 routes. Pointing
axe at the router took it from 61 pages to 152 and immediately found three violations and a 500
that the lists had never visited:

- **`scrollable-region-focusable`** on the three historical trend pages. `.table-scroll` can be
  scrolled with a mouse and by nothing else. It surfaced there and nowhere else because every
  other table in the app contains links, which give the region a way in by accident — the fault
  was app-wide and visible on three pages. All 62 scroll containers are focusable now.
- **`aria-input-field-name`** on `/admin/users/new`, twice over. See below.
- **`color-contrast`** on `/privacypolicy`: the footer copyright at 4.06:1 against the 4.5 AA
  needs. `#a0aec0` is 7.23:1.
- **`/partners/authorized_family_members/new` returned a 500.** Its route is not nested under
  families, so `family_id` arrives as a query parameter; without one, `family` was nil and
  `family.authorized_family_members` raised. Every link supplies it. A bookmark does not.

This is the third audit this week whose real finding was hiding behind a hardcoded list. Ask the
router.

### The drawer was 27 invisible tab stops

Below `lg` the sidebar is moved off screen with `-translate-x-full`. That hides it from the eye
and from nobody else: closed, all 27 of its links and buttons stayed in the tab order. A keyboard
user on a phone tabbed from "Skip to main content" through the entire navigation — invisible,
with no indication of where focus had gone — before reaching any page content.

`inert` is what removes a subtree: out of the tab order, out of the accessibility tree, and
without the `display: none` that would break the slide. `shell_controller` sets it on close,
clears it on open, and **recomputes it on resize**, because at `lg` the sidebar is a visible
column and must not be inert whatever the drawer's last state was.

**It was invisible at 1280 and 27 stops deep at 375**, which is the argument for running the
keyboard audit at both widths rather than one.

### select2 names nothing it builds, and is initialised twice

select2 hides the `<select>` and builds a combobox, a value display marked `role="textbox"`, and
a search input. None inherits the original's name, and the combobox's `aria-labelledby` points at
its own value container — empty until something is chosen.

The naming had already been written once, in `select2_controller`, for the search field. It did
not apply to `/admin/users/new`, because **that select is initialised by `double_select_controller`
instead** — a second call site the first fix never knew about. It is a shared util now, used by
both, and it names all three generated elements. The label's id goes in front of select2's
container id rather than replacing it, so the control announces its name and then its value.

### What the keyboard audit had to be taught

Fifth audit, same lesson. Two false positives, both decoration:

- the drawer scrim, which is `aria-hidden`, closes on click, and whose behaviour is also on
  Escape and on a real close button;
- a `<dialog>`'s own click handler, which is backdrop dismissal — the keyboard equivalent is
  Escape, which the browser provides and `overlay-audit` checks on every dialog.

Requiring either to be focusable would have put an unnamed tab stop in everyone's way. And the
check had to learn that `inert` removes a subtree, or it went on reporting the drawer it had just
been used to fix.

## 2026-08-21 · Dead routes: 29 that could not work, removed rather than filled in

`bin/rails runner bin/design/dead-routes.rb` asks of every route whether the request would
raise. Of 375 verb-and-path combinations, **28 would**, and one more resolved somewhere other
than where it was declared. They are gone; the audit reports 0 of each over the remaining 346.

They were not a scattering. Almost all of them are the actions `resources :x` generates and the
controller never implemented — `resources` writes seven, most of these controllers implement
three or four, and the rest sat in the routing table looking like features:

| Where | Dead |
| --- | --- |
| `requests` | `new`, `create`, `edit`, `update`, `print`, and `partner_requests` |
| `users` | `show`, `edit`, `update`, `destroy` |
| `kits` | `edit`, `update`, `destroy` |
| `admin/users` | `show`, `destroy` |
| `admin/partners` | `destroy` |
| `admin/questions`, `admin/broadcast_announcements`, `broadcast_announcements` | `show` |
| `adjustments` | `destroy` |
| `partners#profile` | GET and PATCH |
| `partners/authorized_family_members` | `index` |
| `partners/donations` | the whole controller, which does not exist |
| `manufacturers#import_csv` | the whole feature, which was never built |

**Removed rather than implemented, because nothing was asking for them.** Eleven named helpers
disappear with these routes and not one is referenced anywhere in `app/`, `spec/` or `lib/` —
no view links to them, no spec exercises them, no hardcoded path string reaches them. A dead
route is not a feature request; it is the default output of a macro. Writing eleven actions to
satisfy a routing table would invent product that no one designed, and each one is a URL a
stranger can reach. Deleting them is one line each to undo.

**What a user could hit before this.** These were not all unreachable in practice. `resources`
puts them at guessable URLs, and three of them were reachable by typing: `/partners/donations`
raised `uninitialized constant Partners::DonationsController`, `/broadcast_announcements/1`
raised a missing action, and `/requests/new` — a plausible thing for a bank user to try, since
the index is full of requests — raised rather than saying requests come from partners.

### Two things the audit had to be taught, which is now six audits in a row

**Reading each route's own controller and action is not enough, because another route can
answer first.** The first version reported `POST /users` as dead: `UsersController` has no
`create`. Devise's registration route is declared earlier and handles that path. Only
`recognize_path` knows which route wins, so that is what the tool asks. This is also what makes
the shadowing check possible at all.

**And `recognize_path` cannot be trusted to say nothing is there.** It runs outside a request,
so a route behind a constraint that needs one raises `RoutingError`. The second version treated
that as "skip", which quietly dropped `/partners/donations` — the one dead route I had already
found by eye the day before, and the reason this cleanup was asked for. A tool that silently
omits the known answer will silently omit the unknown ones. It falls back to the declared target
now, and 28 became 29.

### A collection route under a member route is unreachable

`resources :requests` was declared **twice**, and the second declaration's collection routes sat
below the first's `/requests/:id`. `/requests/partner_requests` resolved to `requests#show` with
an id of `"partner_requests"` — not a 404, a wrong page. It is one declaration now. The general
rule is worth keeping: routes match in declaration order, so a literal segment must be declared
before the `:id` that would swallow it, and two `resources` blocks for the same name interleave
in a way nobody reading either one can see.

### The manufacturers CSV import: the button went too, not just the route

`POST /manufacturers/import_csv` had a trigger button and a modal on the index page, and nothing
else. `ManufacturersController` does not include `Importable`, `Manufacturer` has no
`import_csv`, and `public/manufacturers.csv` — the template the modal offered to download —
does not exist. Every layer was missing; the button raised.

Six controllers include `Importable` and five of them render this modal. Manufacturers was the
one page where the UI had been built and the feature had not. It **predates this branch** — the
same modal is on the pre-migration view at `ae97376d1` — which is the interesting part: a
faithful rewrite carries a broken feature across intact, because the rewrite's question is
"does it look right", and it did.

Removing the UI rather than leaving it pointed at nothing is the same judgement as the routes.
If manufacturer import is wanted, it is four small pieces and one of them is a one-line
`include`; what should not stay is a button that offers it and raises.

## 2026-08-21 · The unreachable `Importable`, and a probe that measured the wrong thing

`ProductDrivesController` included `Importable` and nothing reached it: no `post :import_csv` on
`resources :product_drives`, no `ProductDrive.import_csv`, no template CSV. Unreachable code
rather than a dead route, which is why the route cleanup earlier the same day left it alone and
merely wrote it down. Removing it was the right follow-up: the four layers of CSV import now
correspond exactly — five controllers, five routes, five models, five templates, the same five
each time — and that is a property you can check, where "five and a half" is not.

**The include was doing one thing that looked load-bearing.** `Importable` carries

```ruby
included do
  helper_method :current_organization, :current_user
end
```

so removing it could plausibly take `current_user` out of the views — and
`product_drives/show.html.erb` calls `current_user.has_cached_role?` to decide whether to draw
Delete. The first probe said exactly that: `_helper_methods` lost `current_user`, and the page
looked like it would raise.

It was wrong, in a way worth remembering. **`bin/rails runner` does not draw the routes unless
something asks for them**, and Devise registers `current_user` as a helper from `devise_for`,
when the routes are drawn. Probing a fresh runner therefore reports the state of the app *before
Devise has spoken*:

```ruby
ProductDrivesController._helpers.instance_methods.include?(:current_user)  # => false
Rails.application.routes.routes.first                                      # draws them
ProductDrivesController._helpers.instance_methods.include?(:current_user)  # => true
```

`current_user` comes from `ActionController::Base::HelperMethods` and `current_organization` from
`ApplicationController`. The concern's `helper_method` line is redundant for both, and has been
for as long as both existed. It is left in place: it is shared by five controllers, and this
change was about the one that should not have been including it.

The thing that settled it was not a better probe but the app itself — the request spec renders
`show` and asserts on its body, and a cold-booted server serves the page with the Delete button
on it. **When a static probe and a running request disagree, the request is right.**

## 2026-08-21 · Dead code: 118 findings, two live defects hiding behind them, and thirteen false positives first

`bin/design/dead-code.rb` is the companion to `dead-routes.rb`. That one asks for routes with no
code behind them; this one asks for code with nothing in front of it — no route, no render, no
caller. It reports **118**:

| What | How many |
| --- | --- |
| Controllers no route reaches | 6 |
| Actions no route reaches | 2 |
| Templates nothing renders | 1 |
| Partials nothing renders | 4 |
| Helper methods nothing calls | 24 |
| `public/` files nothing references | 81 |

Services, query objects, jobs, mailers, events, concerns, Stimulus controllers, importmap pins
and CSS component classes are all clean at zero. The object layer is tight; the rot is in the
view layer, the helpers, and the things a migration leaves on disk.

### Five of the six dead controllers are Devise overrides that Devise never asked for

`app/controllers/users/` holds seven controllers. **Two are routed.** `devise_for :users` names
only `sessions` and `omniauth_callbacks`, so passwords, registrations, invitations, confirmations
and unlocks are served by Devise's own classes. The app's versions are empty shells — `def new;
super; end` and a `layout` line — and one of them,
`Users::InvitationsController < Devise::SessionsController`, does not even inherit from the right
base class. Nothing noticed, because nothing runs it.

The views under `app/views/users/passwords/` and friends **are** live: `config.scoped_views = true`
sends Devise's own controllers to look there. Views live, controllers dead, in the same directory
tree — which is most of why this survived.

Two of the five are dead twice over: the `User` model enables neither `confirmable` nor
`lockable`, so `users/confirmations/new.html.erb`, `users/unlocks/new.html.erb` and four mailer
templates cannot be reached either, and `config/application.rb` sets a layout on two Devise
controllers that have no routes at all.

### The dead file was hiding a live defect

`app/controllers/users/invitations_controller.rb` sets `layout "essentials_auth"`. It never runs.
The controller that does run, `Devise::InvitationsController`, was **not** in the `to_prepare`
block that assigns the auth layout, and `layouts/application` was deleted with AdminLTE. An
unnamed layout is optional in Rails, so nothing raised: `/users/invitation/new` and
`/users/invitation/accept` returned **200 OK with no layout at all** — no stylesheet, no nav,
Times New Roman. That is the first screen every invited user sees.

**And the audit that should have caught it was skipping those routes.** `route-targets.rb` had

```ruby
next if controller.start_with?("rails/", "turbo/", "active_storage/", "devise/")
```

which is defensible right up until you notice that `devise/` **is** the auth screens here. The
app having a `users/invitations_controller.rb` made the family look covered. Both are fixed: the
layout is assigned, and the sweep visits Devise-served screens — 139 screens became 140, and axe
went from 152 pages to 154.

This is the same shape as the manufacturers CSV import and the `Importable` include: a piece of
dead code that looks like the thing being done, so nobody looks for the thing actually doing it.
Three times in two days is a pattern worth naming. **Dead code is not inert. It answers the
question you were about to ask, wrongly.**

### The other live defect: a template link that never pointed at anything

The product drive participants import offered `/product_drive_participants.csv`. The file on disk
was `diaper_drive_participants.csv` — renamed everywhere except here when diaper drives became
product drives. Its contents are right, headers and all. The file is renamed rather than the link
changed, because every other template is named for its resource. This one predates the migration.

### A third variant of "the probe and the app disagreed"

The sweep reported the invitation page unstyled after I had fixed it and watched it render in
Figtree three times. Both were true. **The browser audits default to `BASE_URL=127.0.0.1:3000`
and I was verifying on 3003**, a second server started for the same repo — and
`config/application.rb` is not reloaded in development, so the long-running 3000 process was
still serving the old layout configuration hours after the file changed.

The rule from the `Importable` entry was "when a static probe and a running request disagree, the
request is right". It needs a clause: **and check they are the same running app.** Guessing cost
four rounds; dumping the URL alongside the failing HTML answered it in one.

### Thirteen ways to be wrong about dead code

Every check here was wrong on its first run, and each time the wrongness looked exactly like
findings. In order of how much they would have cost:

1. **The design system's own fonts.** Figtree and Bootstrap Icons are named only by `@font-face`
   in the stylesheet. Drop `.css` from the source glob and the audit recommends deleting the
   fonts every page depends on. This one would have taken the whole site down.
2. **`\b` after a name ending in `?`.** `foo?(x)` has no word boundary between the `?` and the
   `(`, so the first helper pass called every predicate in the app dead: 12 of 33.
3. **A lookbehind excluding `:`.** Added to skip `Foo::Bar`, it also skips `before_action
   :require_admin` — so a method with its `before_action` three lines above it read as uncalled.
4. **`render partial: "partners/profiles/show/#{x}"`** names a directory, not a file. 24 live
   profile sections in the first run of 46.
5. **"Is `index` used anywhere?"** is true in every codebase ever written. Asking the whole app
   instead of the controller suppressed both real findings in that category.
6. **Receiver methods.** `item.active?` is a method on a struct, not a helper. Reflection —
   `instance_methods(false)` — knows the difference; scanning `def` lines does not.
7. **`clock.rb` and `Rakefile` live at the repo root.** A glob starting at `app/` reports all
   three jobs Clockwork schedules as dead.
8. **Unqualified constants.** Code inside `module Partners` calls `UpdateFamily`.
9. **`site.webmanifest`** is the only thing naming the android-chrome icons, and it is not Ruby.
10. **fullcalendar 6 imports preact, luxon and `@fullcalendar/core/` itself.** No static read of
    our code can see a CDN module's own imports.
11. **`sinon`** is imported from a `<script type="module">` in an ERB partial.
12. **`"data-controller": "trigger-change-event"`** — the quoted-key hash form, alongside
    `data-controller=` in HTML and `data: {controller:}` in Ruby.
13. **Base classes and gem classes.** `HistoricalTrends::BaseController` has no routes of its own
    and every subclass does; `DeviseController` is not ours to delete.

The tool carries all thirteen as commented exemptions, because the next person to add a check
will hit the fourteenth.

### Reported, not removed

The 118 are a list, not a change. Removing dead code is a judgement per item — a `public/img`
logo may be somebody's brand asset, a helper may be about to be used by the page being written
this week — and the ask was an audit. The two **defects** are fixed, because those are bugs. The
dead code is written down here and in the change log, and stays until someone decides item by
item. It was 119 until the CSV template was renamed: fixing that link took the file it should
have been pointing at off the unreferenced list.

The one number worth acting on soon: **6.1MB of `public/fonts` and `public/webfonts` is Font
Awesome, Lato and Raleway**, none referenced since ADR 0011 removed AdminLTE.

## 2026-08-22 · The account menu shows the avatar, not the name

The trigger in both top bars was avatar, then name, then chevron — `current_user.display_name`
on the bank side and `current_user.email` on the partner side. It is the avatar and the chevron
now, and the name moved nowhere: the panel already opened with the name, the email and the role,
which is why removing it from the bar costs nothing.

The name in the bar was the only text on the page guaranteed not to change between screens. That
is precisely what makes it expensive — it sits at the top right, where the eye goes for the page
actions, and it is the one thing there that is never the answer to anything. Both copies were
already conceding the point at small widths (`hidden … sm:block`, `max-w-[12rem] truncate`), so
the layout had two behaviours to reason about and the narrow one was the honest one.

**The chevron stays.** It was tempting to read "just the avatar" as the whole trigger, but the
chevron is the only thing marking a circle of letters as a control rather than decoration, and
`aria-haspopup` says so to everyone except the people looking at it.

**Removing the name removed the accessible name with it.** The avatar span is `aria-hidden` —
correctly, since "JB" read aloud is noise — so with the text gone the button had nothing left to
announce, and design.md's rule that a control with only an icon carries its own `aria-label` had
just started applying to it. It is `aria-label="Account menu for …"`, interpolating the same
expression the avatar uses. Plain "Account menu" would have satisfied the rule and quietly lost
information a sighted user still gets from the initials.

Two things noticed in passing and deliberately left alone, both older than this change:

- The trigger has `aria-expanded` but no `aria-controls`; the panel has no `id` to point at. The
  accessibility rules in design.md ask for both on anything that opens a region.
- design.md says the organization's name is in the top bar. It is in the sidebar
  (`_essentials_sidebar.html.erb:12`). The claim about tenancy being visible holds; the location
  in the sentence does not.

## 2026-08-22 · The button between the tab strip and the table

Four of the five tabs on `/items` carried a full-width strip holding one secondary button,
between the tab strip and the first row. Measured in Chromium at 1440×900: **55px** on each of
Item categories, Items quantity and location, Item inventory and Kits.

This was not an open question. `design.md` already said both halves of the answer — the page
header rule ends "do not tuck it above a table; see the tabs rule below", and the tabs rule says
"prefer page tabs when a tab needs its own action". `partners/index` and `partner_groups/index`
had already been converted for exactly this reason. `/items` was the page the rule was written
about and never applied to.

### Two of the four were not a design question

"Items, quantity and location" and "Item inventory" both offered **New item** — the page
header's own primary action, eleven lines up in the same template, rendered a second time 55px
below as a secondary. Deleting those two was the whole fix for them: no decision, no regression,
110px back. That went in first, on its own, so the interesting change would not be carrying it.

### What the industry does, and why the header wins

GitHub, Linear, Stripe and Shopify all put the tab-scoped action in the page header and make the
tabs URLs. Atlassian and Material are the only mainstream systems that sanction a trailing action
on the tab row itself. Nobody puts a band between the strip and the first row.

The tab-row variant was the tempting cheap option — no routing, panel tabs stay — and it was
rejected on measurement rather than taste. The five labels are **598px** at every width. The
tightest container is **702px at a 1024px viewport**, the fixed sidebar taking the rest, leaving
**104px**; "New item category" is **146px**. It wraps at 1024 and below, which is the 55px strip
again with a worse border. It only works from about 1100px up.

### Five page tabs, three controllers

| Tab | URL | Primary action |
| --- | --- | --- |
| Item list | `/items` | New item |
| Item categories | `/item_categories` | New item category |
| Items, quantity and location | `/items/quantity_and_location` | New item |
| Item inventory | `/items/inventory` | New item |
| Kits | `/kits` | New kit |

The two matrix views are collection routes, so they resolve ahead of `items#show`. Verified:
`dead-routes.rb` reports 0 dead and 0 shadowed over 349 routes.

`item_categories#index` had been excluded from the resource (`except: [:index]`) because the
categories table lived inside `items#index`. Creating or deleting a category redirected to
`items_path`, which is to say: to a different tab from the one you were on. Both redirect to
`item_categories_path` now.

**Kits keeps its own title.** The partners precedent has an identical header on both tabs, which
makes the pair read as one page. Kits cannot do that, because it is also a sidebar destination —
clicking "Kits" in the rail and landing on a page headed "Items & inventory" would make the
sidebar lie. It keeps "Kits" and its own filter bar, and renders the strip so the tab is a way
back as well as a way in. This is the one place the two precedents disagree, and the sidebar wins.

### A performance consequence that was not the point

`items#index` built all five tabs' data on every request — the item list, the categories, the
per-storage matrix, the inventory tree and the kits — whichever tab you were looking at. The
expensive one is `ItemsByStorageCollectionAndQuantityQuery`, and the item list paid for it on
every visit. It is a `before_action` on the two matrix views now.

### Filters were deliberately left out of the rule

The rule is phrased "except that table's own filters", and the carve-out is doing work. The
"Inventory" tab of `storage_locations/show` has a band in the same position, holding "Show
inventory at date" and a View button. It is **125px** — more than twice the strip this change
removed — and it stays.

A filter changes the rows underneath it, so being adjacent to them is the point; an action
creates a record and navigates away, and has no relationship to the rows it sits on. Same shape,
opposite job. A rule that caught both would also contradict the filter bar rule — "a plain bar
sits 16px above the table it filters" — on all 19 pages that use the component. And moving this
particular filter would make it lie: `version_date` scopes one of three tabs, and the standard
position is above the card, where it would appear to scope all three.

Two things about that band are wrong for other reasons, and are a filter-consistency job rather
than this one:

- It is hand-rolled `form_for` + `label_tag` + `date_field_tag` + a bare submit, not the
  `filter_bar` and `filter_*` helpers 19 other pages use. `admin/barcode_items/index` is the
  same class of defect — a filter card with its own "Filters" heading.
- **It works only because Inventory is the first tab.** Submitting reloads to `?version_date=…`
  with no fragment, and `tabs_controller` falls back to whichever tab the server marked selected,
  which is always the first. Put that filter on tab two and submitting would silently return the
  user to tab one. Verified in the browser. It is correct today by ordering, not by design.

## 2026-08-22 · Eight specs, and the page kind the audit did not have

The avatar change removed the user's name from the top bar and broke eight examples across
`account_system`, `organization_system` and `partners/coworker_invitations`. All eight had the
same shape: they opened the account menu by clicking the user's name or email, because that text
was the only handle on it. Two also asserted the name was visible on the page after saving it.

They use `[data-account-menu]` now — the hook `admin/users_system` was already using, which is
why that one spec kept passing — and the account spec opens the menu before looking for the
name, which is where the name now lives.

**Why they were not caught.** Only a subset of the system specs was run when the avatar change
landed: the shell, accessibility, layout, navigation and admin-users specs, chosen because they
were the ones that mentioned the topbar or the account menu. That was the wrong selection rule.
A change to a shared layout partial is a change to every page, and the specs that broke were the
ones that used the topbar incidentally, on their way to testing something else — which is
exactly the set that grepping for "topbar" does not find. `CLAUDE.md` says to run the system
specs for anything that touches a view; for a layout, that means all of them.

### A fifth page kind, and 25 views nobody was auditing

`page-audit.rb` classified every view as `show`, `index`, `form` or `partial`. Those four are not
exhaustive, and the new item pages proved it: a template named after a collection action —
`items/inventory.html.erb`, `items/quantity_and_location.html.erb` — matches none of the four
patterns, so it was scanned by nothing and counted in no total. It would have been possible to
add a page with a bare `card` class, an inline style and no `page_header` and have the audit
report zero defects.

The catch-all `action` kind fixes the shape of the problem rather than the instance:

```ruby
"action" => %r{\A(?!.*/_)(?!.*/(show|index|new|edit)\.html\.erb$).*\.html\.erb$}
```

Every view is now one of five kinds, so a page cannot fall out of the audit by being named
oddly. It found **25 templates that had never been audited** — and one genuine gap behind them.
The mailer exclusion is `rel.include?("_mailer/")`, which catches our own `distribution_mailer/`
and misses Devise's, which is plain `users/mailer/`. Six HTML emails were being read as app
pages, and reported as defects for having `<td>&nbsp;</td>` spacers in them — which is what HTML
email is made of. The exclusion takes both spellings now.

The per-kind totals were computed separately from the scan, with a shorter list of exclusions, so
every "N files" line was slightly too big: `index` counted `static/index.html.erb` and then
skipped it. There is one `audited?` predicate now and both go through it. The count moves from
330 to 354, and 0 defects is a claim about all of them for the first time.

### The dialog count that was already wrong

`overlay-audit.js` reports 4 dialogs where the change log had recorded 6. Before writing the
smaller number down it was measured at `c0de28eb1`, the branch tip before any of this work: 4
there too. The audit's nine pages include nothing these commits touched, and the likeliest
explanation is the manufacturers CSV import, whose modal was deleted along with its route in
`f644de0ef` — recorded in the change log, not carried into the verification line beneath it.

## 2026-08-22 · The storage location date band, and the filter nobody could see

The "Inventory" tab of `storage_locations/show` held the app's last hand-rolled filter: a
`form_for` with a `label_tag`, a `date_field_tag` carrying its own copy of the control classes,
a bare submit button, and a `w-full` hint paragraph that forced a second line. **125px**, always
open, while the nineteen other filtered pages used the `filter_bar` component. It is that
component now: **71px collapsed**, 183px open.

### It stays inside the tab panel

The component's documented home is 16px above the table it filters, which here would be above
the card — above the tab strip, where it would look like it scoped all three tabs while scoping
one. The rule written two commits ago allows a table's own filters between a strip and its first
row, and this is the instance it was written for.

### The frame is not decoration

`version_date` used to submit as a full page load, and a full page load re-renders the tab strip
with whichever tab the server marked `aria-selected`, which is always the first. **The filter
only worked because Inventory happens to be first.** Moving it to tab two would have silently
returned the user to tab one on every apply, and nothing would have failed. Applying into a
frame removes the question rather than answering it: the strip is never re-rendered. The rule in
design.md now says an in-panel filter must use a frame, and says why.

### `filters[…]` is reserved for scopes, which is why two helpers nest and two do not

The obvious move was to submit `filters[version_date]` like `filter_select` and `filter_text`.
That would have been a bug. `Filterable#class_filter` walks the `filters` hash and calls
`public_send(key, value)` on the model, so a name in there that is not a scope raises — and
`filter_params` is shared with `storage_locations#index`, which does call `class_filter`. This
is also, in retrospect, why `filter_checkbox` submits a bare param: `include_inactive_items` is
not a scope either. `filter_date` follows it, the split is written down in design.md, and the
existing `version_date` URLs keep working.

### The chip that never appeared

`filter_summary_controller` skipped **every** `input[type=date]`:

```js
if (field.type === "date") return []
```

That was correct while the only date inputs in a filter bar were the two inside the date range
popover, which reports through a hidden field — counting them too would chip one filter twice.
`filter_date` put the first standalone date input in a bar, and it inherited the exclusion: a
page arrived at by a filtered URL showed the right rows, the right caption and the field
correctly pre-filled, with **no chip, no count badge and no "Clear all"**. The only way back to
the unfiltered view was to empty the field by hand.

The discriminator is the one `clearField` was already using — whether the input is inside
`[data-controller~='date-range']`. Verified both ways: the standalone control now chips and
clears, and `/donations` still shows exactly one "Date range: Today" chip rather than three.

This is the second time in two days that a control was invisible to something because the
something assumed the four cases it had seen were all of them — `page-audit.rb` and its four
page kinds was the first. Both were found by adding a fifth case, not by reading the code.

## 2026-08-22 · The admin barcode filter, which had never filtered anything

`admin/barcode_items/index` was the other filter that was not the component, and rebuilding it
turned up something the styling was hiding.

```ruby
def index
  @barcode_items = BarcodeItem.global
  @items = BaseItem.alphabetized.all
end
```

**No `class_filter`.** The page rendered a "Filter by item category" select and a Filter button;
pressing it reloaded the same full list with the choice sitting in the query string. The private
`filter_params` method existed directly below and nothing called it. A request spec now covers
it, and it fails against the old action — that is how the claim was checked, because the dev
database has no global barcodes at all, so nothing on screen could have shown it either way.

An earlier attempt to demonstrate the bug in a browser did show "51 rows before, 51 rows after",
which looked like proof and was not: `BarcodeItem.global.count` is 0 in dev and those 51 rows
belonged to the modal's own tables further down the page. The number was real and meant nothing.
The evidence that counts is the spec.

### `filter_params` was carrying four names that are not scopes

```ruby
params.require(:filters).slice(:barcodeable_id, :less_than_quantity,
  :greater_than_quantity, :equal_to_quantity, :base_item_id)
```

Of those five, only `barcodeable_id` is a scope on `BarcodeItem`. `class_filter` calls
`public_send(key, value)` for every key it is given, so `?filters[base_item_id]=1` would have
raised the moment the filter was wired up — the fix for the dead filter would have shipped a
500 with it. It permits the one name the page offers, and `slice` became `permit`, which is what
it should have been.

This is the same hazard `filter_date` was designed around a few hours earlier, arriving from the
other direction: there, the question was which namespace a new control should submit under; here,
a namespace that had quietly accumulated names nothing would answer.

### What else went with it

The page was the last one built out of hand-rolled markup rather than components, and the filter
could not be replaced without replacing its surroundings:

- **Its div nesting did not balance.** Four closing tags with nothing open, and the table's card
  hand-rolled from `CARD_CLASSES` pasted inline. `page-audit.rb` did not report the pasted card,
  because it only reports one when the file renders no `shared/essentials/card` at all — and this
  file rendered one properly and then hand-rolled a second. Worth knowing; not fixed here.
- **"Add New Barcode" sat in the filter's button row**, beside Filter and Clear Filters. A page's
  main action goes in the page header; the filter bar's action cell is for applying and clearing.
  It is a primary action in the header now, and sentence case — "New barcode", the same label its
  non-admin twin uses.
- **No pagination**, where the twin paginates at `Pagination::COMPACT`. Global barcodes are
  unbounded: every organization shares them and only super admins add them, so the list only grows.
- The table had no `<caption>`, no `scope="col"`, and no `table-scroll` wrapper, so it was neither
  named nor reachable by keyboard when it overflowed.

The non-admin `barcode_items/index` had all of this already. The two pages are now the same page
with a different collection behind them, which is what they always should have been.

## 2026-08-22 · The card check that reported zero because it was wrong twice

`page-audit.rb` reported "hand-rolled card" as debt: a view that pastes the card's classes
inline instead of rendering `shared/essentials/card`, so a change to the component never reaches
it. It reported **0**, and there were **4**.

```ruby
debt << "hand-rolled card" if src.include?(CARD_CLASSES) && !src.include?("shared/essentials/card")
```

Two holes, and each on its own was enough to hide every instance.

**The escape hatch.** `&& !src.include?("shared/essentials/card")` was presumably meant to avoid
flagging the component's own definition — but `shared/essentials/` is already skipped a few lines
above, so all this clause did was excuse any file that rendered one card properly and pasted a
second one inline. Both pages fixed this week were doing exactly that: `admin/barcode_items` and
`admin/ndbn_members` each render a real card and then wrap their table in a hand-rolled one.

**The substring.** `CARD_CLASSES` is `"rounded-2xl border border-slate-200 bg-white shadow-sm"`,
matched with `include?`. A card is a *surface*, not a string, and one utility inserted anywhere in
that run breaks the match. Three of the four write `bg-white p-4 shadow-sm` or `bg-white p-5
shadow-sm`, so even without the escape hatch they were invisible.

It is four tokens inside one `class` attribute now, order-independent —
`rounded-2xl`, `border-slate-200`, `bg-white`, `shadow-sm`. All four must be in the *same*
attribute, so a rounded wrapper around a white child is not a card.

### The check now proves itself before it runs

Two versions of this check were each wrong in a way that printed zero, which is the failure mode
that looks like success — and it printed zero for long enough that the number reached the change
log's verification line. So it follows `undefined-classes.py` and probes the detector against
known answers before reporting anything, aborting with the failing input if any probe disagrees.
The probes include the padding-interleaved case that used to slip through, and a case where the
four tokens are split across two elements and must *not* match. Regressing the detector to the
old substring now stops the script with exit 1 rather than a clean-looking report.

### The four are reported, not converted

DEBT is defined here as reported and not enforced, and the exit code is unchanged. Two of the
four are a straightforward swap — `reports/index` and `admin/ndbn_members/index` are plain card
surfaces. The other two are not obviously the component's job: `admin/dashboard` and
`partners/_show_header` use the card surface for a small `flex items-center gap-3` tile, and the
card renders a title/subtitle/actions header a tile does not want. Converting all four is a
judgement per file and a separate change; what this one fixes is that the audit can see them.

## 2026-08-23 · One of the two "straight swaps" was not one

Of the four hand-rolled cards the fixed check found, two were called straight swaps. Reading
them, only one was.

**`admin/ndbn_members/index` was.** It is the same shape `admin/barcode_items` was in before it
was rebuilt: a real card rendered at the top, four closing tags with nothing open, and a second
card hand-rolled around the table — with everything from the upload form down accidentally
nested inside the first card's block. It is two cards now, the second `padded: false` around a
table that has a caption, `scope="col"` and a scroll region, plus an empty state for the case
where nothing has been uploaded. Headings went to sentence case, which is what moved the request
spec's `th` assertion.

**`reports/index` was not.** Its six cards are `<section>` elements that each carry
`aria-labelledby` pointing at their own `<h2>`, a 28px icon tile, a count, a `text-sm` heading
and a `pb-2.5` divider. `shared/essentials/card` has none of that: no way to label the section,
no icon slot, no meta slot, and a hardcoded `text-base` heading in a `px-5 py-4` header. Swapping
it would:

- **remove six labelled regions.** An unnamed `<section>` is not exposed as a region at all, so
  this is a real loss that axe would not report as a violation.
- **grow each card by roughly 25px** — measured: the header is 39px today against the component's
  ~56px, and the body would go from `p-4` to `p-5`. The grid ends at 659px in a 900px viewport,
  so it would still clear the fold here, but the file's own comment says the design was chosen to
  keep it there.

So it is not debt in the sense the check means, and it is not a swap. It is a page whose card
is a genuinely different component.

### The recommendation for the remaining three

`reports/index`, `admin/dashboard` and `partners/_show_header` all want the card *surface* without
the card *component* — two of them for a `flex items-center gap-3` stat tile, one for a compact
titled section. And there is a fifth the audit cannot even see: `essentials_stats` pastes the same
classes in `app/helpers/essentials_ui_helper.rb:118`, and `page-audit.rb` only globs
`app/views/**/*.html.erb`.

Converting them to the component is the wrong fix in all four cases. The right one is to stop the
surface being a copied string at all: define it once as a component class next to `.data-table` in
the Tailwind entry, and have `_card.html.erb`, `essentials_stats`, the two tiles and the reports
section all use that. Then a change to the card reaches every surface in the app — which is the
only thing the debt was ever about — the check becomes "you pasted the tokens instead of using the
class", and it can be zero honestly rather than by exception.

Not done here: it is a design system change rather than a page fix, and it should be one commit
that moves all five together.

## 2026-08-23 · One definition of the card surface

Six places drew the card surface and only one of them was the card component. A change to the
card's radius, border or shadow reached one of six.

They are not all cards, which is why converting them was the wrong fix. `essentials_stats` builds
its own container, `admin/dashboard` and `partners/_show_header` build `flex items-center gap-3`
stat tiles, `reports/index` builds a compact labelled `<section>`, and
`shared/essentials/_disclosure` wraps a panel. None wants the component's title/subtitle/actions
header. What they share is a *surface*.

So the surface is a component class now — `.card-surface`, in the Tailwind entry beside
`.data-table` — and all six use it, the card component included.

### `@apply`, and it is the only one in the file

The entry writes explicit CSS with `var()` everywhere else. This class uses `@apply`, because the
point of it is to be *exactly* `rounded-2xl border border-slate-200 bg-white shadow-sm` and
nothing else. `shadow-sm` alone compiles to a `--tw-shadow` declaration plus a five-part
`box-shadow` composition; restating that by hand would be the same copy this class exists to
remove, one level down, and it would drift the next time Tailwind changes how shadows compose.
The compiled output is identical to the four utilities.

**Verified as a no-op, not assumed.** Computed `border-radius`, `border-width`, `border-color`,
`background-color` and `box-shadow` were read from every matching element on `/items`,
`/donations`, `/reports`, `/partners/:id` and `/admin/dashboard` before and after — 26 elements —
and all 26 are byte-identical, with the counts unchanged and every one now served by the class
rather than by pasted utilities.

### The audit's card check is no longer per-page

Two of the six were invisible to `page-audit.rb` for structural reasons rather than by accident:
`essentials_stats` is a helper and the script only globs views, and `_disclosure` is in
`shared/essentials/`, which every check skips as "the definition, not a copy". That skip was
right when the component's own markup *was* the definition. It is not any more — the definition
is a CSS class, and the component is just another caller — so the card check moved out of the
per-kind loop into a sweep over views, helpers, JavaScript and components, `shared/essentials/`
included. It reports 0, and a finding always has the same remedy.

### The bare-`card` regex was wrong in the same way, and only now noticed

`BARE_CARD = /class="[^"]*\bcard\b[^"]*"/` carried a comment claiming word boundaries kept it from
matching `card-body`, `content-card` and `data-card`. They do not: `-` is a non-word character, so
`\b` sits happily between `card` and `-`. Nothing legitimate contained the substring, so it never
mattered — until `.card-surface` did, and every card in the app reported as a dead Bootstrap
class. It splits class attributes into tokens now and looks for exactly `card`, with its own probe
table. Two detectors in this file have now been wrong in a way that only showed up when something
new was added, which is the argument for the probes.

### One violation, from the NDBN rebuild rather than the surface

The axe sweep came back with a `link-in-text-block` on `/admin/ndbn_members`: the Google Sheets
link in that page's instructions. It is not from the surface work — it arrived with the rebuild a
few commits earlier, which replaced a bare `<a>` (browser-underlined) with a brand-coloured
`link_to` and no underline. Colour alone does not distinguish a link from the prose around it.

`app/views/help/show.html.erb` already had the right pattern and design.md did not write it down,
so it does now: a link inside a sentence is `font-medium text-brand-700 underline
hover:text-brand-800`; a link that is its own block does not need the underline because there is
no body text to confuse it with. Back to 0 violations across 156 pages.

## 2026-08-23 · The megaphone that marked nothing

Both announcement cards — `dashboard/_announcements` and
`partners/dashboards/_broadcast_announcement` — stamped `essentials_icon_tile("bi-megaphone")`
on every row, inside a card already titled "Announcements". The icon is on the card now, once,
beside the `h2`.

### The rule already existed, in the wrong place

`design.md` said it: *"One icon per card, not one per row. The icon marks the subject. Repeating
it down every row gives the eye a second column of glyphs to skip and marks nothing out."* It sat
under **Cards in a grid**, written while building the reports hub, and read as a fact about
grids. The reasoning is not about grids at all. It is restated under **Icon tiles and avatars**
now, where someone reaching for `essentials_icon_tile` will meet it, and the grid section points
at it rather than owning it.

Industry practice is the same rule from the other end. Material's list item leading element,
Polaris's `ResourceItem` media, Primer's leading visuals and Atlassian's list iconography are all
specified as *identifying the item* — an avatar, a thumbnail, a status glyph that differs. Every
one of them puts a section-level icon in the header slot instead. GitHub's issue list is the
apparent exception and is really the proof: its per-row icon changes with state, open against
closed against draft, which is exactly what makes it worth a column.

### The test is mechanical, which is why it is worth writing down

Four places in this app put an icon tile inside a loop. Three pass a value from the row —
`stat[:icon]`, `metric[:icon]`, `option[:icon]` — and are correct. The two that were wrong passed
a **string literal**. "Is the icon a literal or does it come from the row?" decides it without
any judgement about whether the glyph is pretty, and it is now the wording in design.md.

### The card grew an `icon:` local rather than a captured title

`shared/essentials/card` had no icon slot, and the alternative — passing markup through `title:`
— would have put the icon inside the `<h2>` and into the heading's accessible name. `icon:` and
`icon_tone:` render the tile as a sibling of the heading block, `aria-hidden`, so the accessible
name is still "Announcements".

The header markup only gains a wrapper when there is an icon, because the row is
`justify-between` and a bare icon sibling would be pushed to the far side of the title. The
heading block is captured once and used in both branches. **Checked rather than assumed**: header
height and `h2` position were measured for every card on five pages before and after, and the
only difference anywhere is the announcements `h2` moving 48px right — the 36px tile plus its
`gap-3`. Every other card is identical.

## 2026-08-23 · The icon tile gets one definition too

`essentials_icon_tile` rendered 36px, `rounded-xl`, `text-brand-600`. The reports hub rendered
28px, `rounded-lg`, `text-brand-700` — inline, by hand. Three properties had drifted, not one,
which is roughly what a single hand-rolled copy of a component looks like once nobody is
comparing them side by side.

### Two sizes is the honest answer, not one

The hub could have been forced onto the 36px default, and it would have been wrong. Its card is a
compact cell in a 3×2 grid with a `text-sm` heading; a 36px tile beside 14px text is heavy, and
the file's own comment says the grid was tuned to stay above the fold. So the helper takes
`size:` — `md` (36px, `rounded-xl`) default, `sm` (28px, `rounded-lg`) — named the way the button
sizes already are, which gives the pair of legitimate sizes one definition instead of one
definition and one copy.

**The colour moved and that is the point.** Converting the hub takes its icon from
`text-brand-700` to the helper's `text-brand-600`, 7.07:1 down to 5.62:1 against `bg-brand-50`.
Both are far past the 3:1 that non-text contrast asks for, and the icon is `aria-hidden`
decoration in a card whose heading carries the meaning. The alternative — moving the *helper* to
700 — would have changed the tile everywhere to preserve the one place that was out of step.
Geometry is unchanged: 28×28, 8px radius, same header, card and grid heights.

### The discriminator for the audit is `rounded-full`

A tile check that matched every tone-coloured fixed-size rounded box would also flag the topbar
avatars and the five numbered step badges on the getting-started card. It does not, because those
are circles and tiles are not. That is not a convenience — design.md already keeps avatars and
tiles disjoint on the grounds that it is what makes either readable at a glance, and the audit now
draws its line in the same place. Both sweeps live together now, asking one question of everything
that emits markup: did someone rebuild a thing the design system already defines?

### What was checked and left alone

Eight tone-coloured rounded boxes exist in the app. Two are topbar avatars, five are the
getting-started step badges, one was the reports hub. Only the last was a tile. The step badges
repeat the same 100-character class string five times in one file, which is its own small drift
risk — but they are a numbered badge rather than an icon tile, and five copies in one file is a
different problem from one copy hiding in another component. Written down rather than fixed.

## 2026-08-23 · Three dropdowns, three gaps, three reasons

Every `<select>` in the app drew its own arrow in its own place. Measured across 151 screens:

| Dropdown | Count | Glyph | Painted gap to right border | Left padding |
| --- | --- | --- | --- | --- |
| simple_form select | 75 | the browser's native arrow | 4.5px | 12px |
| `.filter-select` | 41 | the app's SVG chevron | **18.5px** | 12px |
| select2 | ~44 | a CSS triangle in `#888` | 7px | **8px** |

Three causes, none of them the same mistake twice.

**The chevron was positioned by its box, not by its glyph.** The SVG drew `M6 8l4 4 4-4` inside
`viewBox="0 0 20 20"`, so the path was inset 6 units from either side of its own box, and CSS
positions the box. `background-position: right 0.75rem` was chosen to mirror `pl-3`, and left the
painted chevron 18.5px from the border against 12px of padding on the other side. The number
looked right in the source and was wrong on screen, which is exactly the class of thing that
survives review. The viewBox is wrapped tightly around the path now — `0 0 10 6` — so positioning
the box positions the glyph, and `right 0.75rem` means 12px.

**simple_form had no entry for `select`.** Its `:essentials` wrapper applies one `input_classes`
string to every input type, and `wrapper_mappings` named boolean, check_boxes, radio_buttons and
file. A select is not a text field: the browser draws an arrow inside the box and `px-3` cannot
move it. Seventy-five dropdowns — the majority of the app's — fell through to the text-input
wrapper and kept the browser's arrow. There is an `:essentials_select` wrapper now.

**select2 was vendored, not restyled.** The migration kept select2 and brought its stylesheet
across as-is, so it arrived with a 2014 CSS triangle 7px from the border and 8px of text padding.
Its arrow is the app's chevron now, at 12px, with the triangle hidden.

### The names were lying, and that is part of how it happened

The CSS class was `filter-select` and the Ruby constant `FILTER_SELECT_CLASSES`. Both say
"filter", and the chevron belongs to every select — the ones outside a filter bar were the
majority. A name that scopes itself to one context is an invitation not to use it in the others,
and that is roughly what happened: seven selects were given `FILTER_CONTROL_CLASSES` instead, the
*text input* constant, and kept the native arrow because of it. They are `.select-chevron` and
`SELECT_CLASSES` now.

Those seven also revealed a smaller thing: `FILTER_CONTROL_BASE` already begins with `mt-1.5`, and
nine call sites wrote `class: "mt-1.5 #{FILTER_CONTROL_CLASSES}"`, emitting the class twice.
Harmless, and removed.

### The chevron is one CSS variable

`--chevron-down`, defined at `:root` rather than inside `@theme`, because three different
mechanisms need it: a component class for real selects, and an unlayered override for select2,
which cannot take a padding class because the element the user sees is a `<span>` select2 builds.
A data-URI SVG copied into three places would have drifted the way the tile and the surface did.

### Verified by pixels, not by CSS

The gaps above were measured by screenshotting each control at 4× and scanning for the stroke
colour, because the thing that was wrong — a glyph inset inside its own background box — is
invisible in the CSS and invisible to a computed-style check. All three now paint their chevron
with its box edge 12px from the border, matching `pl-3` on the other side, and the app-wide sweep
reports one signature for all 116 visible selects where it used to report three.

## 2026-08-23 · The required marker is a red asterisk, and the legend is gone

Two changes, one of which reverses a call made on this branch three days ago.

### The asterisk was grey, with three dots under it

`<abbr title="required">*</abbr>` inherits the label's colour — slate-700 — and every browser's
default stylesheet gives `abbr[title]` `text-decoration: underline dotted`. Under a single
asterisk that renders as a star with three dots beneath it. Nothing in the design system turned
it off, so the marker was neither red nor cleanly an asterisk, on every form in the app.

It is `rose-600` with `text-decoration: none` now. **The class comes from the locale, not from an
attribute selector.** `simple_form.en.yml` sets `required.html` to
`<abbr class="required-marker" title="required">*</abbr>`, and the Spanish file sets the same
class with `title="necesario"`. Styling `abbr[title="required"]` would have worked in English and
silently not in Spanish, which is the sort of thing that survives for years.

Evidence that the browser default had been met before and only patched locally:
`requests/_request_row.html.erb` puts `class="no-underline"` on an unrelated `<abbr>`. Somebody
hit it, fixed the one they could see, and moved on.

### The legend is removed, and that reverses `fc4e62d32`

`essentials_form_for` rendered "Fields marked * are required." above every form, CSS-hidden
unless the form actually had a required field. It was added deliberately, for WCAG 3.3.2, with
the reasoning: *"`abbr@title` covers a screen reader; a sighted user got a bare glyph."*

The counter-argument, and the one taken: a **red** asterisk is not a bare glyph. Grey-with-dots
was, which is most of why the legend felt necessary. The line cost roughly 32px at the top of
every form's card, and the two profile step pages carried a second one — an info callout reading
"Instructions: Please fill out the following form sections carefully. Ensure that all required
fields are completed." — which pushed the first card from 274px down to 350px.

**Nothing programmatic changed.** The `abbr@title` is still there and still read by screen
readers; `aria-required="true"` is still put on every required input by `EssentialsInputAria`.
What was removed is a visible restatement for sighted users, who now get colour and shape
instead of a sentence. WCAG 3.3.2 asks for labels or instructions, not for a legend; Material and
Polaris both mark required fields without one, and GOV.UK avoids asterisks entirely rather than
explaining them. This is a defensible position rather than an obviously correct one, which is why
it is written down as a reversal rather than as a fix.

### Two consequences that had to move with it

**`form-validation-audit.js` asserted the legend exists.** Left alone it would have reported
"asterisk with nothing saying what it means" on 26 forms — verified by running the old audit
against the new app. The check is now `markerStyled`: the marker must not inherit the label
colour and must not carry a text decoration. That is a test for the defect that actually existed,
where the old one tested for the absence of a mitigation.

**Four labels wrote their own asterisk.** `product_drive_participants/_form` marks four
conditionally-required fields — business name or contact name, phone or email — with a literal
`*` in the label text plus a parenthetical explaining the condition. Harmless while the real
marker was also a grey glyph; not harmless once it is red, because the page then shows two
asterisks in two colours meaning two different things. The asterisks went and the parentheticals
stayed, which is the half that ever carried the meaning.

### One finding this did not cause

The form audit reports `/partners/family_requests/new` with no inline errors and no
`aria-invalid`, against a change log entry claiming the audit had no findings. That form is
`form_with` with no `f.input` and never touches simple_form, and running the *previous* audit
against the current app reports the same thing. It predates this work and is recorded in
[todo.md](todo.md).

## 2026-08-23 · Two error conventions on one page, and the glyph the rule already asked for

### Eighteen forms announced one failure twice

Submitting `/donations/new` empty produced two `role="alert"` regions: a flash at the very top,
above the back link, and the error summary above the first card. Measured across every `new` and
`edit` form in the app, **18 did this** and 13 showed the summary alone.

They also disagreed. `/adjustments` flashed `storage_location: must exist` — raw attribute names
— while the summary above it said "Storage location must exist". Eight forms flashed "Something
didn't work quite right -- try again?", which is not information. Six flattened the record's own
errors into a sentence, duplicating the summary in a format that cannot link to a field.

`design.md` had already decided this, twice over. The summary is "the GOV.UK error-summary
pattern and the reason a summary is worth having", and the entry on rebuilding a failed record
describes the symptom of the old bug as *"the only sign of trouble is a sentence at the top"*.
The flash sentence **was** the old pattern; the summary replaced it, and on 18 forms nobody
removed the thing it replaced.

### The fix is a guard, not a deletion

Deleting the flash outright would have been wrong. `essentials_error_summary` renders nothing for
a record with no errors, and a failure can leave a record clean: a service raises, or a business
rule fails without touching validation — `can_deactivate?` on an item, an inventory shortfall on
a distribution, `validate_role_resource_params` raising before `admin/users` ever validates. Those
would have re-rendered with no sign of trouble at all.

`ApplicationController#flash_error_unless_summarised(record, message)` sets the flash only when
there is nothing to summarise. Operational failure keeps its flash; validation failure gets the
summary; never both. 33 call sites across 21 controllers.

Three of those flashes built their message *out of* `record.errors`, which the guard makes
unreachable — they would have rendered an empty bar on the one path that can still reach them.
Those took a plain operational sentence instead.

`/admin/users/new` is the shape worth keeping in mind: it still flashes, and should. Its create
action raises `"Please select an associated resource"` from a parameter check before any
validation runs, so the record is clean and the summary has nothing to show.

### The audit selector was wrong in a way that flattered the result

The sweep counted a page as having a summary if `main [role=alert].bg-rose-50` matched — and the
**danger flash carries `bg-rose-50` and lives inside `<main>`**, so a page with only a flash
counted as having both. It reported 1 remaining form that direct inspection showed was correct.
The selector now excludes anything inside `turbo-frame#flash`. Reported as it happened because
the same mistake would flatter a future run: 18 → 0 is the number after fixing the check, not
before.

### The inline error had the colour and not the glyph

`design.md`: *"Never colour alone. Every coloured signal carries a word, and usually an icon
too."* The message was the word; there was no icon. And a hint and an error render in the same
place, at the same size, under the same field — `mt-1 block text-xs`, differing only in hue and
weight. Hue was doing the work on its own, which is what WCAG 1.4.1 is about.

`.field-error` adds `bi-exclamation-triangle` through `::before`, because simple_form's error
component renders text into a `<p>` and takes a class rather than a block. Generated content is
not in the accessibility tree, which is right here — the message beside it already says what is
wrong. The summary's heading gained the same glyph; its `flex items-center gap-2` had been
sitting there with a single child since the summary was written, space reserved for an icon
nobody added.

**The text stays `rose-700`, and this is a deliberate departure from what was asked for.** The
request was for grey. `design.md` maps a failure to the `danger` tone, says text tones use the
`-700` step, and says error text specifically is `rose-700` — and the instruction was to check
the design system and match it. Grey is also the hint colour: `slate-500` at `text-xs`, in the
same slot under the same field, so a grey error and the hint it replaces would be near
indistinguishable. The icon was the missing half, and it is the half that removes the reliance on
colour.

## 2026-08-23 · The error message goes slate, and three checks that were keyed to its colour

A follow-up to the entry above, reversing the half of it that kept the inline message red.

### The glyph signals; the sentence reads

The argument for `rose-700` was design.md's colour table: a failure is `danger`, text tones use
the `-700` step. The argument against is that **there is an icon now**, and it is the icon doing
the signalling. Once that is true the sentence is just words, and words read better in body
text: `slate-700` is **10.35:1** on white against rose-700's **6.29:1**. A form with six problems
also stops being six lines of red.

The objection raised the first time — that a grey error is indistinguishable from the grey hint
in the same slot — is answered by the same icon. The hint is `slate-500` with no glyph; the error
is `slate-700` with one. Two differences, neither of them hue alone.

The summary followed: `slate-900` heading, `slate-700` items, on the `rose-50` surface inside its
`rose-200` border. The frame and the mark carry the danger; colouring the sentences as well says
it a third time, and slate-900 on rose-50 is 16.25:1 where rose-900 was 8.71:1.

### A tile on white, a plain glyph on a tint

The inline glyph got a `rose-50` chip, 16px, because it sits on the card's white. The summary's
glyph was built the same way and **could not be seen** — a `rose-50` tile on a `rose-50` surface.
design.md already says this about the flash bar: *"a message bar gets a plain glyph, never an
icon tile: a soft `-50` tile on a `-50` surface is invisible."* A summary is the same kind of
object. Measured before believing it: both came back `oklch(0.969 0.015 12.422)`.

### The bullets had a red underline under grey words

Each summary item is a link to its field, and they carried `decoration-rose-300`. That was
coherent while the item text was `rose-800`; the moment the text became slate it was a red rule
under grey words, matching nothing else in the app. They are ordinary links now — `brand-700`,
underlined, 7.19:1 on rose-50 — which is also what they should have looked like all along, since
the entire point of the GOV.UK summary is that the items are clickable.

### Three audit checks were testing for a colour

`form-validation-audit.js` looked for `main p.text-rose-700` to decide whether a field had an
inline error, and for a `rose` class in the ancestry to decide whether `aria-describedby` pointed
at one. Both went wrong the instant the message stopped being rose — reporting first 2 and then
**27 forms** with defects that did not exist. They key on `.field-error` now, which is the thing
being asked about rather than the colour it happens to be painted.

This is the third audit in three days found to be checking a proxy rather than the property:
`page-audit`'s four page kinds, its substring match for a card, and now these. The pattern is
worth naming — a check written against today's markup passes for as long as nothing changes, and
a design system is a thing that changes.

### `admin/partners/edit` builds its fields properly now

The three `f.input :name do ... f.input_field ... end` blocks are plain `f.input`. The block form
replaces the wrapper's input, so those fields had no `aria-required`, no `aria-invalid`, no
`aria-describedby` and no inline message, and carried a hand-copied version of the wrapper's
class string that could never follow it. Confirmed in a browser: the name field now reports
`aria-required`, and an empty save gives `aria-invalid`, a linked description and a message
beside the field where previously there was nothing at all.

---

## 2026-08-24 · The line item row becomes a table, and the scan field leaves the row

**Area.** `line_items/_line_item_table`, `line_items/_line_item_fields`, and the seven forms that
render them — donation, purchase, distribution, transfer, adjustment, audit, kit.

**Decision.** Option C of three offered in
[`docs/mockups/line-item-row-options.html`](mockups/line-item-row-options.html): one scan bar per
card, column headings once in a heading row, an icon-only remove at the end of the row, and a
running total in the footer. All seven forms render one shared partial instead of assembling the
card body by hand.

**Why the row was a mess, measured before anything was changed.** Five controls on what is
supposed to be one line, landing on **three different bottom edges** — 910, 924 and 926px at a
1440px viewport. Against the app's 38px/8px/14px control: the barcode input matched, the scanner
button was **42px** and 34×42 rather than square, the remove link 28px, and the item dropdown
**28px tall, 4px radius, 16px text, 575px wide** — wrong on every axis. The row is 58px now and
every control shares one edge.

**Why a table and not three equal columns.** The literal reading of "match the convention for
number of columns per card" would have been `sm:grid-cols-2 lg:grid-cols-3`, which is what the two
cards above it use. That was rejected: those cards hold *one form filled in once*, and this one
holds *a repeating collection*. Three equal columns would make Item and Quantity the same width,
and quantity is always the narrow one — no inventory app does otherwise. What the card inherits is
**column discipline**, not a column count.

**Why the scan field left the row.** It was the deepest fault and the least visible one. A barcode
field belongs to the document being built, not to a line of it. Square, Zoho Inventory, Odoo and
Amazon Seller all put one scan field at the top of a receiving screen and append rows as you scan;
this form rendered "Scan a barcode", an "or" and a full item picker **per row**, so a ten-line
donation had ten scan fields. The behaviour that replaced it is the one the old code was reaching
for through a proxy: it used to detect a repeat scan by comparing the value left sitting in every
row's own barcode input, which is why the three-scan package prompt worked at all. The count is
`data-scan-count` on the row now — first scan sets the barcode's quantity, second adds it again,
third and later ask how many packages in total, exactly as before.

**Alternatives rejected.**

- **Option A, align the existing row.** Correct as far as it went, and it touched no JavaScript,
  but it keeps three labels, a scan field and an "or" on every line. Offered as the small-appetite
  choice.
- **Option B, headings only.** This *is* C without the scan bar, so it was not so much rejected as
  passed through: building B first would not have been wasted work if C had proved too much.
- **A camera glyph for the scanner.** `bi-upc-scan` is the barcode mark Shopify, Square and Zoho
  all use; a camera says "photo".
- **The scan button inside the field as a trailing adornment.** Tidiest, but a ~36px hit area
  inside a text input is easy to mis-tap, and this is a warehouse form used on tablets.
- **A remove control revealed on hover.** There is no hover on touch.
- **Keeping `.li-name` / `.li-quantity`.** They were layout wrappers, used by exactly one spec.
  Reintroducing them would have meant markup existing only for a test; the spec uses the
  documented `.line_item_name` and `.quantity` hooks instead.
- **`Capybara.enable_aria_label = true`.** It would have let `have_field("Quantity")` keep working
  now that the control's name comes from `aria-label` — and it would have made that selector
  *ambiguous*, because the barcode dialog has a Quantity field too. The one spec affected matches
  by id, which is what its neighbours already did.

**A third thing measurement caught.** The first build put four columns on the row at every width,
and at 320px that leaves the item picker **72px** — narrower than the quantity box beside it, on
the screen where the item name matters most. 320 is not an arbitrary width to check: WCAG 1.4.10
Reflow is defined there, and `responsive-audit.js` visits it. The row stacks below `sm` now, which
takes the picker to 196px; the heading row goes with the columns, so each cell grows its own
`sm:hidden` label, and the `aria-label` on the control is what carries the name at the width where
that label is `display: none`. Narrowing the quantity column instead was tried on paper first and
rejected — 4rem gets the picker only to 122px, and the heading "QUANTITY" stops fitting.

**Two defects created and fixed on the way**, both recorded in `design.md` because neither is
specific to this screen: a `MutationObserver` whose callback wrote inside the subtree it observed
(an unbroken loop that hung the tab on the first scan), and the assumption that jQuery's `.val()`
and `.trigger()` are visible to a native `addEventListener` (they are not, which left the running
total one scan behind).


---

## 2026-08-24 · The scan field's width, and the camera that drew itself into the button

**Area.** `line_items/_line_item_table`, both `barcode_items/_barcode_modal` partials,
`utils/barcode_scan.js`.

**Decision.** The scan field is **15rem**, sized to its content rather than to a column. The
camera renders into a `[data-barcode-viewport]` inside a `[data-barcode-scan]` region, and no
scanner is wired by id.

**Why not one column wide.** The question was a fair one — the scan bar sits directly above a
table, and matching a column would give the two a visible relationship. It was rejected because
the Item column is `1fr`: 904px at 1440 and 377px at 641. Tying the field to it would make the
width of a barcode box depend on the size of the window, and a barcode is 12 to 14 digits on
every screen there is. The alignment that does mean something is already there — the scan bar and
the Item column share the card's `px-5`, so they start on the same vertical.

**Where 15rem comes from.** Measured, not chosen: a 14-digit GTIN — the longest barcode in common
use, longer than EAN-13 or UPC-A — renders at **138px** in Figtree at 14px including the field's
padding. The group is 240px, of which the field is 202px and the button 38px, so about 21
characters fit. The previous value was `max-w-md`, which is **410px of field for 138px of
content**, and it came from the mockup, where I picked it by eye and never measured it. Industry
says the same thing in three places: GOV.UK ships fixed-width input classes precisely so that a
field's width signals expected length, USWDS has the same set, and Baymard reports oversized
fields causing hesitation in checkout testing. Promoted into `design.md` as a general rule, with
the explicit carve-out that free text — a name, an address, a comment — takes its column.

**The camera bug, which was three bugs.** Quagga is handed a `target` element and fills it with a
`<video>` and a `<canvas>`. It was handed **the button**: `target: "#barcode-scanner-btn"`.
Measured before and after a click, the glyph moved from x=730 to **x=391** — 339px outside the
38px control that owns it — because the button is a centring flex box and its contents had
suddenly become a camera feed. Second, on a successful read the code called `.empty()` on that
same button, deleting the glyph permanently. Both looked like they "reset on refresh" because
neither was ever persisted. Third, and the reason a fix by id would not have held:
`id="barcode-scanner-btn"` is in **three partials**, and a donation form renders two of them, so
pressing the *dialog's* camera button drew the picture inside the *scan bar's* button. axe does
not report that — `duplicate-id` was deprecated in axe-core 4.9.

A fourth, found while reading rather than from the report: `last_target.prev().val(code)` took
`$(e.target)`, which is the `<i>` inside the button as often as the button itself, and an icon's
previous sibling is nothing — so a camera read frequently had nowhere to write its result. It
uses `e.currentTarget` and the region's own input now.

**Alternatives rejected.**

- **Keeping the button as the target and restoring it afterwards.** The damage is visible for the
  whole time the camera is open, which is the part the user actually saw.
- **Unique ids per scanner.** It would work, and it would leave the next person to invent a
  scheme for generating them in a partial rendered once per card and twice per page. A region
  with a data attribute needs no scheme.
- **Auto-running the lookup after a camera read on every scanner.** Done for the line item field,
  which is the same keypress a handheld reader sends and what `create.js.erb` already simulates.
  Deliberately *not* done in the barcode dialog: the field there holds the barcode being created,
  and looking it up is the thing that just failed.


---

## 2026-08-24 · The scan field takes a grid column, and the width rule gets its missing half

**Area.** `line_items/_line_item_table`, `design.md` &sect; Forms.

**Decision.** Option A of
[`docs/mockups/scan-field-width-options.html`](mockups/scan-field-width-options.html): the scan
bar sits on the same `gap-x-5 sm:grid-cols-2 lg:grid-cols-3` grid as the two cards above it and
takes column one. Its left and right edges land on the storage location select's at every width.

**This reverses the entry above it, one day old.** That entry sized the field to its content —
`15rem`, from a 14-digit GTIN measuring 138px — citing GOV.UK and USWDS, and it stated the rule in
`design.md` without the condition that makes it true. The condition is **neighbours**. GOV.UK's
narrow inputs sit in a column of stacked fields, where the field above and the field below share
the left edge; that repetition is what makes a short width read as deliberate. The scan field is
alone in a tinted band with nothing to establish a rhythm, so the same short width reads as
unfinished. Both rules are real and they are about different situations; I applied the one whose
precondition did not hold.

**The measurement that settles it.** A fixed width cannot align to a fluid grid at more than one
viewport. `15rem` was 106px short of the column at 1440, 53px short at 1280 — and at **1024 it was
33px *wider* than the column**, crossing a boundary every other control on the page respects. That
is not a ragged right edge, which is a defensible aesthetic; it is a control overhanging its cell.
On the grid it is 346/293/207/329/265/301/246px at the seven audited widths and aligned at all of
them.

**The content measurement was not wasted.** It became the check in the other direction: the column
must never be *too small* for the content. At 1024, where the three-column grid is narrowest, the
field is 169px against 138px of barcode. If that had come out negative, option A would have been
the wrong answer.

**Alternatives rejected.**

- **Half the card**, the other option offered. At `lg` the cards use thirds, so a half falls
  between column two and column three — a line the page does not draw. At `md`, where the grid is
  two columns and a half ought to coincide, it overshoots by **10px**, which is exactly half the
  `gap-x-5` gutter: a column is `(W − 20) / 2` and a half is `W / 2`. Near-miss at one breakpoint,
  arbitrary at the rest.
- **Keeping `15rem`.** Worth revisiting only if the scan bar ever gains a second control beside
  it — a storage location, say — because then there would be a column of stacked fields for a
  short width to sit inside, and GOV.UK's rule would start applying properly.
- **A wider camera viewport spanning the band.** The viewport stays inside column one with the
  field it belongs to; a preview that broke the column would reintroduce exactly the unmoored edge
  this change removes.


---

## 2026-08-24 · A copy audit, and what it had to learn before it could be believed

**Area.** `bin/design/copy-audit.rb` (new), `design.md` &sect; Copy (new), and 56 strings across
views, mailers and locales.

**Decision.** Copy is part of the design system and gets an audit like everything else. Six
checks: link text (WCAG 2.4.4), sensory instructions (WCAG 1.3.3), gendered wording, ableist
wording, "please", and all-capital shouting. `design.md` gains a **Copy** section, which it did
not have at all — which is why none of this had a rule to drift from.

**The findings, after the audit was made honest.** Gendered: **0**. Ableist: **0** — the app was
already clean on both, and the value of the checks is that it stays that way. Real: 5 vague link
labels, 2 sensory instructions, 1 piece of shouting, 48 "please".

**Three things the audit got wrong first, each caught by its own probe table rather than by
review.** This matters more than the findings, because a copy audit that reports a confident zero
is worse than none:

- **It read source, not copy.** The first `he/she` pattern matched `render
  "organizations/header"` — "organization[s/he]ader" contains it. Every check now runs against
  strings pulled from where copy actually lives: locale values, template text nodes, and the
  arguments to the helpers that put words on screen.
- **It did not know a link from a heading.** WCAG 2.4.4 is about link labels and nothing else.
  Applied to all copy, the vague-text check reported **all sixteen cards titled "Details"** —
  headings, and entirely correct. Corpus entries carry a kind now, and the count fell 22 → 5.
- **Its `/x` regexes had their spaces stripped.** Ruby's extended mode removes literal
  whitespace, so `VAGUE_LINK` was looking for `clickhere` and `SENSORY` for `tothe left`. Every
  multi-word branch uses `\s+` and every branch has a probe.

A fourth, less subtle: the acronym allowlist was too short, so FPL, JPEG, PDX and GMT reported as
shouting. 21 → 1. **Adding a real acronym to the list is the right fix; rewording around it is
not**, and that is written down.

**On short link labels.** Two "More info" links keep their visible words and gain an `aria-label`
that *extends* them — "More info about the announcement of 22 August". Replacing the visible text
outright would have satisfied 2.4.4 and broken **WCAG 2.5.3 Label in Name**, which requires the
visible label to be part of the accessible name, and voice control with it. The audit understands
that exemption, and the exemption is itself probed: strip the `aria-label` and the finding comes
back, which was verified rather than assumed.

**What was found on the way.** `account_requests/new` was still rendering simple_form's
`f.error_notification` rather than the app's `essentials_error_summary` — the single-convention
sweep in `6d2cdb6e2` looked for a *flash* beside a summary and so never saw it. It surfaced here
only because the notification's default message, "Please review the problems below:", is copy
with both a "please" and a position in it.

**Alternatives rejected.**

- **Leaving "please" in mailers and the privacy policy.** Tempting, because it reads as warmth
  rather than filler. Rejected for consistency: a rule with a "except when it feels nice" clause
  is not a rule, and none of the 48 read worse without it.
- **Leaving the Devise locale strings alone** as upstream defaults. They are in our locale files
  and shown to our users, so they are our copy. The cost is drift if Devise changes them, which
  is a merge conflict rather than a defect.
- **Rewording around flagged acronyms.** FPL, NDBN and GTIN are the words the domain uses.
- **Checking prose in `docs/` and `bin/`.** The audit's scope is what a *user* reads. Three
  "sanity-check"s in contributor docs were fixed by hand for consistency with the rule, and the
  audit deliberately does not police documentation.


---

## 2026-08-24 · Icon-only buttons: kept, made real buttons, and no tooltip

**Area.** `UiHelper#add_element_button`, `UiHelper#remove_element_button`, `design.md` &sect; Icons.

**Decision.** Icon-only stays for the line item row action. Both helpers render a real
`<button type="button">` instead of an anchor carrying `role="button"`. **No tooltip.**

**Are they recommended?** For a *repeating row action*, yes, and the industry is unanimous:
QuickBooks, Xero, Shopify and Stripe all end an editable line item with a bare glyph. The row
supplies the context a label would, and eight rows of "Remove" text is eight repetitions of a word
that says nothing new. For a **one-off** action, no — a single destructive control in a page
header gets its words. That distinction is now in `design.md`, because "use icon buttons" without
it is how a page ends up with an unlabelled glyph nobody can identify.

**Should they have a visible label?** No, and the row is the reason. **A hover label?** Also no,
and this was the closer call. Material, Fluent and Carbon all pair icon buttons with tooltips, and
the argument for one here is real: a sighted mouse user meeting a trash glyph has nothing but the
glyph. Rejected on three grounds. A `title` attribute is the cheap version and is the worst of
both — **not shown on keyboard focus**, unavailable on touch, and announced inconsistently on top
of the `aria-label`, which produces a double announcement. A real tooltip is a component this app
does not have, and WCAG 1.4.13 requires it to be dismissible, hoverable and persistent, which is a
Stimulus controller and a preview of its own. And the glyph is a **trash can at the end of a row
that has a delete affordance in every comparable product** — the recognition cost is close to
zero, unlike an ambiguous glyph where a tooltip would be doing real work. Worth revisiting if a
second icon-only action ever joins it in the row, because then the two need telling apart.

**Are they screen reader compliant? They were not, and axe said they were.** The accessible name
was fine — `aria-label="Remove this item"`, icon `aria-hidden`, and the accessibility tree read
`{role: button, name: "Remove this item"}`. The **behaviour** was wrong. A native `<a>` fires on
Enter and ignores Space; the ARIA button pattern requires both, so a control that announces
itself as a button and then ignores Space fails **WCAG 4.1.2 Name, Role, Value**. Measured on
`/donations/new`: Enter removed a line item, **Space did nothing**. axe cannot catch it, because
axe reads markup and this is behaviour, and the markup was impeccable.

The fix is not a keydown handler; it is to stop pretending. Both helpers render `<button
type="button">` now — Enter and Space for free, no `href="javascript:void(0)"`, and they leave a
screen reader's *list of links*, where fourteen inert "Add another item" entries had been sitting.
`type: "button"` is load-bearing: these are inside forms, where a button defaults to submit.

**Alternatives rejected.**

- **Adding a `keydown` handler for Space to the anchor.** It reimplements a native control badly,
  and leaves the anchors in the links list.
- **`title` as a cheap tooltip.** See above: invisible to keyboard focus, absent on touch, and
  doubles the announcement.
- **A visible "Remove" label.** ~45px per row on a control the row already explains, and it is
  what the mockup measured and the user chose against.


---

## 2026-08-24 · The labelled remove button, a destructive ghost that is not red, and the empty state

**Area.** `UiHelper#remove_element_button`, `EssentialsUiHelper::BUTTON_VARIANTS`,
`line_items/_line_item_table`, `line_item_total_controller`, `design.md`.

**Decision.** Option C of
[`remove-control-and-empty-state.html`](mockups/remove-control-and-empty-state.html) for the
control and option B for the empty state. `ghost_danger` becomes **`slate-600` at rest**, rose on
hover and focus.

**The control: consistency, and it reverses my own earlier recommendation.** I argued for
icon-only two rounds ago on density, citing QuickBooks, Xero and Stripe. That is a good argument
about line item editors in general and the wrong one about *this* app, because
`remove_element_button` has five call sites and four already rendered the words — including
`partners/requests/_item_request`, which is the same shape as the bank row and sat two screens
away rendering "Remove" at 83×28. The 45px the label costs is smaller than the cost of one control
having two appearances. It is one rendering now; the `icon_only:` branch and the
`ICON_BUTTON_CLASSES` constant that existed only to serve it are both gone.

**The colour, which the preview got wrong.** I drew the ghost button rose-700 at rest, and
`ghost_danger` really was rose at rest — but `design.md` had *already* carried the opposite rule
for this exact control: *"`slate-500` until hover… so an eight-row form does not carry eight red
marks down its edge."* I had written that sentence for the icon and then contradicted it in the
variant and again in the preview. It is `slate-600` at rest now, matching plain `ghost`, with rose
reserved for hover and focus. The word and the trash glyph say the action is destructive; colour
saying it a third time, on every row, makes the row you are pointing at no louder than the rest.
Same reasoning as the grey error message. Verified: rest `oklch(0.446 0.043 257.281)`, hover
`oklch(0.514 0.222 16.935)` on `rose-50`, focus outline `rose-600`.

One consequence worth having: `partners/profiles/step/_attached_documents_form` was passing a
whole replacement class string to force rose, a workaround for `ghost_danger` losing to `ghost` in
the cascade. The variant is correct, so the workaround is deleted, and that call site stops being
the only Remove in the app still red at rest.

**The empty state: `:cold_start`, and no action in it.** Removing the last row left the column
headings over a 20px void and a footer with a blank total, which is exactly what *"never render
bare empty table chrome"* is about. The state is rendered hidden and switched on by
`line_item_total_controller`, because rows come and go without a round trip; the headings are
hidden with it, since there are no columns left to head. **It deliberately offers no action**:
`:cold_start` normally does, but the footer's **Add another item** is 60px below, and two buttons
doing one job is what the tab-actions pass removed.

**Alternatives rejected.**

- **A tooltip on the icon.** A whole component with WCAG 1.4.13 obligations — dismissible,
  hoverable, persistent — bought to solve what a word solves for free. `title` is not a shortcut:
  the preview measured the tooltip at opacity 0 at rest and 1 **on focus**, which is precisely what
  `title` cannot do, on top of doubling the announcement over the `aria-label`.
- **"Never allow empty"**, keeping one blank row with the remove disabled on the last one. What
  Xero and Stripe actually do, and genuinely tempting, since an empty state nobody can reach is
  dead code. It needs a disabled control with `aria-disabled` and a reason, or the user finds a
  button that does nothing; the empty state is less machinery.
- **Fixing the sixteen tables with no empty state at all**, found while sweeping. The ask was to
  check that the existing ones match each other, and all 64 do — 0 without a deliberate `kind:`.
  Nine of the sixteen are reachable-empty and need a title, a body and an action decision each;
  they are triaged in `docs/todo.md` rather than folded in here.


---

## 2026-08-24 · Free text in a table column

**Area.** `.data-table .notes`, 16 columns across 15 views, `design.md`.

**Decision.** Option B of [`long-text-in-tables.html`](mockups/long-text-in-tables.html): a
`.notes` column class, one line, clipped at **16rem**, beside the existing `.numeric`, `.quantity`
and `.date`. The app already types its columns; free text of unbounded length is the fourth kind.

**Measured.** `/purchases` rows were **145–245px** against a normal 45px, fourteen of them making a
**2,711px** table. With `.notes` the table is **1,111px**. Carbon, Material, Salesforce, Atlassian,
Stripe, Linear and GitHub all clip to one line; Polaris and Notion allow two. Two lines was the
near miss — it gives the column two row heights, which is the original problem in miniature.

**Two exceptions, and the test between them.** `partners/requests/_history` and the partner
dashboard already used a `<details>` disclosure, with a comment saying it had replaced a Bootstrap
tooltip because tooltips are hover-only. **I did not show that option in the preview and should
have** — it was in the app already. Checking why it was there gave the rule: those rows **lead
nowhere**, so a clipped comment would be unreadable rather than one click away. *Is the full text
one click away? clip. Is it not? disclose.* A third table, `admin/account_requests`, has no detail
page either and was left alone for the same reason. And `item_categories` renders its items as a
`<ul>` of anchors, where clipping would leave focusable links invisible; that needs a count or a
"+N more" and is recorded rather than invented.

**16rem is load-bearing, and the first value was 22rem.** `nowrap` makes a column *demand* its
max-width rather than shrink by wrapping, so this one number sets how wide every table carrying a
`.notes` column becomes. At 22rem the purchases table grew from 1,061 to 1,298px, crossed its
scroll region, and **started the whole document swiping sideways at 1440**, which it had not done
before. 16rem is the widest that leaves it where it was.

**What that regression exposed.** Chasing it turned up a pre-existing bug: `html { overflow-x:
clip }` is set for exactly this and does not work — at 375px the `h1` on `/purchases` could already
be swiped from `left: 16` to `left: -670` before any of this work. Worse, **`responsive-audit.js`
does not catch it**, because it compares `scrollWidth` with `clientWidth` and that is the very
number the `clip` rule exists to neutralise. The audit reads a proxy and reports clean while the
page pans; the honest check is to scroll the window and see whether the `h1` moves. Recorded in
`docs/todo.md` with the measurements. `body { overflow-x: clip }` was tried, did not help, and was
reverted rather than left in as dead CSS.

**Alternatives rejected.**

- **Two-line clamp.** Bounded, but two row heights.
- **Dropping the columns.** Right for any that turn out to be almost always empty — worth checking
  per table rather than assuming, and not checked here.
- **A `title` tooltip for the full text.** The third time this has come up and the third refusal:
  not shown on keyboard focus, absent on touch, announced on top of the text it duplicates.


---

## 2026-08-24 · A tooltip for clipped table cells, after refusing three

**Area.** `clipped_text_controller`, `.tip-bubble`, `design.md`.

**Decision.** Option C of [`clipped-cell-tooltip.html`](mockups/clipped-cell-tooltip.html): a real
tooltip on hover **and** focus, only on cells whose text is actually clipped.

**Why this reverses three earlier refusals without contradicting them.** I argued against a
tooltip on the scan button, the remove button and then the clipped cell. Those were one case:
**a control that needed a name**, where a word solved it for free and a tooltip was a component
bought to avoid typing one. Truncated text is the opposite — the words are already written,
already in the DOM, and hidden *on purpose* to keep the table scannable. Revealing them on demand
is what a tooltip is for, and the systems ship both halves: Carbon has a documented tooltip for
truncated table text, Ant Design pairs `ellipsis` with a Tooltip, AG Grid has `tooltipField`,
Salesforce pairs `slds-truncate` with a title. Clipping without revealing was the incomplete half
of the pattern. `design.md` now says which case is which, so the distinction survives.

**Only where it is clipped, and that is what makes it affordable.** `scrollWidth > clientWidth`
per cell. A tooltip repeating text you can already read is noise, and a `tabindex` on every notes
cell would add a tab stop per row — measured, `/adjustments` has **42** notes cells and **0** are
clipped, so it gains neither a tooltip nor a tab stop. `/purchases` has 14 and all 14 are clipped.

**The bubble is `aria-hidden` and the cell gets no `aria-describedby`** — a correction to the
mockup, which had used one. CSS clipping is visual only: the whole string is in the DOM and a
screen reader has already read it, so describing the cell with a copy of its own text would
announce it twice. That is the main fault of `title`, and it would be no better for being ours.

**WCAG 1.4.13 is why this is a controller.** Dismissible with Escape, hoverable so you can move
onto the bubble to read or select the text, persistent. The mockup got "hoverable" half right —
the bubble stayed on screen forever once the pointer left it, because only the cell had a
`mouseleave`. Fixed in both.

**Alternatives rejected.**

- **The `title` attribute.** Shown in the preview so it could be compared directly: nothing on
  keyboard focus, nothing on touch, no control over appearance, ~1s delay, and announced on top of
  the text a screen reader just read.
- **Making every notes cell focusable.** 42 extra tab stops on one page for no gain.
- **Rendering the tooltip inside the cell.** It would be clipped by the thing it exists to escape —
  `.table-scroll`'s overflow and the card's `overflow-hidden`. It is `position: fixed` on the body,
  which is also why the controller hides it on any scroll: a fixed element does not follow what it
  points at.

**Touch is the honest gap.** There is no hover on a phone and a tap target the size of a table cell
fights the row. The detail page remains the answer there, which is what it already was.


---

## 2026-08-25 · A table row is one line, with three classes that make that survivable

**Area.** `.data-table td`, `.wrap`, `.name`, `.pin-col`, `clipped_text_controller`, `design.md`.

**Decision.** Option C of [`table-row-height-options.html`](mockups/table-row-height-options.html)
plus C2 and C3 of [`long-names-in-tables.html`](mockups/long-names-in-tables.html): cells do not
wrap, a name column is capped at 18rem, the identifying column is pinned, and anything clipped is
revealed on hover and focus.

**Why nowrap.** A wide table can have short rows or fit the screen, not both. Carbon, Material,
Stripe and Linear all pick the short row, because a table is read *down* a column and a ragged row
height breaks that, while a sideways scroll is a deliberate act you take once — and WCAG 1.4.10
Reflow exempts data tables from the no-sideways-scroll rule for the same reason. Measured:
`/distributions` **1,339px tall with three row heights → 943px with one**, `/purchases` 1,111 → 783.
Four tables were already single-line and did not move.

**Why nowrap alone was not enough, which the user found before I did.** It hands the layout to
whoever typed the longest value. Measured on `/distributions`: one 72-character partner name took
that column from 263px to **493px** and dropped the columns visible without scrolling from **8 to
6** — the first to go being Total value. There was no limit of any kind. `.name` caps it at 18rem,
and **the number is measured**: the longest values in the database are a 32-character partner and a
36-character item, about 263px, so the cap is inert on everything that exists today and engages
only on outliers. A cap that fired constantly would be a different, worse design. It is a *width*,
not a character count, because in proportional type "Illinois" and "Warehouse" are both nine
characters and 12px apart.

**Pinning answers the half a cap cannot.** Capping stops one row ruining the table; pinning stops
the sideways scroll costing you the row's identity. Without it the partner cell sits at **−542px**
once `/distributions` is scrolled right. `background-color: inherit` rather than white, so the cell
keeps whatever the row is doing — hover, the new-record highlight, zebra striping — instead of
drawing a white stripe through it. Verified under hover: row and pinned cell both
`oklch(0.984 0.003 247.858)`.

**A claim of mine that was wrong.** Recommending the cap, I said the reveal was "already built for
any clipped cell". It was not — `clipped_text_controller` queried `td.notes`, so a capped name
would have clipped with no way to read it. It now keys on **any** cell where
`scrollWidth > clientWidth`, which *is* the property: a wrapping cell grows downwards and an
uncapped `nowrap` cell grows sideways, so a cell only overflows when something is clipping it.
Keying on a class list would have failed again at the third kind of column. Reads are batched
before writes, because `/adjustments` is 42 rows and interleaving them re-lays-out per cell.

**The escape hatch is not hypothetical.** `/item_categories` renders a `<ul>` of item links in a
cell; a list on one line is unusable, and it keeps all twelve links with `.wrap`.

**Alternatives rejected**, all recorded in the second mockup: priority-based column hiding (needs a
priority per column and hides data silently, poor on a page people reconcile numbers from),
user-chosen columns (storage, defaults and a settings UI, out of proportion), and a card layout
below `md` (solves the narrow case, does nothing for the desktop case being asked about). **Fewer
columns is still the better answer for `/distributions` specifically** and remains open: twelve
columns, two adjacent dates, a shipping cost empty on every seeded row. Only dropping a column
makes that table narrower *and* shorter.

**A selector mistake worth recording.** The mockup's sticky panel silently did nothing:
`td.name:first-of-type` counts element *type*, so it means "a `td` that is `.name` and the first
`td`" — and the first `td` is the ID cell. It matched nothing and the panel behaved exactly like
the one above it while claiming to demonstrate pinning. The shipped version uses an explicit class.


---

## 2026-08-25 · Row actions collapse into a menu, and `role="menu"` becomes true

**Area.** `shared/essentials/_row_actions`, `popover_controller`, `overlay-audit.js`, four row
partials, `design.md`.

**Decision.** Option C of [`row-action-menus.html`](mockups/row-action-menus.html): three or more
row actions collapse behind a kebab, with a visible primary **only** where the row does not already
link to its record.

**Measured.** The actions column on `/distributions` was **331px** — the second-widest column in
the table, wider than Total items, Total value and Status together. It is **60px**. `/items` the
same; `/vendors` keeps a View and is 160px, and its table now **fits its region** for the first
time. Row heights are a single value everywhere.

**Why no visible View on three of them.** `/distributions`, `/items` and `/purchases` link to the
record from the row's first cell. A View button beside that is two controls with one destination,
which is the duplication the tab-actions pass removed. `/vendors` and `/requests` have no row link
and keep one.

**Two things found while building it, both pre-existing.**

The first is the more serious. The overlay audit requires a popover panel to declare a role, and
the account menu has declared **`role="menu"` since the day it was built while
`popover_controller` had no arrow-key handling at all** — the ARIA menu pattern requires it. A
promise in an attribute that nothing kept, and nothing noticed until row action menus multiplied it
by **62 findings**. The choice was to copy the false promise, dodge it with a vaguer role, or make
it true. The controller implements `ArrowDown`, `ArrowUp`, `Home` and `End` now, **gated on
`role="menu"`** — because the date range panel is `role="dialog"` and holds date inputs, where an
arrow key belongs to the input and hijacking it would break adjusting a date from the keyboard.
Verified: Edit → Deactivate → wraps, End and Home to the ends, and the date panel untouched.

The second: `.table-scroll` sets `overflow-x: auto`, which forces `overflow-y` to compute to `auto`
as well, so an absolutely positioned panel is clipped on **both** axes and the last row's menu was
cut off by the bottom of the table. `data-popover-fixed-value` places the panel against the
viewport instead. Opt-in, because the account menu and date picker have no clipping ancestor and
moving with the page is the better default. Hit-tested at the first and last row of three tables.

**A `<form>` cannot sit between `role="menu"` and its items.** `button_to` wraps its button in one,
so the wrapper takes `role="none"` — the same trick an `<li>` needs in a menu. Without it the menu
owned a form rather than menuitems, and the spec counted one item where there were two.

**An unavailable action stays in the menu, disabled.** `design.md` already drew the line: a form
action gets a genuinely `disabled` `<button>`, a link action a `<span aria-disabled>`. I had made
items' unavailable Deactivate a span, which broke a request spec that asserts the disabled
attribute — and the spec was right, because only a form control can be `disabled`.

**Where the keyboard check lives, and why not in RSpec.** Cuprite would not deliver a key to the
focused node: neither `page.send_keys` nor `Element#send_keys` reached it, and the first version of
that spec **passed for the wrong reason** — focus had landed on a filter input, so "not the first
item" was trivially true. Arrow movement and Escape-with-refocus are checked in
`overlay-audit.js`, which drives a real browser across all 90 popovers rather than one. The RSpec
specs keep what they can test honestly: the trigger's name and ARIA, the item count, initial focus,
and that the panel is `fixed`.

**What is not proven.** The role check is proven in both directions — 62 findings before, 0 after.
The new arrow-key check is proven only positively: arrows work and the audit is clean. Breaking the
handler to watch the check fire made the audit's own navigation time out, so that direction is
untested. Recorded rather than glossed.

**Alternatives rejected.**

- **Hover-revealed kebab**, as Gmail, Linear and GitHub ship. No hover on touch, and a keyboard user
  cannot reach a control that does not exist yet.
- **Two visible actions plus a kebab.** 212px against 60px, for a second action whose identity
  differs by user.
- **`role="group"` or no role**, to avoid promising arrow keys. It would have left the account menu's
  existing false promise in place, which is the actual defect.


---

## 2026-08-25 · A scrolling table has to admit it scrolls

**Area.** `table_scroll_controller`, `.table-scroll`, `design.md`.

**Decision.** Option D of
[`table-scroll-affordance.html`](mockups/table-scroll-affordance.html): a directional fade at
whichever edge has content behind it, plus scrollbar styling where the platform honours it.

**The defect, measured.** `/distributions` hid **486px of columns**, the scrollbar was an overlay
one taking **0px** of height, and there was no fade, shadow or hint of any kind. The only signifier
was `aria-label="Table, scrollable"`.

**Why no audit caught it, which is the part worth keeping.** The region was built for the keyboard
and the screen reader and serves both — a focusable `role="region"` with a name — and that is
exactly what `keyboard-audit` and `axe` check. An overlay scrollbar is *invisible to a
computed-style test*: `offsetHeight - clientHeight` is 0 whether the platform draws an overlay or
nothing at all. So every audit reported clean while the one group left out was people looking at the
page with a mouse. The lesson is the same one three audits have taught already — a check that reads
a proxy reports what the proxy says.

**The fade is the signal; the scrollbar is a bonus.** `::-webkit-scrollbar` makes Chrome and Safari
draw a scrollbar that reserves space, but Firefox ignores the pseudo-element and `scrollbar-width`
cannot force a scrollbar to take space at all. **It could not be verified in headless Chromium
even with `--disable-features=OverlayScrollbar`**, so the preview labelled that panel unverifiable
rather than implying it worked, and the CSS comment says the same. The fade depends on nothing and
is what actually answers the complaint.

**Directional, not permanent.** A fade always on both edges is decoration; one only where content is
hidden is information. A table that fits gets none — verified on `/adjustments` and `/vendors`,
which report `data-overflow=""`.

**Three implementation notes.**

- **The fade is on the *parent*, via `:has()`.** A pseudo-element on the scroller scrolls away with
  the content, which is the usual way this is built wrong. Every one of the **66** `.table-scroll`
  regions sits directly inside a card's body div, so the parent is a reliable anchor and none of
  them needed a wrapper adding by hand. Where `:has()` is unsupported there is no fade, which is
  what there was before.
- **One controller on the shell, not 66 attributes in views.** `scroll` does not bubble but it does
  capture, so a single listener on the root hears every region, and a table arriving in a Turbo
  frame is picked up without the view knowing the controller exists — verified by clearing the
  attribute and dispatching `turbo:frame-load`.
- **`pointer-events: none`, always.** The fade sits over the rightmost column, which on these
  tables is the actions menu. Hit-tested: both the menu trigger and the pinned cell's link are
  reachable through it. One scare on the way was a hit test returning null for the trigger — it was
  at x=1849 in a 1440 viewport, off screen because the table scrolls, not blocked by the fade.

**Alternatives rejected.**

- **A background-gradient fade** with `background-attachment: local`, which needs no JavaScript at
  all. The table's rows are opaque white and paint straight over it.
- **A permanent fade on both edges.** Decoration that says nothing about where the content is.
- **A text hint** such as "scroll to see more columns". It takes vertical space on every table
  forever to say something a 40px gradient says continuously and only when true.


---

## 2026-08-25 · Never fade a frozen column

**Area.** `table_scroll_controller`, `.pin-col`, `design.md`.

**Decision.** The start-of-scroll signal depends on whether the first column is frozen. Where it is,
there is **no fade** and the column casts a shadow to its right instead, appearing only once content
has passed underneath. Where nothing is frozen, the fade at the edge stays.

**Why: the fade I shipped yesterday was a contrast failure.** It was drawn at the container's
`left: 0`, which is exactly where `.pin-col` sits. Sampling the painted pixels of the ID cell on
`/distributions` at 4×, the fade lifted the darkest ink from **69 to 144** — **9.59:1 down to
3.19:1** against white. WCAG 1.4.3 wants 4.5:1. A column-by-column profile put **19 of the 26 inked
columns** under it, the worst going 63 → 164. And that is the *darkest* pixel of each glyph, so the
rest of the stroke is worse.

It is also wrong on its own terms, before any measurement: a frozen column does not move, so fading
it as a scroll signal says something untrue about it, and it obscures the one column pinning exists
to keep readable. **Six of the seven tables that overflow have a frozen column**; only `/items`
does not.

**Why no audit caught it, again.** axe reported **0 violations across 156 pages** while this was
live, because it computes contrast from *declared colours* — a gradient painted on top by a
pseudo-element does not appear in any element's computed style. This is the same failure mode as the
overlay scrollbar the day before, and the same lesson for the third time this month: a check that
reads a proxy reports what the proxy says. **A contrast question involving an overlay can only be
answered from painted pixels.**

**Why the controller has to supply `data-pinned`.** CSS cannot work this out. The existing fade is
`div:has(> .table-scroll)`, and asking "…whose `.table-scroll` child contains a `.pin-col`" needs a
nested `:has()`, which **Selectors 4 forbids**. So `mark()` sets `data-pinned` on the region and the
CSS keys off it. Cheap — one `querySelector` per region, and it is set once.

**Alternatives rejected.**

- **Offsetting the fade past the frozen column** with a `--pin` custom property set from the measured
  column width. It works, and it is more machinery than the question deserves: a shadow is what
  Carbon, Ant Design, AG Grid and Airtable all use, and the boundary is the thing worth marking.
- **Making the fade weaker.** Any opacity over text costs contrast, and the column is the one that
  must stay readable. There is no value that is both visible and safe.
- **Dropping the frozen column.** It is doing its job; the fade was the mistake.

**Left open.** The fade tells you there is more and gives you nothing to act on: the scrollbar is an
overlay taking **0px**, and on **five of the seven** overflowing tables it is *below the fold* —
296px below on `/distributions`. `docs/mockups/table-scroll-controls.html` puts four options for an
actual control, with a recommendation, and is awaiting a decision.


---

## 2026-08-25 · The fade was invisible, so the table got a rail

**Area.** `table_scroll_controller`, `.table-rail`, the edge shadow, `design.md`.

**Reported.** "It is still unclear how the fade is triggered. I don't see it and cannot replicate
it." Both halves of that turned out to be findings.

**The trigger was never the problem.** The end signal is on from first paint — on a fresh load of
`/distributions` with nothing scrolled, `data-overflow` is already `"end"` and the controller is
mounted. It is state-driven, not scroll-triggered.

**The fade was invisible because it was white on a white table.** I had been verifying its computed
`opacity`, which is a *proxy* — the third time this month. Screenshotting the 68px strip with it on
and off and diffing painted pixels: it moved the background by a mean of **0.28 of 255**, or 0.1%,
while **erasing 26% of the text** it lay over. Its only measurable effect was damage.

A white scrim is the standard treatment for text running out of a box, and I applied it to a table
whose rows are already white. **A scrim only works against content darker than the scrim.** Measured
alternatives: a hard 3px rule 1.83 (also imperceptible), an inset shadow 8.35, a grey gradient 9.59.
Chose the **inset shadow** — 0% text erased, and it matches the shadow the frozen column already
casts. Shipped it measures 7.95 on `/distributions` and 8.12 on `/items`.

**And an edge signal is not enough anyway, which is why option B was right.** It can say *there is
more*; it cannot say *you can move*. The platform will not say it either — the scrollbar is an
overlay taking **0px**, and on **five of the seven** overflowing tables it is below the fold, 296px
below on `/distributions`. So the table now has a rail: a drawn horizontal scroll control that rides
the fold, as Ant Design (`<Table sticky />`), Confluence and Jira all do.

**Four decisions inside the rail.**

- **`fixed`, not `sticky`.** `section.card-surface` is `overflow: hidden`, which makes it the sticky
  container. A probe rail inside it did not track the viewport — measured, not assumed.
- **It settles *below* the table, not over it.** The first version sat at `bottom - height`, over the
  last row, and being a control it took the pointer: the hover on the bottom row's comment cell went
  to the rail and the clipped-text tooltip never opened. **Three specs that had been passing caught
  it.** The card reserves a strip instead. It does still float over a row while the table runs past
  the fold — the row already cut in half by the bottom of the window — which is what Ant Design's and
  Confluence's do too.
- **`aria-hidden`, exactly as a native scrollbar is.** The region is already a focusable named
  `role="region"` that the arrow keys scroll. A focusable rail would add a second tab stop per table
  duplicating a path that already works and is already announced. **This reverses what the preview
  panel promised** — it advertised `role="scrollbar"` and arrow keys as a point in B's favour. On
  reflection that was a worse design: it is a pointer affordance, and the keyboard was never the gap.
- **Injected by the controller, not written into 66 views**, consistent with the earlier decision to
  mount one controller on the shell. It is removed again when a table fits.

**Alternatives rejected.**

- **Bounded height, the spreadsheet model** (C). Nested scrolling on a page that already scrolls, and
  no single height suits both `/transfers` at one row and `/adjustments` at 42.
- **A proxy scroller above the header** (D). It depends on the platform drawing a native scrollbar,
  which is the broken thing. Its own preview panel rendered empty, which made the argument.
- **Paddle buttons** (E). No data grid in wide use ships them; they are a tab-strip control, and they
  give no position feedback.

**A claim of mine to correct.** The preview said a sticky rail "has to yield to anything else that
lives at the bottom of the viewport. Nothing does today." Measured across 13 routes, two things do:
the off-canvas sidebar (`inset-y-0`, translated out, no conflict) and **rack-mini-profiler's badge**,
`position: fixed; bottom: 0; z-index: 9999`, on five routes. It is development-only and sits above
the rail rather than under it, so nothing breaks — but the claim was stated without being checked.


---

## 2026-08-25 · A narrow table stops being a table

**Area.** `table_stack_controller`, `.data-table[data-stack]`, `design.md`, `docs/onboarding.md`.

**Decision.** Below **640px of card width** a data table becomes a list of labelled fields — one
field column below 416px, two above it. Option A of `docs/mockups/table-stacking.html`.

**The defect, measured.** **All fifteen tables scrolled sideways at 320px, and at 375**; thirteen at
640. The worst hid **80% of its width**: `/distributions` needs 1,638px and had 320. On `/purchases`
you could see a fifth of the table.

**This reverses a written convention, deliberately.** `design.md` said tables scroll, on the strength
of WCAG 1.4.10 Reflow exempting data tables. **That exemption is permission, not advice** — it says a
data table is *allowed* to scroll, not that four fifths of one should be off screen. The system was
also already contradicting itself: the line item row stacks below `sm` with a label per cell, and the
reason recorded for it — "four columns at 320px leaves the item picker 72px, which is not a control
anyone can use" — applies word for word to nine columns of purchase data at 286px.

**The threshold is the card's width, not the viewport's.** Measured on `/purchases`: at a **1023px**
viewport the card is **973px**; at **1024px** it is **702px**, because that is where the sidebar
appears. A viewport breakpoint at `lg` would have returned the table to table form exactly where it
had least room. 640 was then chosen over 704 so the result is also monotonic in the viewport — at 704
a 1024px viewport would stack while 768 stayed a table.

**But not via a `@container` query, which was the obvious tool.** `container-type: inline-size`
computes to `contain: layout`, which makes the element a containing block for **fixed** descendants.
The row action menus are `position: fixed` precisely so they can escape this card, so every one of
them would have been positioned against the wrong box. The controller sets an attribute instead.

**Two things this pattern is usually built without.**

- **Labels from `<thead>` by column index, into a real element.** The usual build is `data-label` on
  every cell read by `::before`. That is **299 headings across 71 views** to write and keep in step,
  and generated content is not reliably announced.
- **The table's semantics restored explicitly.** A browser stops exposing rows and cells as a table
  the moment `display` is not `table`, and `thead` is `display: none` here — a screen reader would
  have been left with unlabelled text in no structure. The roles go on always, because a role cannot
  be applied conditionally.

**Two defects found while building, both by things that were already passing.**

- `table_scroll_controller` drew a **rail for a stacked table**, because on first paint it runs
  before this one and cannot see that the table is about to stop overflowing. It now listens for a
  `table:stack-change` event.
- A `font-weight: 600` on the card's title **did nothing**: the views put `font-medium` on that cell,
  and a utility beats a rule in `@layer components` whatever its specificity. Removed rather than
  forced — a rule that silently does not apply is the same class of problem as a mockup that lies.

**The cost, stated plainly.** `/purchases` at 320px goes from 1,448px tall to **7,614px**. That is
the trade being made: down a page you can read rather than sideways through one you cannot.

**Alternative kept on the table.** Option B — the leading fields with the rest behind a per-row
disclosure — measured **37% shorter** (245px per record against 388). It was recommended in the
preview and not built, because it needs a judgement per table about which fields lead, and the
request described A. The machinery is shared, so B is an increment on this rather than a rewrite.


---

## 2026-08-25 · The edge signal drops to 6%, and a shadow that never painted

**Area.** The `.table-scroll` edge shadow, `.pin-col`, `table_scroll_controller`, `design.md`.

**Reported.** The grey overlay looks odd and quaint. It did, and the numbers agree: isolated by
shooting the strip with the treatment and without it, what shipped changed the background by up to
**62 of 255** and tinted **28.5% of the visible table**. Ant Design's production value for the same
signal is **6% over 10px** — max change **10**, touching **6.6%**. What shipped was six times heavier
than the most-used table component on the web.

**Decision.** Ant Design's value, `rgb(5 5 5 / 0.06)` with a 10px offset and 8px blur, on **both** the
container edge and the frozen-column boundary. One number for one meaning: they had been 40% and 28%,
which is two conventions where there should be one.

**Why it got so heavy: a bad metric.** To decide whether an edge signal was visible at all, I
averaged luminance change over a 68px strip. That measure **rewards a broad smear and punishes a
crisp line** — a 1px rule changes almost no area, scored 1.83, and I wrote it off as *imperceptible*.
By sharpest local step it is **43.4**, among the most visible options available. The eye finds edges
by local contrast, not by area average. The heaviest option won because the metric was biased toward
heaviness.

**And the ground had moved.** When the shadow was chosen there was no rail, so the edge was carrying
the whole job of saying the table scrolls. With a real control present the edge only has to say
*content is cut here rather than ended here*.

**The larger find: a `box-shadow` on a `td` is never painted here.** `.data-table` is
`border-collapse: collapse`, under which Chrome does not draw a cell's box-shadow. Verified with a
solid red 40px shadow — **0%** of its pixels on the cell, **50.9%** on a control `div`.

That means the frozen column's shadow **never appeared**, in any version: not the 28% shipped
yesterday, not the 6% shipped an hour before this, and not the `1px 0 0` hairline that had been the
column's divider since it was written. **The spec passed throughout**, because it asserted on
`getComputedStyle().boxShadow`, which reports the declared value whether or not a pixel changes —
precisely the failure mode written into `process.doc`. It was found only because extending the 6%
value to that shadow measured **zero change**, which was too clean a number to accept.

The fix is Ant Design's own arrangement, and now it is clear why they build it that way:

- the divider is a **`border-right`**, which paints under `border-collapse`;
- the boundary shadow moves to the **wrapper**, offset by a `--pin-width` the controller measures.

**This revives an option I rejected two days ago.** Offsetting the start shadow by the frozen
column's width was considered and dismissed as "more machinery than the question deserves" in favour
of a shadow on the cell. The shadow on the cell could not work, so the machinery is now the cheap
option. Recorded because the earlier reasoning still reads as sound and was wrong for a reason
nothing in it could have anticipated.

**Alternatives rejected.**

- **Nothing at all**, relying on the rail. Defensible, and the rail sits at the bottom of the table
  while the eye is in the middle of it.
- **A hairline rule at the edge.** Best on sharpness, wrong in meaning: a 1px line at the edge of a
  card that already has a 1px border reads as *the edge of the card*.
- **`border-collapse: separate`** to make cell shadows paint. It changes border rendering for every
  table in the app to fix one signal.


---

## 2026-08-25 · Four buttons become two, and every button gets a border

**Area.** `/requests`, `shared/essentials/menu_button`, `shared/essentials/menu_items`,
`BUTTON_VARIANTS`, `bin/design/button-audit.js`.

**Decision.** Option B of `docs/mockups/page-header-actions.html`: the CSV export and the picklist
PDF collapse into one **Export** menu, and the product totals move onto the card whose rows they
total. The page header goes from four actions to two.

**The rule already existed and nothing enforced it.** design.md has said "at most three actions,
exactly one of them primary, primary last" for weeks, and even anticipated the check — "the actions
container carries `data-page-header='actions'` so a spec can count what is in it". Nothing counted.
`bin/design/button-audit.js` counts now, over **27 page headers across three roles**, and found
`/requests` was the **only** page in the app that broke it. No page had two primaries, none put the
primary anywhere but last.

It has to run in a browser rather than over the source: half these actions are conditional on a role
or on a count being above zero, so `/requests` shows one action to an ORG_USER and two to an
ORG_ADMIN.

**The cost of the fourth, measured.** 707px of buttons wrapping to two rows at *every* width
including 1440, and a 242px header at 320px with each button on its own line. Now: **56px from 1440
down to 768**, and 150px at 320.

**Name the menu after its contents.** design.md's own remedy said "More actions", and that names
nothing. "Export" says what is inside. The rule is updated to say so.

**A summary of a table is not a page action.** This is the diagnosis design.md predicts for a fourth
button — "usually a section of the page wanting an action of its own". "Calculate product totals"
does not act on the page; it summarises the rows below it. It is on that card now.

**On the feature itself.** It works, and it does follow the filters — narrowing to one partner took
it from 46 items and 23,035 units to a smaller set, confirmed against the row count. My first test
of this said it was stale, and that test was broken: the modal renders *inside* the Turbo frame the
filters update. Three things were wrong and none was the maths:

- **No total.** 46 per-item figures and no sum — the one number the button's name promised. It has a
  `<tfoot>` now. There is a precedent against `<tfoot>` totals from the reports work, but it was
  about *duplication* with a summary band above the same table, and nothing duplicates this.
- **The wrong verb.** design.md: a button's verb is what will happen. Nothing is calculated on press.
  It is "Show product totals".
- **The wrong place**, as above.

**The find along the way: every primary button was 2px short.** design.md fixes the control height at
38px. `border` is 1px top and bottom, and only `:secondary` had one — so `:primary` and `:ghost` came
out 36px. Measured across 17 pages: **25 secondary at 38px, 16 primary and 4 ghost at 36px**. It had
been invisible because headers carried enough buttons to wrap; two buttons on one row showed it
immediately. Every variant carries a transparent border now, and the audit checks height.

**Alternatives rejected.**

- **A "More actions" menu**, which is what design.md literally said. It fixes the count and not the
  cause, and leaves the totals summary in the page header.
- **Moving only the totals**, leaving three buttons. Compliant, and it keeps two buttons for what is
  one idea: getting the data out.
- **Putting the totals control in the pagination footer** beside "Showing 1–15 of 119 requests",
  which is thematically right — both speak about the filtered set. The footer is a shared partial
  with no slot for it, and adding one for a single caller is not worth it.


---

## 2026-08-25 · One item is not a menu

**Area.** `shared/essentials/menu_button`, `design.md`.

**Reported.** "If there were 3 different kinds of reports, how does the user pick? I don't see it
under Export — it's only one export."

**The defect is real and I introduced it yesterday.** Both items in that menu are conditional on the
data: the CSV needs any requests at all, and the picklist only exists while something is
*unfulfilled*. Those conditions are independent, so an organisation with requests but none
outstanding gets a menu containing **one entry**. Proved it rather than reasoned about it — the seed
data is 119 pending requests, which can never produce the case, so it took a spec creating a single
fulfilled request: `MENU ITEMS: ["Requests as CSV"]`.

A menu of one is strictly worse than the button it replaced: a click to reach one thing, with its
label hidden behind a general word. It is the same class of mistake as collapsing a single row
action into a kebab.

**Decision.** The component collapses: given one item it renders a plain button. In the component,
not the caller, so every future caller gets it right — the caller cannot know how many of its
conditional items will survive.

**It collapses to the menu's label, not the item's.** "Export", not "Requests as CSV". Safe only
because a menu here is [named after its contents](#menu-button), so its name fits any one of them,
and it is the one that is a verb — design.md requires a button's label to say what will happen.
GitHub's Download menu behaves the same way.

**On the question behind the report: how does someone pick between three reports?** Two to about
four closely-related outputs belong in one menu, each item naming the content *and* the format.
Past that, or for anything that is not a straight download, it belongs in the reports hub rather
than a page header — `/reports` already carries Distributions, Donations, Purchases, Requests,
Compliance and Activity. A page-header menu is for getting *this page's* data out; it is not a
catalogue.

The trigger says there is a choice with `aria-haspopup="true"` for a screen reader and a 12px
chevron for everyone else. If a third output ever joins these two, the menu is already the right
control and only needs the item.

**Alternative rejected.** Rendering the menu regardless and letting it hold one item, on the grounds
that the control should be stable as data changes. Stability is worth less than not making someone
open a menu to find a single link.


---

## 2026-08-26 · A subtitle says something the title cannot

**Area.** 22 page headers, `design.md`, `docs/onboarding.md`.

**Reported.** "Copy like this on the requests page is not very helpful: *Essentials requested by
partner agencies*."

**Measured.** All **40 index pages** carried a subtitle, and about **20 were a definition of their
own heading**. "Requests" / "Essentials requested by partner agencies" is the clearest: anyone who
can read the title already has it, and anyone who cannot is not helped.

**Decision.** Option B of `docs/mockups/page-subtitles.html`: on an index page the subtitle says
**what you do here**, verb-led. 22 rewritten, 8 left alone.

**The rule came out of the app's own good examples**, not from taste. Four already worked —
`/reports` says how the reports work, `/events` says the ordering, `/admin/account_requests` says
the scope of both halves, the dashboard says the purpose. What they share is that each says something
the *title* cannot. None defines a word.

**Scope was rejected on a measurement, and it was the tempting option.** design.md already says the
opposite for a *card* — "the title names the thing; the subtitle states the scope" — and
`essentials_stats_scope` would have generated all forty. But the pagination line already says
"Showing 1–15 of 119 requests" on every one of these pages, so a scope subtitle is the same
duplication that removed the `<tfoot>` totals from `/distributions`. A convention that holds for a
card does not automatically hold for a page.

**Deleting them was the other real option** — GOV.UK's position, and the one an experienced user
would prefer, since they never read it. Rejected because this app is run by volunteers at 200+
non-profits and "kit", "product drive", "inventory audit" and "base item" are not words anyone
arrives knowing. Where the noun is jargon the sentence now carries the gloss **and** the action:
"Items bundled to go out as one. Allocate a kit to change how many you have." Deleting the only
in-place explanation to save a line is a false economy. It would also have changed the header's
layout on twenty pages, since the partial is `items-end` without a subtitle and `items-start` with
one.

**Writing copy that names an action means checking the action exists, and two of my own drafts were
false.** "Who can sign in, and what each of them is allowed to do" for `/users`, whose table is Name
and Email with no roles column at all; and a claim that a vendor must exist before a purchase, which
I had not checked. Both were cut. Six of the seven remaining claims were verified against the code
that implements them — `Fulfill request` really does post to `start` and redirect to
`new_distribution_path`; a donation form really does offer a donation site, optionally; `/users`
really does have "Invite user to this organization".

**Three empty greps nearly became three false conclusions.** Looking for the donation-site field in
`donations/_form.html.erb` returned nothing because the file is `_donation_form.html.erb`. An empty
grep is not evidence of absence, and it reads exactly like evidence of absence.

**Inclusive, gender-neutral and non-ableist, checked rather than asserted.** `copy-audit.rb` reports
clean on all six checks — but "0 findings across 0 checks" is also what a broken audit prints, so
coverage was proved by planting `Please`, `below` and `insane` in one of the new subtitles and
confirming all three were caught in that file. Then reverted.

**Alternative rejected.** One helper generating every subtitle from the model name. It is how the
definitions got there in the first place: a formula can produce a grammatical sentence but not a
useful one.


---

## 2026-08-26 · Copy review, and the partner portal was half done

**Area.** Five partner portal pages, `design.md` (new **Reviewing copy** section), `process.doc`.

**What showing the portal found.** The bank side was complete and the portal was not. **Three pages
carried no subtitle at all** — `partners/requests/new`, `partners/individuals_requests/new` and the
profile form — one defined "family", and the dashboard's subtitle was the partner's own name while
the *bank* dashboard says "What needs your attention at X".

That is the failure mode worth writing down rather than the five sentences: **the portal is a second
product with a second audience**, an agency volunteer rather than a bank one, and sweeping the bank
side feels like finishing. No audit distinguishes them, so a person has to. `Reviewing copy` in
design.md now says so, and `process.doc` carries it as step 6a.

**Removing the org name from the partner dashboard was checked, not assumed.** It is also in the top
chrome, so the subtitle was the second place it appeared and the page loses nothing.

**The review order matters, and the first step is proving the audit ran.** `0 finding(s) across 0
check(s)` is a pass and is also exactly what a broken audit prints. Planting `Please`, `below` and
`insane` and confirming all three are caught *in the file you edited* takes ten seconds and is the
only thing separating "clean" from "not looking". Same principle as every other proxy this branch has
found, applied to words.

**Two things flagged and deliberately not changed**, because they are judgement calls about voice
rather than defects, and they belong to whoever owns the product's tone:

- **First and second person are mixed.** The app says "your bank", "you serve", then "Edit **my**
  organization" and "Edit my profile". Both conventions are defensible; having both is not.
- **"Need help?" is a question where every other title is a noun or verb phrase.**

Neither is wrong enough to change unilaterally, and both are now in the review table in design.md so
the next person meets the question rather than the inconsistency.


---

## 2026-08-26 · Second person, and a probe that found a hole instead of proving one

**Area.** 14 strings, `design.md` (new **person** rule), `bin/design/copy-audit.rb`.

**Decision.** Option B of `docs/mockups/copy-person.html`. The app addresses the reader as **"you"**,
never "my", never third person. Where the possessive adds nothing it goes entirely — a partner has
one profile and one account, so "Edit profile" says everything "Edit my profile" does in less sidebar
width. "Your" survives where it distinguishes: "Our impact" became **"Your impact"**, against the
bank's figures.

**Measured before: 49 second person, 8 first, one string using both. After: 52 and nothing else.**
Third person never appeared, which was correct rather than an omission.

The eight were three different problems, and the taxonomy is the part worth keeping: **the reader's
own thing** (drop the possessive), **something needing distinction** (keep "your"), and **the product
or its maintainers** (name the party or drop it — "how to reach us" became "how to get in touch").

**"Need help?"** was the only page title in the app that was a question, and the *same feature* was
already called **Help** on the bank side — two names for one thing, across a page title, a page
`<title>`, the partner topbar and `help_link_label`. All four say "Help".

**"Say how many of each item you need" described half its form.** Every row of that form is *two*
controls, a "Select an item" dropdown and a quantity, so the sentence read as though the items were
already chosen. Checked against the markup rather than assumed. Both request forms now say "Choose
the items you need, and how many…".

### The audit part, which is the more useful half

Proving `copy-audit.rb` had read a changed file — by planting `Please`, `below` and `insane` — fired
**two** checks where three were planted. **The sensory check missed "the items below"**, a textbook
1.3.3 failure, because its noun list did not contain `item` and its verb list did not contain
`choose`. The habit of proving an audit ran found a hole in the audit instead. That is a better
argument for the habit than anything written down.

Broadening it then produced its own two lessons, both locked into the probe table:

- **A false positive immediately.** "Items below their recommended on-hand quantity" is real dashboard
  copy where "below" means *less than*. Spatial and comparative "below" are told apart by what
  follows: a comparative one is followed by the thing compared against. Hence a negative lookahead.
- **A silent regression inside the fix.** The lookahead's `a|an` alternative, without a trailing
  `\b`, matched the first letter of "**a**bout" — so "the details below about your bank" on the
  account request form was reclassified as comparative and stopped being reported. A real finding
  disappeared *because of the fix for a false one*, and only reappeared because the probe table was
  extended in both directions before the pattern was trusted.

Two genuine findings survived and were fixed: the account request form's "Fill out the details below"
lost the spatial reference, and my own line-item copy from earlier this session lost a "below" that
was doing no work.

**Alternative rejected.** Leaving the sensory check narrow, on the grounds that a short list has no
false positives. It also had a false negative on the most common phrasing of the failure it exists to
catch, which is worse: an audit that misses the ordinary case gives false confidence, where one that
over-reports gives work.


---

## 2026-08-26 · An interface has no speaker; a letter does

**Area.** 26 strings across the interface and the mailers, `design.md`, `bin/design/page-audit.rb`.

**Decision.** "We" goes wherever it is filler in front of the news, which is nearly everywhere in the
app: "We're contacting you to notify you that your password has been changed" is "Your password has
been changed" with eleven words of throat-clearing. Every one of the 26 got shorter.

**Three places keep it, each for a different reason**, and the line is *whether a reader expects a
sender*:

- **The onboarding welcome email**, 14 lines. Genuine correspondence with a voice — "We're delighted
  to hear from you", "We're supported by the non-profit Code for GoodOps". This is the one message
  that is a letter rather than a notification, and stripping it produces something colder and worse.
- **The privacy policy**, 13 lines. A legal document where "we" is the party making the commitment;
  rewriting it into the passive changes what it says.
- **The marketing page**, 3 lines — brand voice, plus a **customer quotation**, which is someone
  else's words and not ours to edit.

The mailers that lost their "we" were the ones *announcing* something: a change, a cancellation, a
rejection, a password. GOV.UK and Mailchimp both use "we" in transactional email, and that is fine
where the email is a letter — it is not fine as a preamble to a fact.

**A grammar defect fell out of it.** The cancellation notification said "**a** essentials request" in
both its HTML and text parts, and had since it was written. Rewriting the sentence to drop "We are
emailing you to notify you that" removed it. Copy nobody reads aloud is copy nobody proofs.

### The audit found more than the copy did

**`page-audit` flagged my own new heading**, "Contact Human Essentials", as Title Case. It was a false
positive with a real cause: the check had no notion of a **proper noun**, so any heading naming the
product would trip it. It has a `PROPER_NOUNS` list now, the same idea as `copy-audit`'s `ACRONYMS`.

Fixing that meant rewriting the scan, and the rewrite exposed how narrow the old one had been:

- It only matched a capitalised run **starting immediately after the tag**, so
  `Race/Ethnicity of Client Base` was invisible — the offending words were mid-heading.
- It captured `[^<]+`, so a heading whose text sits inside `<strong>` was **unreachable entirely**.
  Three of those existed in the partner profile forms.

**Four genuine Title Case headings** came out of that, all in a section whose every sibling was
already sentence case, and one of which contradicted its own edit-side card. The check now strips
inner tags and looks anywhere in the heading, verified by planting a violation and watching it fail.

**Alternative rejected.** Rewording "Contact Human Essentials" to dodge the false positive. It would
have left the audit blind to the next heading that names the product, and the copy was not the thing
that was wrong.


---

## 2026-08-26 · The calendar is restyled, and its toolbar is ours

**Area.** `distributions/schedule`, `calendar_controller` (new), `application.js`, `application.css`,
`design.md`.

**Decision.** Option A plus the toolbar half of C from `docs/mockups/calendar-chrome.html`: restyle
FullCalendar's grid in CSS the way select2 already is, and take the **toolbar** out of the library's
hands entirely.

**The font was never the problem**, though that is what it looks like. The calendar renders in
Figtree like everything else; what reads as another typeface is **16px at weight 400 against the
app's 14px at 500**. Worth stating plainly, because the obvious next move — hunting a font-family
bug — would have found nothing.

**Why restyle rather than replace.** design.md already settles it for select2, in almost the same
words and with literally the same numbers: *"It ships a 28px-tall, 4px-radius, 16px-text control in a
`#aaa` border."* FullCalendar ships 4px and 16px too. There is a precedent pointing the other way —
Litepicker was **deleted** rather than restyled — but that argument is *native control versus
dependency*, and there is no native month grid. Rebuilding event layout, day overflow, the list view
and Luxon's timezone handling is a great deal of work to fix an appearance.

**Why the toolbar is different.** Three buttons filled `rgb(44,62,80)` were a page's worth of
primary-looking chrome for moving the month, on a page whose real action is a quiet secondary. They
are ordinary components now, driven through public API — `today()`, `prev()`, `next()`, `datesSet`.
Three buttons are cheap to own, and owning them means a library upgrade cannot silently revert them,
which is exactly what had happened to the rest of this page.

"‹ Prev" and "Next ›" rather than bare chevrons: design.md reserves icon-only for a repeating row
action, and this is the shape the **pager** already uses for the same job.

### Three findings the styling work turned up

- **`!important` is required here and is not for select2.** FullCalendar injects its stylesheet into
  `<head>` at runtime, unlayered and later in source order than anything `application.css` can emit.
  The existing `.fc-day-other` rule had already discovered this and said so; the new rules follow it.
- **A palette swap breaks the contrast pair you did not touch.** Setting `--fc-today-bg-color` to
  `brand-50` put the *existing* slate-500 day number at **4.0:1**, and axe caught it on the first run
  after. The text colour never changed; the background under it did. Today's date is `brand-700` now,
  the pair the event chips already use — measured at **8.59:1** from painted pixels.
- **The mobile list view had never worked.** `defaultView` and `eventLimit` are FullCalendar **4**
  spellings and this app is on **6**, so both were silently ignored. Verified rather than inferred:
  running the new spec against the stashed old code reported `fc-dayGridMonth-view` at 375px, and
  against the new code reports `fc-list`. **A wrong option name is not an error, it is nothing** —
  which is why this survived a version upgrade unnoticed.

**Also.** The subtitle was "Scheduled distributions, by day", which is the subtitle rule failing in
its own words. It says what you can do now, including the thing the page's only button is for:
"See when each distribution is due out, or subscribe to this calendar from your own." Checked that
the Copy calendar URL button really does serve `text/calendar` before writing it.


---

## 2026-08-26 · Which calendar views earn their place

**Area.** `distributions/schedule`, `calendar_controller`, `db/seeds/calendar_seeder.rb`.
**Built** as recommended; `docs/mockups/calendar-views.html` has the preview.

**The starting position.** There is no view switching on the page at all, and never was:
FullCalendar's default toolbar carries `title` and `today prev,next` and no view buttons unless you
ask for them. The one view decision being made is made *for* the reader — below 992px it swaps to a
week list — and until the option names were corrected today, that swap never happened either.

**Day is rejected on the numbers.** Over the last year: **22 days** had any distribution at all,
mean **1.9**, and **13 of those 22 held exactly one**. A day view is twenty-four rows of hour axis to
say "Silver Spring, 9am", which the month cell already says in one line.

**Week earns it.** Mean **3.5** a week, peaking at **16**. Sixteen in a week is precisely the case the
month grid handles worst, because that is where `+N more` swallows the detail — and a week is the
horizon the page exists for: what is going out, and what has to be packed before it.

**Which kind of week is the interesting question, and the data answers it.**

- The times are **real**: the form takes `as: :datetime, minute_step: 15`, labelled "Distribution
  date and time". A bank does record that a pick-up is at 9:00.
- But a distribution has **no end**. The columns are `created_at`, `updated_at`, `issued_at`. On an
  hour axis every event is a zero-length block.
- And **24 of 48 rows sit at 00:00**, because `db/seeds.rb` sets a date with no time. A time grid
  stacks those at the top of every day, which reads as a midnight appointment rather than as missing
  data. (The 24 with real hours are `db:seed:calendar`'s.)

So `dayGridWeek` over `timeGridWeek`: it fixes the crowded day without drawing an axis this data
cannot honestly fill, and it needs no new plugin or importmap pin on a library the app has already
been caught trailing a major version of. If banks start recording times on everything, `timeGridWeek`
becomes the better answer and the change is a view name.

**On remembering the choice: the URL, and design.md has already made this call.** Of the three places
it could live — nowhere, `localStorage`, the URL — the page tabs rule already says why the URL wins:
*"it is also how a tab becomes something you can link to, bookmark and go back from."* A view is a tab
by another name. It is also the only option that answers "why does mine look different from yours",
which `localStorage` creates and cannot explain.


---

## 2026-08-26 · Seeding the past writes rows with no inventory behind them

**Area.** `db/seeds/calendar_seeder.rb`, `db:seed:calendar`, `db:seed:calendar:clear`.

**What is actually going on**, after getting it wrong twice. `Event` validates
`no_intervening_snapshot` **on create**, so an inventory event for a distribution dated before the
latest `SnapshotEvent` fails validation — and `DistributionEvent.publish` uses `create`, not
`create!`, so the failure is **silent**. `DistributionCreateService` then reports success.

The result is a distribution row that appears on the calendar, in the index and in every export, and
never moved a single item of stock. Verified: the twelve backdated rows the seeder had made carried
**0 events**, and deleting all twelve moved total inventory by **0**.

The same guard blocks the tidy-up from the other end — `Distribution#check_no_intervening_snapshot`
refuses to destroy them. So the seeder was creating rows that were both a lie and unremovable.

**Decision.** The seeder writes **nothing before today**, and there is no `PAST=1`: that option was
the wrong answer to a misdiagnosis. `db/seeds.rb` already leaves a few distributions in the previous
month, so Prev is not empty.

**And a worse one underneath: `destroy_all` on a distribution loses stock.** `Distribution` carries
only `before_destroy :check_no_intervening_snapshot`. Nothing on the model publishes a
`DistributionDestroyEvent` — only `DistributionDestroyService` does. So `destroy_all` deletes the row
and leaves its `DistributionEvent` behind: inventory stays reduced for a distribution that no longer
exists, and the event is orphaned. **The task had been printing that as its cleanup advice.**

Measured before the fix: destroying 20 seeded distributions holding 150 units moved inventory by
**0**. There is a `db:seed:calendar:clear` task now, going through the service, and the round trip is
lossless — **162,608 → 162,437 → 162,608**.

**What it cost, plainly.** Running `destroy_all` repeatedly while working this out left **140
orphaned `DistributionEvent` rows** in the development database, holding about **1,105 units**. The
event log and the distribution rows no longer agree there. `bin/rails reset_demo` is the clean
repair. The calendar page itself is unaffected, since it reads distributions rather than inventory.

**The generalisable part:** in an event-sourced app the model is not the source of truth, and
`destroy` is not how you remove things — use the service that publishes the compensating event. And
be suspicious of a delete that moves no numbers.


---

## 2026-08-26 · A conditional requirement belongs to the group, not to both labels

**Area.** `product_drive_participants/_form`, `requests/_new`, `bin/design/form-validation-audit.js`,
`design.md`.

**Reported.** "(phone or email required)" in the New product drive participant popup does not match
the design system.

**It was the residue of an earlier decision.** design.md records that four labels on this form once
wrote an asterisk by hand for their conditional requirements; the asterisks went and *the words
stayed*. The words were right — the placement was not.

**Measured.** The label is the field's accessible name, so a screen reader announced
**"Phone (phone or email required)"** as the *name* of the field, and then
**"Email (phone or email required)"** — the same condition twice, as identification rather than
instruction. Four fields, two conditions, each said twice.

**Decision.** The condition moves to the group's `<legend>`, which is where design.md already puts a
requirement belonging to a group rather than a control: *"A radio or checkbox group is marked on its
`<legend>`, not on each option. The group is what is required."* Neither phone nor email is required
alone; the pair is. The labels are now `Phone` and `Email`, and the rule is stated once.

The rule in design.md is generalised from "a radio or checkbox group" to "a requirement that belongs
to a group", because that is what it always meant.

### The audit had a hole exactly where the report was

`form-validation-audit` visited every `new` **route**. A modal has no route — it lives on an index
page behind a button — so **four modal forms had never been audited**. It opens them now, by
triggers verified one at a time, since there is nothing to derive them from.

It found two things immediately:

- **`New quantity request`** carried a `required` select with **no visible marker**: programmatically
  required, silently. Half of what design.md asks for. It has the red asterisk now.
- **`Import from CSV`** could not be opened from `/product_drive_participants` at all — four of the
  five pages carrying that modal render its trigger only while the list is **empty**, because Export
  takes the slot once there is data. Deliberate, and worth knowing; the audit points at `/partners`,
  which shows it always.

**Two mistakes in the audit change itself**, both caught before they shipped. A shared `formInView()`
helper referenced from functions handed to `page.evaluate` — which serialises them and drops
everything they closed over, so it would have been `undefined` in the browser. And `markedFor` still
only consulted a legend for radios and checkboxes, so the moment the condition moved off the labels
the audit would have stopped recognising these fields as conditional and said nothing at all.

**Left alone, and pre-existing:** `/partners/family_requests/new` shows no inline error and no
`aria-invalid` — only a summary. Verified against a stashed tree: it reports identically without any
of this work.


---

## 2026-08-26 · The family request form's real defect was not the one reported

**Area.** `partners/family_requests/_list`, `bin/design/form-validation-audit.js`.

**The audit said** `/partners/family_requests/new` showed no inline error and no `aria-invalid` —
only a summary. Both halves were wrong, and one of them was the audit's own.

**It had not been submitted.** Every child's checkbox is `check_box_tag "child-#{id}", child.active,
child.active` — **pre-checked**. So the submit did not post: it opened the confirmation dialog,
*"You are ordering 2,500 total items. Are you sure?"*. The audit's summary selector matched that
text and concluded the form had shown an error and failed to attach it to a field. It reports the
case honestly now — "the submit opened a confirmation instead" — and no longer reads anything inside
an open `<dialog>` as an error summary.

**There is nothing field-level for the error to attach to.** The form's only inputs are 36
checkboxes; the failure — "every line needs an item selected and a quantity greater than zero" — is
about the set, not about a control. A callout is the right place for it, and `aria-invalid` on 36
checkboxes would be a lie.

**The real defect was next to it, and no audit was looking.** Every checkbox's label was
`<span class="sr-only">Include This Child?</span>` — **36 identical accessible names**. A screen
reader user tabbing the table hears the same six words thirty-six times with nothing to say which
child. axe does not flag duplicate labels, so nothing caught it.

It is the defect `row_actions` already records — *"names the row, so a screen reader hears 'More
actions for distribution 24' rather than 'button' once per row"* — and takes the same fix: the label
names the child. Verified: **36 checkboxes, 36 distinct names**.

**A flaky spec of my own, found in the same pass.** The calendar's Back-navigation spec failed about
once in twenty: it called `page.go_back` straight after asserting the rendered class, so the
assertions raced the popstate handler. It waits for the history entry first now — ten consecutive
runs clean, and the full suite green. Worth recording because the failure was invisible in isolation
and only appeared in a full run, which is exactly the shape of thing that gets re-run and forgotten.
