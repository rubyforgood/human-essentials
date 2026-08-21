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
