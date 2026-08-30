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
| ~~`toastr`~~ | **Gone.** Removed from `config/importmap.rb` and `application.js` after its last caller was migrated — see the defects table. |

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
| Reporting a validation error | A flash *and* an error summary on 18 forms, saying the same thing in two formats and firing two `role="alert"` regions | The summary alone. `flash_error_unless_summarised` keeps the flash for the operational failures that have nothing to summarise |
| The required-field marker | `<abbr title="required">*</abbr>` inheriting the label's slate-700 and carrying the browser's dotted underline for `abbr[title]` — a grey asterisk with three dots under it — plus a "Fields marked * are required." legend above every form | A `rose-600` asterisk with `text-decoration: none`, classed from the locale so it works in both. No legend |
| The dropdown chevron | Three: the browser's native arrow on 75 simple_form selects, an SVG chevron 18.5px from the border on 41 filter selects, and select2's CSS triangle at 7px | One `--chevron-down` variable, one `.select-chevron` class, one `SELECT_CLASSES` constant and an `:essentials_select` wrapper. Every visible select, 12px |
| select2's box | The vendored 2014 control: 28px tall, 4px radius, 16px text, a `#aaa` border, no focus style, on six selects across five views | The app's control box, restyled unlayered in `application.css`: 38px (`min-height` for a multi-select), 8px, 14px, slate-300, and the same focus ring as everything else |
| The line item row | A `flex-wrap` row per line carrying its own "Scan a barcode" field, an "or", a labelled item picker, a labelled quantity and a text "Remove" — five controls on three different bottom edges, 96px a row | `line_items/_line_item_table`: one scan bar per card, column headings once, an icon-only remove, a running total, 58px a row. All seven forms render the one partial |
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
| Fourteen pages had two page wrappers, and a 72px gap under the heading | The shape is a `px-4 py-6 sm:px-6 lg:px-8` closed after the page header and a second one opened for the content, so the first one's bottom padding stacks on the second one's top padding. Measured: **72px** between the heading and the first card where the design system's number is **24** (the header's own `mb-6`). `/organization` was the one reported by eye; the other **13** were found by counting the wrapper in the templates. All render, validate and pass every sweep — `route-sweep.js` reported no findings on all 14 both before and after. One wrapper each now, `space-y-6` between blocks, and all fifteen affected screens measure 24px. On `admin/users/edit` the roles card had been *outside* every wrapper, so it ran to the window edge with no page gutter. |
| The organization page's users table, spacing and action | Reported *after* the details card was rebuilt, because I had fixed one partial rather than looked at the page. The table was `<table class="table border">` — Bootstrap's `.table`, which this design system defines nowhere and which therefore styled nothing — in a card whose header was written by hand instead of passed as `title:`, with the invite button pushed over by `float-right`. The row partial had been migrated; the table around it had not. And Edit sat in the "Organization info" card's header, where it read as editing that card's six fields rather than the record's 28. `/users` had the same card with an **empty** `border-b` strip at the top of it — a hand-written header holding nothing, drawing a hairline for no reason. |
| The organization page's shell was migrated and its body was not | `/organization` — reached from the sidebar's bottom-left link and the account menu — kept 28 fields as flat `<p>` pairs with **zero `<dl>`**, six `<hr>` rendering **slate-900** (an unstyled `<hr>` inherits `currentColor` under preflight), **7 different vertical gaps** (24–93px), **15 of 28 labels in Title Case**, an icon on 14 rows, and invalid nesting that made the browser manufacture **2 empty `<p>`** — `</address>` was closed inside an `if` branch. It passed everything the app checks: HTTP 200, no legacy class, no JS error. Rebuilt as one card of eight bands with the fields as a `<dl>`. **The lesson for the rest of the migration**: "no Bootstrap classes" is not the same as "migrated", and no automated check the app has can tell the difference. |
| The barcode confirmation was invisible | `barcode_items/create.js.erb` announced a successful scan with `toastr.success(...)`, on a page using the essentials layout — which loads only `tailwind.css`. Measured on `/donations/new`: **zero toastr CSS rules load**, so its container rendered `position: static`, no background, no padding, appended at the foot of the document at **y=1284 on a 900px viewport** — below the fold. The scan worked and said nothing. The message is a flash bar now, rendered from the same partial the server-side strip uses, and `toastr` was removed entirely. The spec passed throughout, because `have_content` finds text whether or not anyone can see it; it asserts `[data-flash]` now. |
| Two static CSVs shadowed their own export routes | `public/product_drive_participants.csv` and `public/vendors.csv` were **import templates**, and Rails serves `public/` ahead of the router — so `GET /product_drive_participants.csv` returned the three-row sample file instead of the organization's data, and the same for vendors. Found when main added a filtered CSV export at that exact path and its spec returned 3 rows whatever the filter said. Both renamed to `*_template.csv`, which is what the other three templates were already called. |
| Three profile partials closed wrappers they never opened | The browser closed the `<form>` early; the served-areas fieldset, the remaining sections and the submit button all sat outside it. Nothing below that point could be submitted. |
| Four Stimulus controllers toggled `d-none` | Partner-group reminder fields, shipping cost and the admin role picker could never be revealed. |
| Profile accordion declared `accordion` but its sections call `disclosure#toggle` | No section could open. |
| Every enabled action in every row menu was half width and right-aligned | `_menu_items` rendered an enabled action through `essentials_action_button`, which applies `inline-flex justify-center` and wraps the form in `form_class: "inline-block"` — and the actions cell is `text-right`, so the inline-block inherited it and floated. Measured on `/vendors`: *Edit* at x=1 across 222px, *Deactivate* at **x=117, 106px wide**, in one 224px menu. A plain `button_to` with the item's classes now; all nine menus report identical lefts, widths and glyph positions. |
| Native `window.confirm` on all 44 destructive actions | Browser chrome — unstyled, unbranded, and it announces the page's hostname above the message. **Three audits could not see it and one depended on it**: `overlay-audit.js` opens `<dialog>` elements and a native confirm is not in the DOM; axe scans the document and has nothing to scan; and the system specs drive it with Capybara's `accept_confirm`, which only works on a *native* dialog, so a green suite is evidence for it. `overlay-audit.js` listens for the browser's `dialog` event now and reports 2. **Not yet converted** — every `accept_confirm` in the suite becomes a click on a real button, which is its own change. |
| Every destructive action confirmed with `window.confirm` | All **44** `confirm:` call sites, plus one raw `confirm()` in `utils/donations.js` that no attribute-based fix could reach. Browser chrome: unstyled, unbranded, announcing the page's hostname. Now `shared/essentials/confirm_dialog`, one per shell, filled in by `confirm_dialog_controller.js` — **no call site changed**. The click is intercepted in the capture phase and replayed, because rails-ujs's confirm hook is synchronous and a `<dialog>` is not. 35 spec call sites moved from Capybara's `accept_confirm`, which only drives a native dialog. |
| The new-kit warning sat below the fold | *You will not be able to change the composition of the kit once it is saved* rendered under both cards on `/kits/new`, measured at **y=922 on a 720px viewport** -- 765px below the `h1` and out of sight. A warning about something irreversible, placed after the decision it warns about. Moved directly under the page header: **y=205**. Its second sentence also said the name and visibility could be changed "via the kit's item", which leaks the STI detail that a `Kit` *is* an `Item`; it names the Items & inventory screen and links to it now. Of 26 callouts, four sat below a card and only this one was wrong -- the other three are scoped to a section and sit with it. |
| "Add other users at your bank" did nothing at all | `/users/new` was a registration form — name, email, **password**, confirmation — with **no `UsersController#create` behind it**. `essentials_form_for(@user)` inferred `users_path`, and `POST /users` resolves to `devise_invitable/registrations#create`, which for an already-signed-in admin answers *"You are already signed in."* and bounces to the dashboard. So the one link to it, on the dashboard's getting-started prompt, led to a form that could not add anyone. It posts to `invite_user_organization_path` now — the same `UserInviteService` call the organization page's modal makes, so there is one code path with two entry points. The password fields are gone: an invited user picks their own, and the users table records an `invitation_status` a directly-created account would never have. |
| Fields painted, then hidden by JavaScript | Reported as "a strange ghost button that appears for a second when you click refresh" on `/distributions/new`. It was the **shipping cost** field: the server rendered it visible and `distribution_delivery_controller` hid it on `connect()` unless the delivery method is `shipped`, which a new distribution never is. `/manage/edit` had the same defect in the reminder day fields. Both now render their `hidden` class from the server, so the controller only ever reveals. `bin/design/flash-of-hidden-audit.js` checks the whole class by diffing what is visible at `commit` against what survives. |
| A purchase could not start a distribution, or be printed | Two halves of one asymmetry between pages that are otherwise the same shape. **Neither was dropped by the migration** — checked against `origin/main`, where the purchase page carried only *Make a correction* and a delete button, and has never had either. The distribution one could not have existed: `copy_line_items` hardcoded `itemizable_type: "Donation"`, so a `purchase_id` would have been read by nothing and opened an empty form. Generalised, plus `copy_from_purchase` and a `purchase_id` branch in `distributions#new`. The print one needed a route, an action and a `PurchasePdf` — deliberately the same document as the donation receipt, honouring the same `hide_value_columns_on_receipt` setting, with "Purchased from" and "Amount spent" where the donation says "Donation from" and "Money Raised". |
| A camera that could not start looked like a dead button | Quagga's init callback did `console.log(err); stop()`, and `stop()` hides the viewport — so on any failure the panel opened and shut in one frame and said nothing. Reproduced both real causes in Chromium: **no camera** (`NotFoundError`) and **blocked permission** (`NotSupportedError`), and in both the viewport ended hidden, empty, with `aria-expanded` back to `false`. Each failure now writes a sentence into the viewport saying what to do. The insecure-origin case branches on `window.isSecureContext`, because "this browser cannot" and "this address cannot" are different problems with different fixes. |
| Three of four barcode scan fields used a broken overlay | The button was `absolute right-2 top-8` over a `pr-10` field: a **38px** field, a **36px** button, sitting **4px below** the field's bottom edge and not vertically centred, with a 28×36 tap target. The offset was tuned to one form's label height, so it drifted as soon as the markup moved. `design.md` had already settled this in the line-items section — *the scan field and its button are joined, one rectangle sharing a border, "which is what keeps them the same height by construction"* — and `line_items/_line_item_table` was the only one following it. All three are now `shared/essentials/_barcode_scan_field`, measured identical to the audit's bar: 0px seam, both 38px, 38×38 target. `form-validation-audit.js` also still pointed its "Invite a new user" modal check at the deleted `/users`; it points at `/organization` now. |
| The barcode form had no scanner | `/barcode_items/new` and `/barcode_items/edit` asked you to type a barcode by hand — the one thing a barcode exists to avoid. The camera scanner was already built and already loaded (`utils/barcode_scan` is imported by `application.js` on every page, quagga is pinned) and appeared on the line-item tables and both barcode modals; it had simply never been put on the form for creating a barcode. Same markup as the modal's, no new dependency. |
| `/users` deleted as redundant | It listed **name and email**; the organization page's own table shows those plus role, last sign in, status, reinvite and the row actions — a strictly weaker view of a list one click away, and by then reachable from nothing. Route, `UsersController#index` and `users/index.html.erb` gone, along with `users/shared/_account_management_menu.html.erb`, which was already rendered by no one and linked to both. `/users/new` **stays** — the dashboard's getting-started prompt links to it — but its back link now points at the organization page. |
| "Organization" was in two navigation surfaces, and "Co-workers" in none | Both Organization entries — the sidebar's pinned footer and the account menu — linked `organization_path` behind the identical `can_administrate?` gate. The only duplicated destination of 22 sidebar entries and 3 menu entries. The account-menu one is gone: an avatar menu is for the person, which is the one thing Slack, GitHub, Linear, Notion, Stripe, Atlassian and Shopify all agree on. Removing it surfaced the opposite in the same menu: **"Co-workers" was gated on `can_administrate?` *and* `has_cached_role?(:partner)`**, and a bank admin has no partner role, so it rendered for nobody — a gate copied from the partner top bar when the shell was built. Removed rather than repaired, because `/users` shows name and email where the organization page's table shows those plus role, last sign in, status, reinvite and actions. **`/users` now has no inbound link and is not deleted**; that is a separate decision. |
| An action that could not succeed still asked you to confirm it | The first cut of option B kept `confirm:` on every branch, including the one that cannot succeed — so deactivating a held item meant clicking, confirming "are you sure?", and only then reading that it was never possible. Two steps to a dead end. The `confirm:` is on the branch that can succeed and omitted from the one that cannot. |
| A disabled action gave no reason to anyone who could see | The `reason:` on an unavailable menu item was `sr-only`, so a screen reader heard "Deactivate, unavailable while this item is still in inventory or used by a kit" and everyone else saw a greyed-out word and nothing at all. Reported as confusing on `/items`, and it was a defect introduced by the row-actions change. Visible help text now — Polaris's `helpText` — with the dimming moved onto the label alone, because `opacity-60` on the whole item painted the reason at **2.32:1**; it is slate-500 at **4.75:1** now. The five reasons were reworded from "unavailable while…" into standalone sentences, since they were phrased to be read after the label. |
| Row actions were treated differently on every table | `/items` put two actions behind a kebab while `/barcode_items` showed three inline for **349px**, the widest actions column in the app. `/partners` chose from a five-branch `case` on status, so down one screen the column measured **170, 120, 170, 241, 0, 170px** — different label, different width, sometimes nothing; `/organization`'s users table did the same by role. `/vendors` and `/requests` put a 30px labelled button beside a 28px kebab. And the column header came in **four variants** across 43 tables: 33 hidden and plural, 8 visible, one `<th>Action` with no `scope` and no alignment, one hidden and singular. Nine tables changed, 10 headers normalised. |
| Ten screens could be reached and not left | Every report is listed on the reports hub, **none is in the sidebar, and none linked back** — so the browser's back button was the only way out of all five of them, plus the by-county report and the three trend pages. Also orphaned: `/events`, `/help` and `/users`, the last reached from the account menu's "Co-workers", which is a menu rather than a nav landmark. All now carry a breadcrumb, and `bin/design/wayfinding-audit.js` checks the property. It also found `partners/authorized_family_members/new` rendering its form **outside the page wrapper**, so the form had no gutter, and a `page_header` call with **two `back:` keys** — a duplicate key in a Ruby hash literal is not an error, the last silently wins, so the first had been doing nothing. |
| The reports tables were `.data-table` outside a scroll region | The three itemized reports had the class but none of what makes it work: no `.table-scroll`, so no focusable named region for the arrow keys, no edge shadow, no rail, and nothing to scroll when the table is wider than the card. Their headers were `<th>` with no `scope`, in Title Case, using `text-right` instead of the design system's `.numeric` column class. |
| The custom request units field was a select that opened nothing | select2 in free-tagging mode with `select2-hide-dropdown-value`, so it looked like a select, and clicking it — the first thing anyone does — did nothing. Nothing on screen said the interaction was "type, then comma". Measured: the chip remove target was **9&times;21** against WCAG 2.5.8's 24&times;24, and the chips were select2's `#aaa` border on `#e4e4e4`, used nowhere else in this design system. Rebuilt as `shared/essentials/tag_input` after a preview with three options; the `<select multiple>` still submits, so the wire format is unchanged and the no-JavaScript path is the native control it always was. select2 is still used by five other views and stays. |
| The rich text toolbar icons rendered nothing at all | Reported as "weird squares", and it was mine, from the change one commit earlier that replaced Trix's SVG icons with Bootstrap Icons. Adding the `bi-*` class to the **button** could never work: Trix sets `content: ""` on `.trix-button--icon::before` at `trix-toolbar .trix-button--icon` specificity, which outranks `.bi-type-bold::before`. Fourteen empty boxes. **The spec passed the whole time** — it asserted the class was present and the font family was `bootstrap-icons`, both true, and neither is evidence that a glyph came out. Counting painted pixels per button box found 0 of 14. The glyph is an `<i class="bi-…">` child now, which is how design.md says an icon is written, and the spec reads the computed `content` rather than the class. Third time on this branch a passing spec has hidden an invisible feature. |
| The settings address was four placeholders | Street, City, State and Zipcode carried their names only as a `placeholder` and an `aria-label`, under one "Address" span — and a placeholder disappears the moment anything is typed, which is when you most want to know what the box is for. Every other address in the app labels each field. All four also ran the full 726px width of the card, which is a lot of box for a two-letter state code. Visible labels now, with State and Zip sharing a row through `essentials_field_row`. |
| Seventeen more templates with two page gutters | The same defect as the fourteen already fixed, and the check written for those missed all seventeen: it required both wrappers to be the exact string `px-4 py-6 sm:px-6 lg:px-8`, and these open the header with `pt-6`. Matching the *gutter* (`px-4 sm:px-6 lg:px-8`) rather than the whole class string finds both shapes. Measured 48px under the heading against the design system's 24. `shell-first-audit.rb` checks for it now, so it cannot come back quietly a third time. |
| The organization settings form was banded by a fieldset border | Seven `<fieldset class="border-t">`, each with a `<legend>` — and a legend is rendered *in* its fieldset's top border, so the browser cut a gap for it and the rule started where the legend text ended. Not a pattern this design system has anywhere; it is a fieldset rendering artefact. The sections are `shared/essentials/form_section` bands now, the same band the organization page uses, so a record and the form that edits it look alike. |
| Radio and checkbox options had no vertical spacing | 24px rows with a **0px** gap, in all 14 groups on the settings page and every other group in the app, because `:essentials_collection`'s `item_wrapper_class` set the horizontal gap between control and label and nothing between the rows. Passes WCAG 2.5.8 on size alone and sits exactly on its floor. Now 32px rows with 8px between — GOV.UK pairs 40px with 10px, Material 3 asks 48dp, Apple 44pt. |
| "Deadline day" was cut off mid-word | The number field measured **44px wide against a 92px placeholder**. Both number fields in `_deadline_day_fields` were rendered inside `f.input ... do` blocks, and a block *replaces* the wrapper's input — so they came out as bare browser number fields with none of the design system's classes. The partial was unmigrated besides: a `<label>`, a `<br>`, a radio, a second `<label>` for the same radio and another `<br>` — design.md's own example of what a radio group must not be — and a `label:` on `f.radio_button`, which is not an option that helper has, so it rendered as an HTML attribute and named nothing. `wrapper_html: {min: 0, max: 28}` put the bounds on the wrapping div, where they mean nothing. |
| The rich text toolbar was Trix's, not the design system's | The editor body had been styled to match a text input and the fourteen controls above it had not: `#bbb` borders, a 3px radius against the app's 8, 42x26 buttons with no radius, a `#cbeefa` active state found nowhere else, and **fourteen SVG data-URI icons** — a second icon set in an app that retired Font Awesome to have one. Now 32x32 ghost buttons in a `rounded-lg` slate-300 group, `bg-brand-50` when active, and Bootstrap Icons added as `bi-*` classes by the toolbar controller. |
| Four button labels in Title Case, and one that restated its own page | `page-audit.rb` checks Title Case in **headings only**, so `New Announcement` (twice), `Add New Organization` and `New Donation` sat outside the sentence-case rule for the length of the migration — 4 of the app's 41 distinct button labels. Fixed, and `Add New Organization` became `New organization`, since `New <noun>` is what the other nine create buttons say. Separately, `Invite user to this organization` was the **longest button label in the app** at five words, in the footer of a card titled *Users* on a page whose `<h1>` is the organization's name; it is `Invite user` now, and `/admin/users` said `Invite a new user` for the same action, so both agree. **Not fixed, and named deliberately: 57 Title Case *form field* labels** in the partner profile forms (`Year Founded`, `Storage Space Description`, `Do You Verify The Income Of Your Clients?`). Sentence case covers labels too, but that is a large user-visible copy change across two parallel form trees — `profiles/edit/` and `profiles/step/` — and it is a decision to take on its own rather than as a rider. |
| Nine more bodies inside migrated shells | Found by `shell-first-audit.rb` on its first run, after the narrowings. `partners/profiles/show/_area_served` was a bare `<table>` with a loose `<th>` row and no `<thead>`; `admin/users/_roles` rendered the card component and then wrote its header out underneath it; `profiles/_show` held its fifteen sections apart with **15 `<br>`** and used a `<strong>` as a heading; `account_requests/new` painted a notice `bg-yellow-200` — a raw palette colour no callout uses — with two `<br>` inside it; `admin/organizations/index` and `admin/users/index` positioned a button with `float-right`, the latter wrapping it in an `<h2>` that announced the button as a heading; `served_areas/_served_area_fields` drew a bare `<hr>` between rows; and `partner_users/_users`, `partners/profiles/step/_attached_documents_form`, `served_areas/_served_area_fields` and `shared/essentials/_filter_bar` pasted a button's classes inline instead of asking `essentials_button_classes` for them. The filter bar's copy had already drifted: `font-semibold` and a `shadow-sm` that no other secondary button in the app carries. |
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
| `WIDE_ENOUGH_FOR_A_GRID = 992` in `calendar_controller` | **992 is Bootstrap's `lg`**, and it is the only place in `app/` that number survives. This app is on Tailwind's scale — 640, 768, 1024, 1280 — which is why `responsive-audit` probes 639/641, 767/769 and 1023/1025 and **straddles no boundary near 992**. A view-switching bug that only appeared below 992 was therefore invisible to the audit at every one of its ten widths. Found in August 2026, while fixing that bug. |

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
# there. It proves its own extractor before reporting: Tailwind escapes `.` and `:` in
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

