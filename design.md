# Human Essentials Design System

> **Living record** of how the Human Essentials UI is built and why — the **single source
> of truth** for UI work. Read it before building a screen, and keep it current as patterns
> change. Approved by [ADR 0010](docs/architecture/decisions/0010-adopt-a-documented-design-system.md).
> Decisions taken where this document was silent are logged in
> [`docs/design-decisions.md`](docs/design-decisions.md).

Human Essentials is used by 200+ non-profit essentials banks, most often by a volunteer on a
laptop in a warehouse. The UI should be **plain, dense and predictable** — not fashionable.
Consistency beats novelty here: a bank user who has learned one index page has learned all of
them.

## Status & approach

The app ships **one** design system: **Bootstrap 5.2 + AdminLTE 3.2**, compiled by Sprockets,
with ImportMap for JavaScript. There is no Tailwind, no CSS bundler, and no component library.

That decision was made in [ADR 0009](docs/architecture/decisions/0009-stick-with-adminlte-for-app-design.md)
(Oct 2022) after a Tailwind migration was started and abandoned, and it stands. **Do not
introduce a second CSS framework.** When AdminLTE has a widget for what you need, copy it from
the [AdminLTE demo](https://adminlte.io/) rather than inventing one.

- Stylesheet entry point: `app/assets/stylesheets/application.scss` (Sass → Sprockets).
- JavaScript entry point: `app/javascript/application.js`, pinned in `config/importmap.rb`.
- No asset build step in development. `bin/start` runs the Rails server + Delayed Job worker.
- Stimulus controllers live in `app/javascript/controllers/`; jQuery is still global
  (`window.$`) because AdminLTE, select2, bootstrap-select and filterrific all need it.

### The two-dialect problem (read this first)

`application.scss` imports, in this order:

```scss
@import 'bootstrap';   // bootstrap gem 5.2.3
@import 'AdminLTE';    // AdminLTE 3.2.0 — which embeds a full copy of Bootstrap 4.6.1
```

The vendored `AdminLTE.css` contains Bootstrap **4.6.1** and is imported **second**, so where
the two frameworks define the same class, **Bootstrap 4 wins**. Meanwhile the JavaScript is
Bootstrap **5.2.3** (`bootstrap.min.js` from the gem, precompiled in
`config/initializers/assets.rb`). The app is therefore BS4 in CSS and BS5 in JS, on purpose,
and you have to know which half you are writing.

This is not a guess — compile the two imports and look. In the 1.18MB result, `.card` is
defined by Bootstrap 5 (the `--bs-card-*` custom-property version) at ~85KB in, redefined by
AdminLTE's embedded Bootstrap 4 at ~309KB, and redefined once more by AdminLTE's own rules at
~786KB. Last one wins. Both utility sets survive intact, one after the other: `.visually-hidden`,
`.float-end` and `.ms-auto` (BS5) all land before `.float-right`, `.sr-only` and `.ml-auto`
(BS4).

**CSS class names: write Bootstrap 4.** `ml-auto`, `mr-2`, `float-right`, `text-left`,
`font-weight-bold`, `form-group`, `sr-only`, `btn-block`. This is not a preference, it is what
the codebase is: 20 `mr-*` vs 0 `me-*`, 27 `float-right` vs 0 `float-end`, 116 `text-right` vs
0 `text-end`, 48 `font-weight-bold` vs 5 `fw-bold`. BS5-only utilities do resolve (the BS5 gem
is loaded too), but they are a minority dialect that reads as drift. Never mix both in one
block.

**JS behaviour attributes: write Bootstrap 5.** `data-bs-toggle`, `data-bs-dismiss`,
`data-bs-target`. The app has 37 `data-bs-toggle` and 34 `data-bs-dismiss` and **zero**
BS4-style `data-toggle`/`data-dismiss`. A BS4 attribute renders fine and simply never fires.

**AdminLTE's own widgets use `data-widget`**, not Bootstrap: `pushmenu` (sidebar toggle),
`treeview` (sidebar submenus), `collapse`/`remove` (card header tools), `expandable-table`.
These are jQuery plugins from `app/javascript/adminlte.js`.

**Where a class exists in both dialects, wear both.** `partners_helper.rb` renders
`badge badge-pill badge-info bg-info` and 10 views render `class="close btn-close"` — BS4 name
plus BS5 name — because either stylesheet may be the one that matches. That is ugly and it is
correct; keep doing it for `badge`, `close`, and any other overlapping component until the
frameworks are untangled.

### Dead classes (verified undefined on the asset path)

These are Bootstrap **3** / AdminLTE **2** leftovers. They are not defined in Bootstrap 4,
Bootstrap 5, or AdminLTE 3.2 — checked against every stylesheet Sprockets loads. They render
as nothing. **Do not add them; delete them from files you touch.**

| Dead class | Occurrences in `app/views` | Use instead |
|---|---|---|
| `pull-right` | 28 | `float-right` |
| `hidden-xs` | 6 | `d-none d-sm-block` |
| `box`, `box-body`, `box-header`, `box-title`, `box-primary`, `with-border`, `no-padding` | 53 across 26 files | the AdminLTE 3 `card` family |
| `label`, `label-*` (BS3 badge) | 1 (`partners_helper.rb` error fallback) | `badge badge-*` |
| Leftover **Tailwind** classes — `text-2xl`, `flex`, `font-bold`, `w-1/2`, `bg-yellow-400`, `rounded-2xl`, `space-y-5`, … | 81 across 28 files | the Bootstrap/AdminLTE equivalent |

The Tailwind row is the unfinished half of ADR 0009's stated consequence (*"Any work that used
TailwindCSS would need to be updated to use Bootstrap"*). Be careful when clearing them:
**`text-sm`, `text-lg`, `text-xl` and `text-bold` are real AdminLTE utilities and `gap-*` is a
real Bootstrap 5 utility** — they look like Tailwind but they work. Only the 81 listed above are
undefined.

Two of these are load-bearing bugs rather than harmless noise:

- **`UiHelper#submit_button` defaults to `align: "pull-right"`.** Every default Save button in
  the app is therefore *not* right-aligned, and has never been. Pass `align: "float-right"` for
  the intended behaviour, and fix the default when you are next in `ui_helper.rb`.
- **`shared/_card` emits `box-body table-responsive no-padding`** for `type: :table`, of which
  only `table-responsive` applies. A table rendered through that partial does not get the
  padding reset the class name promises; use `card-body table-responsive p-0` when you build
  the card inline.

## Foundations

### Typography

**Source Sans Pro** (Google Fonts CDN, `<link>`ed in each layout, weights 300/400/600/700 plus
italics). Both AdminLTE's `--font-family-sans-serif` and `$diaper-font-family-sans-serif-default`
name it, backed by a system fallback stack.

Use the framework scale. Do not set `font-size` in a view.

| Role | Markup | Size |
|---|---|---|
| Page title | `<h1>` inside `.content-header` | 1.8rem (1.5rem below `sm`) |
| Page title qualifier | `<small>` **inside** the `h1` | inherited, muted |
| Card title | `<h3 class="card-title">` | 1.1rem |
| Body | default | 1rem / 1.5 |
| Meta, table chrome | `<small>`, `.text-muted` | 0.875rem |

There are 148 inline `style="…"` attributes in `app/views`. That is accumulated debt, not a
pattern to follow — put new rules in the relevant SCSS file.

### Title Case (house style)

Human Essentials writes UI copy in **Title Case**: page titles, nav items, buttons, table
headers, form labels. "New Distribution", "Pick Ups & Deliveries", "Storage Locations", "Date of
Distribution", "Clear Filters".

Measured across every `<th>` in the app: **158 Title Case vs 26 sentence case** — Title Case is
the convention by a wide margin, and the sentence-case minority is drift, not a second style.

This is a deliberate difference from the sibling Ruby for Good project
[CASA](https://github.com/rubyforgood/casa/blob/main/design.md), which uses sentence case. If
you are porting a pattern from CASA, re-case the copy.

Two consistency rules that are cheap to keep:

- **Match the nav label.** A page's `h1` should read the same as the sidebar item that leads to
  it ("Storage Locations", not "Manage Storage Locations").
- **Don't shout.** No `text-uppercase` on labels; use size, weight and colour for hierarchy.

### Color

Three overlapping palettes live in this repo. Know which one you are in.

1. **Bootstrap/AdminLTE contextual names** — `primary` `#007bff`, `secondary` `#6c757d`,
   `success` `#28a745`, `info` `#17a2b8`, `warning` `#ffc107`, `danger` `#dc3545`, `light`,
   `dark`. These drive every `btn-*`, `bg-gradient-*`, `badge-*`, `card-*`, `text-*`.
   **This is the palette for components — reach for it first.**
2. **`app/assets/stylesheets/_colors.scss`** — a small semantic set (`$action`, `$error`,
   `$success`, `$caution`, `$blue`, `$light-grey`, …) used by the hand-written SCSS files.
3. **`app/assets/stylesheets/base/_variables.scss`** — the `$diaper-*` token file: ~90 raw
   colour values named by hue and HSL lightness (`$diaper-color-blue-49`), a few semantic
   aliases (`$diaper-text-color-interactive-default`,
   `$diaper-notifcation-color-error-default` — the typo is load-bearing, it is the real
   variable name), and size tokens (`$diaper-navbar-height: 57`, `$diaper-footer-height: 75`).

**Rule: no new raw hex values in views or in `custom.scss`.** If a component needs a colour,
use a contextual name; if it genuinely needs a new one, add a named variable to
`base/_variables.scss` and reference it.

**What the contextual colours mean here.** This mapping comes from `UiHelper` and holds across
essentially every screen, so it is the app's actual semantic layer:

| Colour | Means | Canonical uses |
|---|---|---|
| `success` (green) | creates, saves, moves forward | New, Save, Submit, Reactivate |
| `primary` (blue) | the ordinary action | Edit, Filter |
| `info` (cyan) | read-only / retrieval | View, Download, Refresh |
| `warning` (amber) | needs attention, reversible admin action | Invite, Restore |
| `danger` (red) | destructive or blocking | Delete, Deactivate |
| `outline-primary` | the neutral way out | Cancel, Clear Filters |
| `secondary` (grey) | inert | Deactivated status |

**Never signal state by colour alone.** `status_label` pairs every colour with an icon *and* a
word; keep that pairing.

### Spacing, radius, elevation

- Bootstrap 4 spacing scale: `m-*` / `p-*` with 0–5 → 0 / .25 / .5 / 1 / 1.5 / 3 rem.
- Page background `#f4f6f9`; surfaces are white `.card` at `border-radius .25rem`; the sidebar
  is `elevation-4`.
- Fixed chrome: sidebar 250px, navbar 3.5rem, footer 75px. `.content-wrapper` is offset for
  both; do not position against the viewport directly.
- Page rhythm: `.content-header` (padding `15px .5rem`) then one or more
  `.content > .container-fluid > .row > .col-*` blocks. Cards carry their own
  `margin-bottom: 7.5px` — do not add ad-hoc margins between stacked cards.

### Iconography

**Font Awesome 5.11.2 plus the v4 shims**, both from jsDelivr, `<link>`ed in every layout.

Render icons through the `fa_icon` helper (`app/helpers/icon_helper.rb`), never a bare `<i>` in
new code:

```erb
<%= fa_icon "trash", text: "Delete" %>                        <%# <i class="fa fa-trash"></i> Delete %>
<%= fa_icon "chevron-right", text: "Next", right: true %>     <%# icon after the text %>
```

**The icon names in this app are Font Awesome *4* names**, and they only resolve because
`v4-shims.css` is loaded: `pencil-square-o`, `circle-o` (38 uses), `floppy-o`, `dot-circle-o`,
`money`, `gratipay`, `file-text`, `calendar-o`, `pie-chart`, `repeat`, `sign-out`. Keep using
FA4 names so the icon set stays coherent. If you need an FA5-only glyph, write the explicit FA5
form (`fas fa-…`) and check it actually renders — the shim maps old names forward, not new names
backward.

Icons in this app are **decorative**: every icon `fa_icon` produces sits beside its own text
label. If you ship an icon-only control, it needs an `aria-label`, and the icon itself should be
`aria-hidden="true"`.

### Accessibility

The bar is **WCAG 2.1 AA**. The app is not there yet, so there are two rules:

1. **Do not add new violations.** Real `<label>`s, one `<h1>` per page, `alt` on meaningful
   images, `aria-label` on any icon-only control, keyboard-operable everything.
2. **Fix what you touch.** Landing in a file is the cheapest chance to close a gap in it.

These gaps are app-wide, already verified, and do not need rediscovering — fix them where you
land, or take one on deliberately:

| Gap | Where | Why it matters |
|---|---|---|
| No `lang` attribute on `<html>` | all 4 app layouts | WCAG 3.1.1 — screen readers guess the language |
| `maximum-scale=1, user-scalable=no` in the viewport meta | all 4 app layouts | WCAG 1.4.4 — blocks pinch-zoom on a phone |
| No skip link | all layouts | WCAG 2.4.1 — keyboard users tab the whole sidebar on every page |
| Zero `<caption>` across 142 `<table>`s | app-wide | WCAG 1.3.1 — a table announces nothing about itself |
| 4 `<main>` landmarks across 422 views | app-wide | `.content-wrapper` is a bare `div` |
| 8 `<label for>`s pointing at an input that is never rendered | see **Forms** | WCAG 1.3.1 / 4.1.2 — the label names nothing |

There is currently **no automated accessibility test** — no axe, no `spec/system/accessibility/`.
Adding one is the highest-leverage accessibility task in the repo (see **Backlog**), because
everything above is the kind of defect a single axe sweep would have caught years ago.

## Components

### Buttons — always through `UiHelper`

`app/helpers/ui_helper.rb` is the button system, and its own comment states the rule: *"Anytime
a button or pseudo-button are displayed, it should always be through one of these methods."*
Follow it. A hand-written `<a class="btn btn-…">` skips the confirm dialog, the
`data-disable-with` double-submit guard, and the `link_to` vs `button_to` decision that the
HTTP verb requires.

| Helper | Renders | Default label |
|---|---|---|
| `new_button_to(path, text:)` | success · md · `fa-plus` | New |
| `edit_button_to(path)` | primary · xs · `fa-pencil-square-o` | Edit |
| `view_button_to(path)` | info · xs · `fa-search` | View |
| `delete_button_to(path)` | danger · xs · `fa-trash` · `DELETE` + confirm | Delete |
| `deactivate_button_to` / `reactivate_button_to` | danger / success · xs · `PUT` + confirm | Deactivate / Reactivate |
| `restore_button_to` / `update_button_to` | warning / success · xs · `PATCH` | Restore |
| `invite_button_to` | warning · xs · `fa-envelope` · `POST` + confirm | Invite |
| `submit_button(options)` | success `<button type="submit">` · `fa-floppy-o` | Save |
| `submit_button_to(path)` | success · lg · `fa-check-circle` · `POST` | Submit |
| `cancel_button_to(path)` | outline-primary · md · `fa-ban` | Cancel |
| `clear_filter_button` | a cancel button pointed at `request.path` | Clear Filters |
| `filter_button` | primary `<button type="submit">` · `fa-filter` | Filter |
| `download_button_to` | info · md · `fa-download` | Download |
| `print_button_to` | outline-dark · xs · `fa-print` | Print |
| `refresh_button_to` | info · md · `fa-sync` | Refresh |
| `modal_button_to(target_id)` | outline-primary + `data-bs-toggle="modal"` | — |
| `js_button` | outline-primary, for JS hooks | — |
| `add_element_button` / `remove_element_button` | primary / danger, drive the `form-input` Stimulus controller | — |

**Sizes carry meaning**: `xs` for a row action inside a table, `md` for a page or section
action, `lg` only for the one terminal Submit on a page. A `lg` button in a table row reads as
a mistake.

Every helper sets `data-disable-with` ("Please wait…", or "Saving" for `submit_button`). That is
the app's only double-submit guard — do not bypass it. Any destructive or state-changing action
gets a `confirm:` (the helpers default to "Are you sure?"; `ApplicationHelper` has
`confirm_delete_msg` / `confirm_deactivate_msg` / `confirm_reactivate_msg` / `confirm_restore_msg`
for a resource-specific message, which is better).

Destructive confirms use Rails UJS `data: {confirm:}` (native `window.confirm`), because that is
what Capybara's `accept_confirm` / `dismiss_confirm` can drive in system specs. Do not replace
one with a custom dialog without moving the specs too.

### Status labels

`status_label(text, icon, type)` renders a **non-interactive** pill built from button classes
(`cursor-default btn btn-xs btn-#{type}`). `partner_status_label` maps the six partner states
onto it: uninvited (plain + `exclamation-circle`), invited (info), awaiting_review (warning),
approved (success), recertification_required (danger), deactivated (secondary).

Use it for state. **Never make a status label a link** — if it navigates, it is a button, and it
should look like one.

### Cards

The AdminLTE `card` is the only surface in the app. Two ways to build one:

**Inline** — the common case (159 views):

```erb
<div class="card card-primary">
  <div class="card-header"><h3 class="card-title">Distribution Filters</h3></div>
  <div class="card-body">…</div>
  <div class="card-footer">…</div>
</div>
```

**`shared/_card`** (6 views) — takes `title:`, `subtitle:`, `gradient:`, `type:`
(`:box` / `:plain` / `:table`), `footer:`, `header_div:`, and adds AdminLTE's collapse/remove
tool button in the header. Use it when you want that header treatment.

A card that holds a table gets `card-body table-responsive p-0` so the table meets the card
edges.

### Page header

Every page opens with the same block: an `<h1>` on the left, a breadcrumb on the right (132 and
129 views respectively).

```erb
<section class="content-header">
  <div class="container-fluid">
    <div class="row mb-2">
      <div class="col-sm-6">
        <% content_for :title, "Distributions - #{current_organization.name}" %>
        <h1>Distributions <small>for <%= current_organization.name %></small></h1>
      </div>
      <div class="col-sm-6">
        <ol class="breadcrumb float-sm-right">
          <li class="breadcrumb-item"><%= link_to fa_icon("dashboard", text: "Home"), dashboard_path %></li>
          <li class="breadcrumb-item active">Distributions</li>
        </ol>
      </div>
    </div>
  </div>
</section>
```

Rules:

- **One `<h1>` per page.** The qualifier ("for Pawnee Diaper Bank") goes in a `<small>` *inside*
  the `h1`, never as a second heading — a second heading breaks heading order for screen readers.
- **Always set `content_for :title`.** The `<title>` otherwise falls back to
  `default_title_content`, which is just the organization name, so every tab reads the same.
- The breadcrumb's last item is the current page, is not a link, and carries `active`.
- Sub-pages (`new`, `edit`, `show`) get a breadcrumb back to their index. That breadcrumb is the
  only "back" affordance the app has — a page without one is a dead end.

### Filter bar

An index page's filters are a `card card-primary` titled "… Filters":

- `card-body` → a `row` of `form-group col-lg-2 col-md-2 col-sm-6 col-xs-12` cells, one per
  filter.
- `card-footer` → `filter_button` and `clear_filter_button` on the left; export and New buttons
  in a `float-right` span.

Build the controls with `FilterHelper` (`filter_select`, `filter_text`, `filter_checkbox`), not
by hand. It generates a UUID-suffixed id and a matching `label_tag`, so the label is correctly
associated — which is exactly the thing hand-rolled `<select>`s get wrong.

Date filtering is `shared/_date_range_picker`: a Litepicker instance (configured in
`application.js` with named ranges — Default, All Time, Today, Last 7/30 Days, This/Last Month,
Last 12 Months, Prior Year, This Year) that submits `filters[date_range]` plus a
`filters[date_range_label]` hidden field. The controller side is the `Filterable` concern's
`class_filter`.

Filters submit with `method: :get` so the filtered view is a real, shareable, bookmarkable URL.
Keep it that way.

### Tables

- `<table class="table table-hover">` inside `card-body table-responsive p-0`.
- **Column alignment is semantic**: `class="numeric"` or `"quantity"` right-aligns (from
  `custom.scss`), `class="date"` centres (from `application.scss`). Use them instead of
  `text-right`.
- Extract a row into `_thing_row.html.erb` and render it as a collection once it has more than a
  couple of cells; that is the established pattern (`_donation_row`, `_purchase_row`,
  `_request_row`, `_partner_row`).
- Row actions are `xs` `UiHelper` buttons in a final cell.
- **Pagination is Kaminari**: `<%= paginate @paginated_things %>` in the `card-footer`.
  `config/initializers/kaminari_config.rb` sets **50 per page in production but 5 in development
  and staging** — if a pagination change looks broken locally, check that first.
- A totals row goes in `<tfoot>`, and should say what it totals ("(This page)" vs the whole
  result set) — `purchases/index` is the reference.
- Expandable rows use AdminLTE's `data-widget="expandable-table"`; `expandable_table.scss`
  supplies the +/− affordance, which AdminLTE itself does not.
- **Give new tables a `<caption>`** (`class="sr-only"` is fine). There are currently zero in the
  app; do not extend the streak.

### Forms

`simple_form` with the Bootstrap wrappers in `config/initializers/simple_form_bootstrap.rb`.
57 views use `simple_form_for`; 10 still use bare `form_for` and 5 use `form_with`. **New
model-backed forms use `simple_form_for`** — that is what gets you the wrappers, the error
markup and the required marker for free.

Non-model forms (filter bars, search) correctly use `form_tag` / `form_with` with `method: :get`;
17 views do, and that is not debt.

Note there are two initializers, and Rails loads them alphabetically: `simple_form.rb` first,
then `simple_form_bootstrap.rb`, which wins. That is why the required marker renders **after**
the label (`label_text = ->(label, required, _) { "#{label} #{required}" }`), and why
`boolean_style` is `:inline` in the app even though `simple_form.rb` says `:nested`.

The house pattern is an input group with a leading icon:

```erb
<%= f.input :business_name, label: "Business Name", wrapper: :input_group do %>
  <span class="input-group-text"><i class="fa fa-suitcase"></i></span>
  <%= f.input_field :business_name, class: "form-control" %>
<% end %>
```

**The attribute passed to `f.input` must be the same one passed to `f.input_field`.** When it
isn't, simple_form emits `<label for="item_name">` above a field whose id is
`item_value_in_dollars`: the label names nothing, clicking it focuses nothing, and the required
marker is computed from the wrong attribute. There are **8** of these today — `items/_form` (×5),
`kits/_form`, `organizations/edit`, `admin/organizations/edit`. Don't add a ninth, and fix the
ones you pass.

**Required fields.** simple_form derives required-ness from the model, and the details matter:

- An **unconditional** `validates :x, presence: true` produces the marker automatically
  (`<abbr title="required">*</abbr>`, styled by `_form_abbr.scss`). Let it. Don't type a `*`.
- A **conditional** validator (`presence: {...}, if: ->{...}`) is deliberately ignored by
  simple_form (`conditional_validators?` in `simple_form/helpers/validators.rb`), so no marker
  appears. This is the "phone **or** e-mail" case in `product_drive_participants/_form`.
- Passing `required: true` is **not** a safe substitute for a conditional requirement. With an
  explicit `required:` option simple_form sets the HTML5 `required` attribute *regardless* of
  `config.browser_validations = false`, and the browser will then block a submission that the
  model considers perfectly valid.
- So: for a conditional requirement, say it in the label —
  `label: "Phone* (phone number or e-mail required)"`. That is the one sanctioned place a
  literal `*` belongs in a label string. Keep the wording consistent with the existing four.
- Because every ActiveRecord model responds to `validators_on`, `config.required_by_default` is
  effectively dead for AR-backed forms; only presence validators drive the marker.

`config.browser_validations = false` is intentional: server-side validation is the single source
of truth, and error messages render through the simple_form error components
(`is-invalid` + `invalid-feedback`) rather than a browser tooltip.

### Modals

Bootstrap 5 modals (`data-bs-toggle="modal"`, `data-bs-dismiss="modal"`) opened via
`modal_button_to`. Every layout ships an empty `<div class="modal fade" id="modal_new">` at the
bottom of `<body>` that AJAX responses (`*_modal.js.erb`, `create.js.erb`) render into — that is
how "New Donation Site" / "New Vendor" / "New Product Drive" work from an index page.

`shared/_csv_import_modal` is the shared import dialog: a two-column explainer (download the
template, then upload) taking `import_type`, `csv_template_url` and `csv_import_url`. Use it for
every CSV import rather than writing a new one.

Close buttons carry both dialects: `class="close btn-close"`.

### Flash messages and toasts

Two channels, and they are not interchangeable:

- **Flash** — `shared/_flash` renders each key inside a `turbo_frame_tag "flash"` with
  `role="alert"`, classed by `ApplicationHelper#flash_class`: `notice` → `alert-info`,
  `success` → `alert-success`, `error` → `alert-danger`, `alert` → `alert-warning`. Use it for
  the outcome of a request that navigated. Note `flash_class` returns `nil` for any other key,
  which renders an unstyled bare div — stick to the four keys.
- **Toastr** — `window.toastr`, configured in `application.js` with a **1400ms** timeout. Use it
  only for transient in-page feedback. At 1400ms it is too fast to read a sentence, so keep toast
  copy to a few words, and never put an error or anything actionable in one.

### Charts

Highcharts, via `shared/_highcharts` and the `highchart` Stimulus controller:

```erb
<%= render "shared/highcharts", config: chart_config %>
```

The partial ships Select All / Deselect All series buttons. Chart config is built server-side
(see `app/helpers/historical_trends_helper.rb` and `app/services/reports/`). A chart is never
the only representation of a number — pair it with the table or figure it summarises, because a
canvas is invisible to a screen reader.

### Empty states and onboarding

- **Cold start (whole app)** — `dashboard/_getting_started_prompt` renders a checklist of setup
  links while `@org_is_set_up` is false, and disappears once the org has storage locations,
  items and a partner. New setup requirements belong on that list.
- **Cold start (one page)** — an index with no records shows a short line of copy plus the same
  New button as the toolbar. Never render bare empty table chrome.
- **No results** — a filtered index that matches nothing says so, and leaves the filter bar and
  `clear_filter_button` in place so the user can undo it.

### Progress stepper

`progress_stepper.scss` plus `ApplicationHelper#step_container_helper(index, active_index)`
styles a 4-step flow: done steps go green (`$diaper-color-green-33`), the active step is outlined
blue (`$diaper-color-blue-49`), and future steps are muted. Use it for any multi-step wizard so
they all look alike.

## App shell

Four shells, all built from the same AdminLTE chrome: fixed 250px dark sidebar
(`sidebar-dark-primary elevation-4`), white 3.5rem top navbar, `content-wrapper` on `#f4f6f9`,
and a footer. The `<body>` carries `hold-transition sidebar-mini layout-fixed`, plus an `id` of
the controller name and a `class` of the action name — those hooks are used by specs and by
page-specific CSS, so keep them.

### Bank shell — `layouts/application.html.erb`

The main app. Sidebar groups, in this order (frequency of use, not alphabetical):

**Dashboard · Donations · Purchases · Requests · Distributions · Pick Ups & Deliveries ·
Partner Agencies · Inventory · Community · Reports · My Organization**

Groups with children are AdminLTE `has-treeview` accordions whose children are marked with
`fa-circle-o` bullets. `ApplicationHelper#active_class` and `#menu_open?` take an array of
controller names and light up / expand the matching item — pass **every** controller that
belongs to the group, or the menu collapses out from under the user mid-task.

Nav items are gated by role (`current_user.has_cached_role?(Role::ORG_ADMIN, current_organization)`
for Inventory Audit, organization settings, and similar). Gate the nav item *and* the controller;
a hidden link is not authorization.

The top navbar carries a yellow help link (User Guide for org users, "Need Help?" otherwise),
an upcoming-pick-ups dropdown, a notifications dropdown counting pending requests and partners
awaiting review, and the account menu.

### Partner shell — `layouts/partners/application.html.erb`

The partner-facing portal at `/partners/*`. Same chrome, much shorter nav: **Dashboard ·
My Profile · Edit My Profile · Essentials Requests · Distributions · Families · Children.**

Partners are a different audience with different vocabulary — they see "Essentials Requests",
not "Requests"; they never see inventory, storage locations or other partners' data. Keep the
two navs conceptually separate even though the CSS is shared.

Its flash rendering is its own copy (with a dismiss button and `sanitize(value, tags: %w(ul li))`
so multi-error messages can render as a list) rather than `shared/_flash`. If you change flash
markup, change both.

### Admin shell

Super-admin pages under `/admin/*` swap in `_lte_admin_navbar` / `_lte_admin_sidebar` from the
same `layouts/application.html.erb`, selected by `ApplicationHelper#admin_namespace?` (which
tests `request.path_info.include?('admin')` — a string match, so any future path containing the
word "admin" will pick up the admin chrome).

### Auth pages — `layouts/devise.html.erb` → `_devise_shared`

Sign-in / sign-up / password reset render through a shared partial that takes `title:`,
`body_class:` and `masthead_img_src:`. The `body_class` picks the background gradient from
`custom.scss`: `login-page--user` (purple), `login-page--consolidated` (blue), `login-page--partner`
(grey). This is the one place in the app with decorative colour; leave it be.

## Key patterns

### Turbo is off by default, and opted into per action

`application.js` sets `Turbo.session.drive = false`. A controller action opts in with
`before_action :enable_turbo!`, which sets `@turbo` and makes the layout emit
`data-turbo="true"` and drop the `turbo-visit-control: reload` / `turbo-cache-control: no-cache`
meta tags.

Today exactly **two** actions opt in: `distributions#new` and `distributions#show`. If you want
Turbo on a page, opt that action in and test it — do not flip the global. The `turbo` Stimulus
controller scrolls to the top on a failed `turbo:submit-end` so the error summary is visible.

Independently of Drive, `shared/_flash` is wrapped in a `turbo_frame_tag "flash"`, so flash
messages can be replaced by a frame response.

### Stimulus first; jQuery where the plugin requires it

New behaviour goes in a Stimulus controller in `app/javascript/controllers/`, wired with
`data-controller` / `data-action` / `data-*-target`. There are ~20 of them and they are the
pattern to copy.

jQuery stays global because AdminLTE, select2, bootstrap-select and filterrific all need it. A
Stimulus controller may use jQuery to drive one of those plugins (`select2_controller.js` does),
but new code that doesn't touch a jQuery plugin should be plain DOM.

Notable controllers: `form-input` (add/remove repeatable rows, driven by
`add_element_button` / `remove_element_button`), `date-range` (Litepicker validation),
`highchart`, `select2`, `duplicate-items`, `confirmation`, `password-visibility`, `file-input`.

### Enhanced selects

- **select2** via the `select2` Stimulus controller for searchable and multi-selects. Its
  connect() carries three workarounds — autofocus on open, preventing a reopen loop on
  unselect, and optional dropdown hiding — that were each fixed once. Do not initialise select2
  by hand and rediscover them.
- **bootstrap-select** (`selectpicker`) for the simpler styled selects.
- Both are jQuery plugins that replace the native control, which means **the default
  `<label for>` no longer points at the visible widget**. Any enhanced select needs an explicit
  accessible name.

### CSV export

Every index that can export does it the same way: a `download_button_to` pointing at the same
path with `format: :csv` and the current `filter_params` merged in, so the export matches what
is on screen. Keep that coupling — an export that ignores the filters is a support ticket.

### Multi-tenancy is visible in the UI

Nearly everything is scoped to `current_organization`. Page titles say which organization
("Distributions **for** Pawnee Diaper Bank"), and `content_for :title` includes the org name.
Never render a collection that isn't organization-scoped; the scoping is a tenant boundary, not
a filter.

### Print and PDF

Distribution manifests, donation receipts and picklists are generated with Prawn server-side
(`app/pdfs/distribution_pdf.rb`, `donation_pdf.rb`, `picklists_pdf.rb`), not by styling HTML for
print. They set their own type (OpenSans at 10pt) and letterhead — the organization's uploaded
logo, falling back to `Organization::DIAPER_APP_LOGO` — so a PDF is a separate design surface
from the web UI and does not inherit anything from this document's tokens. Don't add
`@media print` rules to work around a missing PDF.

## Design decisions (rationale)

The *why*, so these are not re-litigated.

- **Bootstrap + AdminLTE, not Tailwind.** Decided in ADR 0009 after a Tailwind migration was
  started and abandoned: the maintenance win did not justify migrating a volunteer-built app of
  400+ views. The corollary is the important half — **use AdminLTE properly.** Copy its demo
  markup for widgets instead of writing bespoke CSS.
- **One design system at a time.** The current BS4/BS5 split is already one framework overlap
  too many; a third would make every class name a coin flip.
- **Buttons only through `UiHelper`.** Colour, size, icon, HTTP verb, confirm dialog and
  double-submit guard are all decisions that should be made once, centrally. Consistency here is
  what makes 400 pages feel like one app.
- **Colour carries meaning, and never carries it alone.** The green/blue/cyan/amber/red mapping
  is a real semantic layer; pair it with an icon and a word so it survives colour-blindness and
  greyscale printing.
- **Filters are GET, results are URLs.** Bank staff share and bookmark filtered views, and
  support asks them to. Never move a filter into session state.
- **Server-rendered, progressively enhanced.** Validation, filtering, sorting and pagination all
  happen on the server; JavaScript decorates. This keeps the app usable on the hardware and
  connections our users actually have.
- **Turbo stays opt-in.** It was introduced onto an app full of jQuery plugins that assume a
  full page load; enabling it globally breaks them silently. Per-action opt-in makes the blast
  radius one page.
- **Title Case**, because that is what the app already is and inconsistent casing looks like a
  bug to a non-technical user.
- **Accessibility is part of "done"** for new work, even though the existing baseline is behind.
  The gaps listed above are known debt, not permission.

## Building or changing a page (playbook)

1. **Read this document and the page's existing specs** before touching markup — know what
   behaviour is pinned. Prefer request specs; system specs are slow and flaky (see
   `docs/code_standards.md`).
2. **Start from the page skeleton**: `content_for :title` → `section.content-header` with one
   `h1` and a breadcrumb → `section.content > .container-fluid > .row > .col-*` → cards.
3. **Use the components above** — `UiHelper` buttons, `FilterHelper` filters, the card and table
   patterns, `simple_form` with matching `f.input` / `f.input_field` attributes. Don't invent a
   new one; if you must, add it here in the same PR.
4. **Write Bootstrap 4 class names and `data-bs-*` JS attributes.** Delete any `pull-right`,
   `hidden-xs`, `box*` or leftover Tailwind class in the file you are editing.
5. **Design the empty state** and the no-results state.
6. **Check accessibility on what you touched**: label/field association, one `h1`, `alt` text,
   `aria-label` on icon-only controls, a `<caption>` on any new table, keyboard reachability.
7. **Verify**: `bundle exec rspec` for the affected specs, `bundle exec rubocop`,
   `bundle exec erb_lint --lint-all`, and load the page at a narrow width — the sidebar collapses
   at 992px (`data-auto-collapse-size="992"`).
8. **Keep specs green semantically.** If a spec is coupled to a presentational class you are
   changing, move it to a stable hook (an `id` or `data-*`) rather than weakening the assertion.

## Backlog

Known debt, roughly in order of leverage. Each is self-contained and a good first contribution.

- [ ] **Add an automated accessibility check** (axe via Capybara, a small `spec/system/accessibility/`
  sweep over the main pages of each role). Everything below would have been caught by it.
- [ ] Add `lang="en"` to all four app layouts.
- [ ] Remove `maximum-scale=1, user-scalable=no` from the viewport meta so mobile zoom works.
- [ ] Add a skip link and wrap `.content-wrapper` content in `<main>`.
- [ ] Add `<caption class="sr-only">` to tables as they are touched (142 tables, 0 captions).
- [ ] Fix the 8 `f.input` / `f.input_field` attribute mismatches so those labels name their fields.
- [ ] Fix `UiHelper#submit_button`'s `align: "pull-right"` default, then remove the remaining 28
  `pull-right` and 6 `hidden-xs` usages.
- [ ] Replace the 53 AdminLTE 2 `box*` class usages (26 files) with the AdminLTE 3 `card` family,
  including inside `shared/_card`.
- [ ] Remove the **81 leftover Tailwind class usages across 28 files** (`text-2xl`, `flex`,
  `font-bold`, `w-1/2`, `bg-yellow-400`, `rounded-2xl`, `space-y-5`, …). These are undefined and
  render as nothing — they are the unfinished half of ADR 0009's stated consequence.
  Careful: `text-sm`, `text-lg`, `text-xl`, `text-bold` and `gap-*` **are** real (AdminLTE and
  Bootstrap 5 respectively) and should stay.
- [ ] Migrate the 10 remaining bare `form_for` model views to `simple_form_for`.
- [ ] Pull the 148 inline `style="…"` attributes into SCSS.
- [ ] Self-host Font Awesome, select2, toastr and the Source Sans Pro font instead of loading
  them from three CDNs on every page.
- [ ] Converge the duplicated flash rendering between the bank and partner layouts.
- [ ] Delete `app/views/shared/_logo_line.html.erb` — it is a 0-byte file rendered by nothing.

## Workflow

- This document is the design system. **If you introduce a pattern, add it here in the same PR;
  if you find one that is wrong, fix it here too.** A pattern that only exists in one view is
  not a pattern.
- Design changes that alter a shared component (`UiHelper`, `shared/_card`, a layout) affect
  every page — say so in the PR description and name the pages you checked.
- If a change would need a second CSS framework, a new front-end dependency, or contradicts
  ADR 0009 / ADR 0010, raise it as an issue and get agreement first. `docs/code_standards.md`
  is explicit that new dependencies need a strong justification.
