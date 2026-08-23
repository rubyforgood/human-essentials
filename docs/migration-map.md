# Migration map: Bootstrap/AdminLTE to the design system

Where everything went, what replaced what, and what to do when you meet the leftovers.

Companion documents: [design.md](../design.md) is the specification for the system that
replaced it; [changelog.md](changelog.md) is the ordered record of what changed and when;
[design-decisions.md](design-decisions.md) is the running log of judgement calls;
[onboarding.md](onboarding.md) is the way in for a new contributor or user; and
[ADR 0011](architecture/decisions/0011-adopt-the-ruby-for-good-design-system.md) is the
decision itself.

## Status

Complete. Both frameworks are gone from the `Gemfile`, the asset path and the importmap, and
the legacy layouts are deleted.

Measured on 2026-08-18 with the commands under [verifying a
migration](#verifying-a-migration):

| | |
| --- | --- |
| Controllers on a design system layout | 63 of 65 |
| Views carrying design system markup | 299 of 392 |
| Undefined Bootstrap/AdminLTE/Font Awesome classes in `app/views` | 0 |
| Stimulus controllers | 30 |

The 93 views in neither column are not a backlog — 55 are ten lines or fewer, 12 are mailer
templates, and the rest carry no markup of their own. [changelog.md](changelog.md#current-state)
breaks that down.

| Not migrated | Why |
| --- | --- |
| `HistoricalTrends::BaseController` | Abstract; it has no views. Its three subclasses are migrated. |
| `StaticController` | `layout false`. The marketing home page and privacy policy are standalone public documents with their own stylesheet, not app screens. |
| `donations#add_item`, `donations#remove_item` | Removed in 2026, not migrated: routes with no actions whose only templates were 2018 scaffold stubs. |
| `@selected_date_range_label` | Set in `ApplicationController#setup_date_range_picker` and read by no view. `#date_range_label` itself is now used — by the stats caption and the empty states — but through the helper, not this ivar. |

### Class names that style nothing

**None.** `bin/design/undefined-classes.py` reports zero.

Twenty-three inert class names were removed in August 2026 — AdminLTE-era layout hooks
(`form-yesno`, `radio-yesno`, `col-w`), hooks for a served-areas script that no longer exists
(`pc-*`, `partner-served-*`), FullCalendar v4 names the library stopped emitting (`fc-ltr`,
`fc-unthemed`), and `animate-pulse-once`, which was a Tailwind theme extension added in 2021
(#2438) and dead from the moment Tailwind was first removed later that year. If that pulse on
the partner request success and error messages is wanted back, it is a `@keyframes` and one
class in `application.css`; nothing else survives of it.

They were documented as harmless leftovers first and then removed, because a permanently
non-zero audit is one people learn to ignore — the next dead class should stand out on its own.

**Three false positives the script had to learn**, each of which would have had something
deleted that mattered:

| Looked inert | Actually |
| --- | --- |
| `filterrific-periodically-observed` | The filterrific gem's own JS hook. |
| `form-inputs` | simple_form's. The gem scan had to include `lib/`, not just `app/` and `vendor/`. |
| `filter-bar-submit` | Defined in an inline `<style>` inside a `<noscript>`, which is what makes the filter bar submit without JavaScript. The script reads inline `<style>` blocks now. |

A class can also be deliberate without being styled — a Stimulus target or a spec selector. The
script separates those (32 of them) from genuine orphans rather than reporting them.

### Index tables without a pager

Every other index table paginates (`design.md` → Pagination). These eight do not. Row heights
were measured at 1440×900 on 2026-08-20; the band is the one they would take.

| Table | Row | Band | Why not, or why next |
| --- | --- | --- | --- |
| `/admin/partners` | 53px | COMPACT | **Should be next.** Every partner across every organization — 200+ organizations in production. Unbounded by construction. |
| `/admin/ndbn_members` | 45px | COMPACT | **Should be next.** A national roster, loaded by CSV upload; NDBN has some hundreds of member banks. |
| `/partners` | 65px | MEDIUM | Grows with the bank. A large one has 50–200 partner agencies, so 13,000px at the top end. |
| `/vendors` | 52px | COMPACT | Grows with use, though more slowly than partners. Has a CSV export, so it needs the separate-ivar pattern. |
| `/product_drive_participants` | 53px | COMPACT | Grows with use. Has a CSV export. |
| `/kits` | 111px | TALL | Bounded by how many kit types a bank chooses to define, but the rows are tall — 50 kits is 5,550px. |
| `/users` | 45px | COMPACT | Bounded by an organization's staff. Dozens at the outside. |
| `/storage_locations` | 65px | MEDIUM | Bounded by physical warehouses, and the table has a `<tfoot>` grand total. Paginating would leave a "Total" row that does not add up the rows above it — the number stays right and the label stops being obvious, which is worse than a long page for a table that is three rows in practice. |

Anything else still carrying `btn`, `card-body`, `form-group`, `col-md-*` or `fa-*` is a
defect rather than a page awaiting its turn: none of those classes are defined anywhere now, so
they render as nothing at all.

## The stack, before and after

| | Before | After |
| --- | --- | --- |
| CSS framework | Bootstrap 5.2 gem, plus Bootstrap 4.6.1 vendored inside AdminLTE 3.2 | Tailwind v4.3.3 |
| Build | sass-rails through Sprockets | `tailwindcss-rails` standalone CLI, no Node |
| Asset pipeline | Sprockets, with a `manifest.js`, a precompile list and a disabled CSS compressor | Propshaft: digests filenames and rewrites `url()`, nothing else (ADR 0012) |
| Typeface | Source Sans Pro, CDN | Figtree, self-hosted under `public/vendor/` |
| Icons | Font Awesome 4 and 5, two CDNs | Bootstrap Icons, self-hosted, compiled into the bundle |
| Shell | `layouts/application`, `_lte_navbar`, `_lte_sidebar`, `_lte_admin_*` | `layouts/essentials_app`, `_essentials_topbar`, `_essentials_sidebar` |
| Partner shell | `layouts/partners/application` | `layouts/essentials_partner` |
| Auth shell | `layouts/devise`, `_devise_shared` | `layouts/essentials_auth` |
| Modals | Bootstrap modal, jQuery `$(el).modal("show")` | Native `<dialog>` + `showModal()`, `dialog_controller.js` |
| Form styling | `simple_form_bootstrap.rb` | `simple_form_essentials.rb`, `:essentials` the default wrapper |
| Selects | bootstrap-select | select2 (kept), stylesheet now vendored |
| Date range filter | Litepicker + its `ranges` plugin, two unversioned jsDelivr pins | A preset `<select>` and two native `<input type="date">`; no dependency |
| Totals | `<tfoot>` under each table, and a separate summary report | `essentials_stats` above the table: one card, hairline separators, columns following the figure count, titled and scoped |
| Filter bars | A flex row of content-sized controls, applied with a Filter button, reloading the page | A grid of equal columns, applied on change into a Turbo Frame; no button, no reload |
| The storage location "show inventory at date" band | A hand-rolled `form_for` with its own copy of the control classes and a submit button, 125px and always open | `filter_bar` with `filter_date`, 71px collapsed |
| `admin/barcode_items` filter | A "Filters" card with its own heading, a Filter button, a Clear Filters link — and no `class_filter` behind any of it | `filter_bar` + `filter_select`, applying into a frame, and an action that actually filters. The last two filters that were not the component |
| The card surface | `rounded-2xl border border-slate-200 bg-white shadow-sm` pasted into six places, only one of them the card component | `.card-surface`, one component class in the Tailwind entry, used by all six |
| The icon tile | `essentials_icon_tile` at 36px, and the reports hub's own 28px copy that had also drifted on radius and text colour | One helper with `size: :sm` and `size: :md`; `page-audit.rb` sweeps for hand-rolled ones |
| The required-field marker | `<abbr title="required">*</abbr>` inheriting the label's slate-700 and carrying the browser's dotted underline for `abbr[title]` — a grey asterisk with three dots under it — plus a "Fields marked * are required." legend above every form | A `rose-600` asterisk with `text-decoration: none`, classed from the locale so it works in both. No legend |
| The dropdown chevron | Three: the browser's native arrow on 75 simple_form selects, an SVG chevron 18.5px from the border on 41 filter selects, and select2's CSS triangle at 7px | One `--chevron-down` variable, one `.select-chevron` class, one `SELECT_CLASSES` constant and an `:essentials_select` wrapper. Every visible select, 12px |
| JS | jQuery + Bootstrap + AdminLTE widgets | Stimulus; jQuery only where a third-party widget needs it |

## What was migrated, by area

Counts are files changed on the branch.

| Area | Views | Notes |
| --- | --- | --- |
| Partner portal | 93 | Its own shell and vocabulary. The profile forms were the largest and worst-behaved views in the app. |
| Super admin | 42 | Had no navigation at all after the shell swap until an admin rail was built. |
| Layouts | 26 | Three shells replaced five layouts and four navbar/sidebar partials. |
| Shared partials | 18 | Where the design system's own components live (`shared/essentials/*`). |
| Users and auth | 15 | Devise views moved to the split auth shell. |
| Reports | 14 | Fifteen reports, renamed `Subject — cut` so they sort together in the rail. |
| Items and inventory | 14 | Five page tabs across three controllers; expandable rows for per-location quantities. |
| Distributions | 14 | The confirmation flow, which turned out never to have worked. |
| Vendors, manufacturers, product drives, donation sites, participants | 44 | Mostly index/form/show triples; the most mechanical part of the work. |
| Storage locations, transfers, purchases, donations, requests, kits, audits, adjustments | ~50 | Core inventory movement. |
| Kaminari | 7 | Pagination partials, previously Bootstrap markup with no styling behind it. |
| Dashboard | 6 | Cards with stable ids the system specs depend on. |

## Pattern translation

What to write when you meet the old thing.

### Layout and structure

| Bootstrap / AdminLTE | Design system |
| --- | --- |
| `.container-fluid`, `.row`, `.col-md-*` | `grid gap-6`, `sm:grid-cols-2`, `lg:grid-cols-3` |
| `.content-header` + `<h1>` | `render "shared/essentials/page_header", title:` |
| `.card` / `.box` + `.card-body` | `render "shared/essentials/card"` |
| `.card-footer` | the card's `footer:` local |
| `.card-tools` | the card's `actions:` local |
| `.table`, `.table-striped`, `.table-hover` | `.data-table`, `.data-table.striped` |
| `.tab-pane`, `.nav-tabs` | `render "shared/essentials/tabs"` + `data-controller="tabs"` |
| `.modal`, `.modal-dialog`, `.modal-content` | `render "shared/essentials/modal"` (a native `<dialog>`) |
| `.alert`, `.alert-warning` | `render "shared/essentials/flash"`, or a tinted callout for inline notices |
| `.pagination`, `.page-item`, `.page-link` | `render "shared/essentials/pagination"`; kaminari partials style themselves |

### Utilities

| Bootstrap | Tailwind |
| --- | --- |
| `d-none` / `d-block` / `d-flex` | `hidden` / `block` / `flex` |
| `justify-content-between`, `align-items-center` | `justify-between`, `items-center` |
| `text-muted` | `text-slate-500` |
| `font-weight-bold` | `font-semibold` |
| `pull-left` / `pull-right` | `float-left` / `float-right` |
| `text-truncate` | `truncate` |
| `visually-hidden` | `sr-only` — **this one matters**: without it, screen-reader-only text is on screen |
| `w-100`, `h-100` | `w-full`, `h-full` |
| `rounded-circle`, `rounded-3` | `rounded-full`, `rounded-xl` |
| `list-unstyled` | `list-none` |
| `btn btn-primary btn-md` | `essentials_button_classes(variant: :primary, size: :md)` |

### Helpers and JavaScript

| Was | Is |
| --- | --- |
| `fa_icon "plus"` | still works — `IconHelper` maps ~75 Font Awesome names to Bootstrap Icons. New code writes `<i class="bi-plus-lg" aria-hidden="true">` |
| `UiHelper#new_button_to` and friends | unchanged API, design system output; `type:`/`size:` map onto variants |
| `data-bs-toggle="collapse"` | `data-controller="disclosure"` + `data-action="click->disclosure#toggle"` |
| `data-bs-target="#x"` | `aria-controls="x"` — the accessibility contract, not a style hook |
| `data-widget="expandable-table"` | `data-controller="expandable"` |
| `$(el).modal("show")` | `data-action="click->dialog#open"` + `data-dialog-id-param` |
| `$(el).modal("hide")` | `document.getElementById(id).close()` |
| `f.button :submit` | `f.button :button` — renders a real `<button>`, not `<input type=submit>` |

## Defects the conversion exposed

These were not styling problems. They were live bugs, most of them invisible until the system
specs ran — those had never been run during the migration and were failing 298 of 565.

| Defect | Consequence |
| --- | --- |
| Three profile partials closed wrappers they never opened | The browser closed the `<form>` early; the served-areas fieldset, the remaining sections and the submit button all sat outside it. Nothing below that point could be submitted. |
| Four Stimulus controllers toggled `d-none` | Partner-group reminder fields, shipping cost and the admin role picker could never be revealed. |
| Profile accordion declared `accordion` but its sections call `disclosure#toggle` | No section could open. |
| "Approve partner" rendered as POST against a GET route | Routing error instead of the approval screen. |
| `confirmation_controller` called Bootstrap's modal API inside a promise | The catch submitted the form, so the confirmation step never appeared — for distributions, transfers and all three partner request forms. This predates the migration. |
| `data-turbo-confirm` replaced `data-confirm` | This app loads rails-ujs; "are you sure?" silently vanished from destructive actions. |
| Admin shell built from the bank nav helper | Super admins had no way to reach organizations, users, base items or account requests. |
| The sinon test clock shim was dropped from `<head>` | Every `travel_to` spec compared a browser-computed date against a Ruby date months apart. |
| `flash.each` instead of `flash[key]` | memflash stores large messages in the cache and leaves a key; CSV import errors rendered as `Memflash-error-1787…`. |
| `remote ||= true` | `||=` cannot express "default true"; the admin barcode dialog submitted over AJAX to an action with no JS response. |
| select2 had no stylesheet | `.select2-container` had no size; the enhanced selects were unclickable. |
| `public/*.html` still linked `/assets/application.css` | Error pages served unstyled, including the 500 page that is served when nothing else can render. |
| Four `fa-*` names still passed into the bank-side profile accordion | Four section headers rendered an empty `<i>`. Found later, by grep, not by the tooling — see below. |
| The manufacturers CSV import was rebuilt on the new modal, and nothing was ever behind it | No `Importable`, no `Manufacturer.import_csv`, no `public/manufacturers.csv`: the button raised. It predates this branch — the same modal is on the pre-migration view — which is the point. A faithful rewrite asks whether a screen looks right, and a broken feature looks fine. Removed in August 2026 along with its route. |

The lesson is recorded in [design-decisions.md](design-decisions.md): a static sweep catches
what renders wrongly, and the system specs catch what renders fine but cannot be used. Neither
alone was enough.

## Verifying a migration

```bash
bundle exec rspec                 # system specs included -- they catch what a sweep cannot
bundle exec rubocop
bundle exec erb_lint --lint-all
ruby bin/design/status.rb         # which controllers are on a design system layout
ruby bin/design/page-audit.rb     # defects and debt, per view

bin/start                         # then, with the app running:
pw bin/design/route-sweep.js      # every HTML screen the router knows, as three roles
pw bin/design/wcag-audit.js       # axe, WCAG 2.1 A/AA
pw bin/design/overlay-audit.js    # opens every dialog and popover

# Every class token the views or the JavaScript use that nothing defines. Expect 0 orphans; the
# ~32 it also lists are Stimulus targets, spec selectors and gem classes, and are meant to be
# there. It sanity-checks its own extractor before reporting: Tailwind escapes `.` and `:` in
# selectors (`.mt-0\.5`), and a naive regex calls every such utility undefined -- the first
# version produced 186 findings, ~100 of which were Tailwind working correctly.
python3 bin/design/undefined-classes.py

# Routes whose request would raise, and routes another route answers first. Needs no server.
# Exits non-zero if anything is dead. 28 were, before it existed.
bin/rails runner bin/design/dead-routes.rb

# The opposite question: code with no route, no render and no caller in front of it.
bin/rails runner bin/design/dead-code.rb
```

**Restart the server after touching `config/application.rb`.** It is not reloaded in development,
and every browser audit here talks to a long-running process on port 3000. A stale one reported
a defect that had already been fixed, three times, while the app served the fix correctly on
another port.

Run all of them; each sees something the others cannot. The status script asks whether a view
has design system markup, and a view can have plenty while still passing a dead class into a
partial. `undefined-classes.py` catches the dead class but cannot tell you the page has no
`<h1>`. The browser sweep sees both — but only on the pages it visits, which is why
`route-sweep.js` asks the router for the list rather than carrying one.

That distinction is not theoretical. `sweep.js` has a hardcoded list of 56 paths and the three
historical trend pages were never on it. They were in the sidebar, on a design system layout,
and rendered a bare chart with no page header and no `<h1>` for the length of the migration.
Every audit ran clean over them the whole time. `route-sweep.js` covers 140 screens as three
different users, and found two more defects on its first run — nine unlabelled selects on the
partner profile editor and two on the child form, in a portal the old list never visited.

The sweep calls a page clean when it has no leftover Bootstrap/AdminLTE or Font Awesome
classes, exactly one `<h1>` and one `<main>`, no skipped heading levels, no unlabelled form
controls, no buttons without an accessible name, no stylesheets from outside the app, no
console errors, and is rendering in Figtree.

## If you find a leftover

1. Check the [pattern translation](#pattern-translation) tables above.
2. If the class is an app-specific hook rather than styling — `line-item-fields`, `confirm`,
   `nested-fields`, `partner-served-areas` and similar are read by JavaScript or by specs —
   leave it. Confirm with `grep -rn "the-class" app/javascript spec`.
3. If it is a Bootstrap class with no equivalent, ask what it was doing and build the design
   system's version. Record the choice in [design-decisions.md](design-decisions.md).
4. Re-run the sweep and the system specs for the area.
5. Add a row to [changelog.md](changelog.md) in the same change.

The legacy `*_button_to` shims are no longer used inside any table cell: they map onto
`:primary` and `:danger`, which are filled, and that is wrong for a row. They remain in use on
page headers and forms, where filled is correct.

CSV import now lines up exactly, in all four layers: five controllers include `Importable`, five
routes reach `import_csv`, five models implement it, and `public/` holds five templates — the
same five each time (partners, storage locations, donation sites, vendors, product drive
participants). It did not before. `ProductDrivesController` included the concern with no route,
no model method and no template, and the manufacturers page had the button and the modal and
nothing else. Both were removed in August 2026. If you add an import, add all four.

`bin/design/dead-code.rb` lists what the migration left behind, in full. The parts of its 118
findings that belong to this migration rather than to the app's own history:

- **6.1MB of fonts in `public/fonts` and `public/webfonts`** — Font Awesome, Lato and Raleway.
  Nothing has referenced them since ADR 0011 removed AdminLTE. They are the largest single piece
  of dead weight in the repo.
- **24 `public/img` files**, mostly old DiaperBase logos. Two files in that directory are live:
  `essentials.svg`, used twice by the auth shell.
- **Four partials nothing renders**, two of them carrying pre-migration markup that would have
  been caught if anything had rendered them — `class="date"` in
  `admin/organizations/_organization_row`, and `content_for :sidebar` with `class="vertical menu"`
  in `users/shared/_account_management_menu`.
- **11 of the 14 `*_button_to` shims in `ui_helper.rb` have no call sites left.** Only
  `new_button_to` (5), `edit_button_to` (1), `modal_button_to` (3), `refresh_button_to`,
  `cancel_button_to` and `download_button_to` (1 each) are still called, along with
  `submit_button` (19), `add_element_button` (11) and `remove_element_button` (5). The file's own
  comment claiming "~60 call sites pass `type:`/`size:`" is left as written but was true of the
  AdminLTE version, not this one.

One known inert leftover, so you do not have to work it out again: `class: 'form-horizontal'`
survives on 12 forms. Bootstrap 5 had already dropped it, so it was doing nothing before this
work either. It is left alone because removing it means editing option hashes rather than
substituting a token, and that kind of edit has already broken markup once on this branch.