**A filter bar belonging to a tab now renders `in_card: true`**, inside the card under the strip,
with the results frame around the table alone. Five pages moved: `/partners`, `/items`,
`/items/quantity_and_location`, `/items/inventory` and `/kits`. `storage_locations/show` had already
been built this way by hand and now uses the option, so the arrangement has one definition rather
than six copies of a class string.

**Row selection is new rather than migrated.** There was no bulk operation in the app before
August 2026 -- every action was per-record, and `print_unfulfilled` was the one thing that acted on
a set, chosen by filter rather than by hand. `/requests` is the only table with selection, because
it is the only one where a batch endpoint exists; the component is ready for others when one does.

**`title` is not a tooltip in this app any more.** Every icon-only row action carries `aria-label`
plus `data-tooltip`, read by `tooltip_controller`; `title` was removed from all of them, because the
browser's tooltip would draw on top of ours and it shows nothing at all on keyboard focus.
`pw bin/design/tooltip-audit.js` fails if one comes back. The clipped-cell bubble is unchanged and
still a separate controller.

**Row actions were labelled `sm` ghost buttons and are now 28px icons** -- 55 call sites across 30
files, rewritten to `essentials_row_icon_link` / `essentials_row_icon_action`. `<td class="text-right">`
in a table is now `<td class="cell-actions">`, on all 43 tables, which is what the CSS freezes to the
right edge.

A pattern that had no shared component until August 2026: **a field revealed by another answer**.
Six of them existed, each built its own way -- a parallel grid column on the distribution form, a
bare `pl-5` on the partner group form, nothing at all on three others -- and one had a wiring fault
that meant it could never appear. They are all `shared/essentials/conditional_reveal` now; see
"Conditional reveal" in design.md, and `pw bin/design/disclosure-audit.js` to check them.

One known inert leftover, so you do not have to work it out again: `class: 'form-horizontal'`
survives on 12 forms. Bootstrap 5 had already dropped it, so it was doing nothing before this
work either. It is left alone because removing it means editing option hashes rather than
substituting a token, and that kind of edit has already broken markup once on this branch.
