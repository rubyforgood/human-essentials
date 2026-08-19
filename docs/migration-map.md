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
| `DateRangeHelper#date_range_label` | Correct for the first time — `filters[date_range_label]` now carries a real preset name — but nothing reads its output. `@selected_date_range_label` is set in `ApplicationController#setup_date_range_picker` and consumed by no view. Left in place, and written down here, rather than deleted inside an unrelated change. |

Anything else still carrying `btn`, `card-body`, `form-group`, `col-md-*` or `fa-*` is a
defect rather than a page awaiting its turn: none of those classes are defined anywhere now, so
they render as nothing at all.

## The stack, before and after

| | Before | After |
| --- | --- | --- |
| CSS framework | Bootstrap 5.2 gem, plus Bootstrap 4.6.1 vendored inside AdminLTE 3.2 | Tailwind v4.3.3 |
| Build | sass-rails through Sprockets | `tailwindcss-rails` standalone CLI, no Node |
| Typeface | Source Sans Pro, CDN | Figtree, self-hosted under `public/vendor/` |
| Icons | Font Awesome 4 and 5, two CDNs | Bootstrap Icons, self-hosted, compiled into the bundle |
| Shell | `layouts/application`, `_lte_navbar`, `_lte_sidebar`, `_lte_admin_*` | `layouts/essentials_app`, `_essentials_topbar`, `_essentials_sidebar` |
| Partner shell | `layouts/partners/application` | `layouts/essentials_partner` |
| Auth shell | `layouts/devise`, `_devise_shared` | `layouts/essentials_auth` |
| Modals | Bootstrap modal, jQuery `$(el).modal("show")` | Native `<dialog>` + `showModal()`, `dialog_controller.js` |
| Form styling | `simple_form_bootstrap.rb` | `simple_form_essentials.rb`, `:essentials` the default wrapper |
| Selects | bootstrap-select | select2 (kept), stylesheet now vendored |
| Date range filter | Litepicker + its `ranges` plugin, two unversioned jsDelivr pins | A preset `<select>` and two native `<input type="date">`; no dependency |
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
| Items and inventory | 14 | Tab strip; expandable rows for per-location quantities. |
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

The lesson is recorded in [design-decisions.md](design-decisions.md): a static sweep catches
what renders wrongly, and the system specs catch what renders fine but cannot be used. Neither
alone was enough.

## Verifying a migration

```bash
bundle exec rspec                 # system specs included -- they catch what a sweep cannot
bundle exec rubocop
bundle exec erb_lint --lint-all
ruby bin/design/status.rb         # which controllers are on a design system layout
bin/start                         # then, with the app running:
pw bin/design/sweep.js            # 56 pages in a real browser

# Classes nothing defines any more. Expect no hits outside prose in comments.
grep -rnE 'btn btn-|card-body|form-group|col-md-|fa-|modal-dialog' app/views/
```

Run the grep as well as the other two. The status script asks whether a view has design system
markup, and a view can have plenty while still passing a dead class into a partial; the sweep
only visits 56 pages. The last defect found on this branch — four invisible icons on the
bank-side profile editor — was invisible to both and obvious to the grep.

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

One known inert leftover, so you do not have to work it out again: `class: 'form-horizontal'`
survives on 12 forms. Bootstrap 5 had already dropped it, so it was doing nothing before this
work either. It is left alone because removing it means editing option hashes rather than
substituting a token, and that kind of edit has already broken markup once on this branch.
