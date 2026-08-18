# Human Essentials Design System

This is the design system for Human Essentials. It is normative:
[ADR 0010](docs/architecture/decisions/0010-adopt-a-documented-design-system.md) makes this
document the reference for UI work, and
[ADR 0011](docs/architecture/decisions/0011-adopt-the-ruby-for-good-design-system.md) makes
Tailwind v4 the system it describes.

If you are building a page, skip to [Building or changing a page](#building-or-changing-a-page).
Otherwise:

| If you want | Read |
| --- | --- |
| To learn the app, as a contributor or a user | [docs/onboarding.md](docs/onboarding.md) |
| To know how the records relate | [docs/domain-model.md](docs/domain-model.md) |
| To know what replaced the old markup | [docs/migration-map.md](docs/migration-map.md) |
| To know what changed and when | [docs/changelog.md](docs/changelog.md) |
| To know why a call went the way it did | [docs/design-decisions.md](docs/design-decisions.md) |

The components below make more sense once you know what a distribution is, so onboarding first
is not a formality.

## What this app is, and what the UI has to do

Human Essentials is inventory management for diaper banks and essentials banks. A **bank**
receives goods (donations, purchases, product drives), holds them across **storage locations**,
and sends them to **partner agencies**, who request what they need for the families they serve.

Three things about the domain shape almost every screen:

- **Everything belongs to an organization.** 22 models carry `belongs_to :organization`, and a
  user works inside exactly one bank at a time. The organization's name is on every page for
  that reason — see [Multi-tenancy is visible](#multi-tenancy-is-visible).
- **There are two audiences in one app.** Bank staff and partner agencies see different
  vocabularies, different navigation and different shells. A partner asks for "essentials
  requests"; the bank calls the same records "requests".
- **Inventory is a ledger, not a number.** Quantities are derived by replaying events
  (`DonationEvent`, `DistributionEvent`, `AdjustmentEvent`, and eleven more), so a screen that
  shows a quantity is showing a computed figure. That is why totals are rendered carefully,
  with `.numeric`/`.quantity` columns and delimited numbers, rather than as incidental text.

## Status

The migration off Bootstrap 5 + AdminLTE 3.2 is **complete**. Both are removed from the
`Gemfile`, the asset path and the importmap. Every controller except two renders on a design
system layout:

| Controller | Why it is not on a design system layout |
| --- | --- |
| `HistoricalTrends::BaseController` | Abstract. It has no views of its own; its three subclasses are migrated. |
| `StaticController` | `layout false`. The marketing home page and privacy policy are standalone public documents with their own stylesheet, not app screens. |

Anything else rendering `btn`, `card-body`, `form-group`, `col-md-*` or `fa-*` is a defect, not
a page waiting its turn: none of those classes are defined anywhere any more, so they draw
nothing at all. Grep for them — `bin/design/status.rb` reports coverage and
`bin/design/audit.js` audits a page in a real browser, but neither catches a migrated view that
passes a dead class into a partial. That is exactly how four icons stayed invisible on the
bank-side profile editor until after the migration was called complete.

Measured on 2026-08-18: 63 of 65 controllers on a design system layout, 299 of 392 views
carrying design system markup, 30 Stimulus controllers, and no undefined legacy classes left in
`app/views`. [docs/changelog.md](docs/changelog.md#current-state) keeps these current.

## Foundations

### Typography

**Figtree**, self-hosted from `public/vendor/` and declared once in `@theme`:

```css
--font-sans: "Figtree", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
```

Every layout sets `font-sans` on `<body>`. There is no second typeface and no CDN request.

| Role | Classes | Notes |
| --- | --- | --- |
| Page title (`h1`) | `text-2xl font-bold tracking-tight text-slate-900` | Exactly one per page, always via the page header partial. |
| Card title (`h2`) | `text-base font-semibold text-slate-900` | Emitted by the card partial. |
| Section title (`h3`) | `text-sm font-semibold text-slate-900` | Inside a card body. |
| Body | `text-sm text-slate-700` | The default reading size in this app. |
| Secondary | `text-sm text-slate-600` | Subtitles, descriptions. |
| Meta | `text-xs text-slate-500` | Timestamps, hints, counts. |
| Field label | `block text-sm font-medium text-slate-700` | Supplied by the simple_form wrapper. |

Heading level is document structure, not size. AdminLTE used `<h5>`/`<h6>` as "small and
bold", which left pages jumping from `h1` to `h5` and gave screen-reader users a broken
outline. Size is a class; the level says where you are in the document.

### Sentence case

**Sentence case for everything a person reads**: headings, buttons, labels, table headers,
nav items, flash messages, empty states.

> New donation · Print unfulfilled picklists · Fair market value · Storage locations

Not `New Donation`, `Print Unfulfilled Picklists`, `FMV`. Proper nouns keep their capitals
(NDBN, Human Essentials, a partner's name). This is the house style across Ruby for Good and
it is the single most common review note on UI PRs here.

### Colour

Brand is **indigo**, declared as a `--color-brand-*` scale in `@theme` so `bg-brand-600`,
`text-brand-700` and friends work exactly like any built-in Tailwind colour. Neutrals are
Tailwind's **slate**, not redeclared.

| Token | Use |
| --- | --- |
| `brand-600` | Primary button, active nav, focus ring, current page |
| `brand-700` | Primary hover, link text on white |
| `brand-50` / `brand-100` | Tinted surfaces, icon tiles, pills |
| `slate-900` | Headings, emphasised values |
| `slate-700` | Body text |
| `slate-500` | Meta text, muted values |
| `slate-200` | Hairline borders |
| `slate-100` | Dividers, hover fills |
| `slate-50` | Page background, row hover |

Semantic colour, one meaning each:

| Tone | Colour | Means |
| --- | --- | --- |
| success | emerald | Completed, approved, healthy, nothing to do |
| warning | amber | Needs attention, awaiting someone |
| danger | rose | Destructive, failed, below minimum |
| info | sky | Neutral information, in progress |

**Never colour alone.** Every coloured signal carries a word, and usually an icon too. A
row that is below its minimum quantity says "Below minimum"; an audit's status says what it
is; a partner's state is a pill with a label. This is WCAG 1.4.1, and it is also just
readable — a red cell does not say *why* it is red.

Text tones use the **-700** step. `rose-600` is 4.51:1 on white, which passes 4.5:1 by a
hair; -600 is only ever used as a border or a filled background with white text on it.

### Spacing, radius, elevation

Tailwind's 4px scale, unmodified. In practice:

| Thing | Value |
| --- | --- |
| Page gutter | `px-4 sm:px-6 lg:px-8`, `py-6` |
| Gap between cards | `gap-6` |
| Card padding | `p-5` (`px-5 py-4` in header and footer strips) |
| Table cell padding | `px-4 py-3` |
| Field spacing | `mb-4` between fields, `mt-1.5` label to input |
| Radius | `rounded-2xl` cards and dialogs, `rounded-lg` controls, `rounded-full` pills and avatars |
| Elevation | `shadow-sm` on cards, `shadow-xl` on dialogs. Nothing else has a shadow. |

Depth is carried by the hairline border, not the shadow. A card is white on `slate-50` with
`border-slate-200`; the shadow is a hint, not the edge.

### Iconography

**Bootstrap Icons**, self-hosted, compiled into the Tailwind bundle. Font Awesome is gone —
an `fa-*` class renders an empty element: no glyph, no error, just a gap.

```erb
<i class="bi-plus-lg" aria-hidden="true"></i>
```

Rules:

- An icon that sits beside its own label is decorative and is `aria-hidden="true"`.
- A control with **only** an icon carries its own `aria-label`. There is no third option.
- `IconHelper#fa_icon` still exists and still takes Font Awesome names, because ~40 call
  sites use it; it maps them to Bootstrap Icons and always sets `aria-hidden`. New code
  should write the `<i class="bi-…">` directly or pass `icon:` to a component helper.
- Icons are aligned once, in `@layer base`, rather than with per-call-site margins.

### Accessibility

Target is **WCAG 2.1 AA**. These are the rules this app has actually had to enforce:

- **Landmarks.** One `<main id="main-content">` per document. `<nav>` elements are labelled.
  A page never has two of the same landmark with the same name.
- **Skip link.** First focusable element on the app shells, visible on focus, `#222` on white
  (15.9:1). It is deliberately not `.sr-only-focusable`: that pattern reveals the link with
  `position: static`, which shifts the page as you tab into it.
- **One `h1` per page**, and no skipped levels below it.
- **Every control is named.** A field has a `<label for>`, or an `aria-label`, or an
  `aria-labelledby`. A `<label>` with no `for` names nothing.
- **A link cannot be disabled.** It stays focusable and clickable by keyboard and announces
  nothing. `UiHelper` renders an unavailable link action as a non-interactive `<span>` with
  `aria-disabled`, and an unavailable form action as a genuinely `disabled` `<button>`.
- **Focus is always visible**: `focus-visible:outline-2 focus-visible:outline-offset-2`.
  Nothing sets `outline: none` without replacing it.
- **Disclosure state is announced**: `aria-expanded` plus `aria-controls` on anything that
  opens or closes a region.
- **Colour is never the only signal** (see [Colour](#colour)).
- `lang` is bound to `I18n.locale`, and the viewport tag does not lock zoom.

The browser audit (`bin/design/audit.js`) checks the mechanical half of this — heading order,
unlabelled controls, nameless buttons, duplicate landmarks, leftover Bootstrap classes,
console errors — on any page you point it at. It does not replace reading the page with a
keyboard.

## Components

Components are Ruby helpers in `app/helpers/essentials_ui_helper.rb` and partials under
`app/views/shared/essentials/`. Reach for one before writing a utility string: the point of
the system is that a card looks the same on all 77 pages that render one.

### Buttons

One treatment per role. The **variant** carries the meaning, the **size** carries the context.

| Variant | Looks like | Use for |
| --- | --- | --- |
| `:primary` | Filled indigo | The one action the page is for |
| `:secondary` | White, slate border | Everything else |
| `:danger` | Filled rose | Destroys or rejects something |
| `:ghost` | No border, tinted on hover | Row actions, toolbar actions |

| Size | Use for |
| --- | --- |
| `:sm` | Inside a table row or a dense toolbar |
| `:md` | Page and section actions (default) |

```erb
<%= essentials_link_button "New donation", new_donation_path, icon: "bi-plus-lg" %>
<%= essentials_action_button "Deactivate", deactivate_partner_path(partner),
      method: :put, variant: :danger, confirm: "Are you sure?" %>
<button class="<%= essentials_button_classes(variant: :secondary, size: :sm) %>">Filter</button>
```

`essentials_link_button` is a `GET` — it navigates. `essentials_action_button` goes through
`button_to`, so the verb, the CSRF token and `disable_with` are handled for you. A thing that
changes state is never a link.

**`UiHelper` is the older API and it still works.** `new_button_to`, `edit_button_to`,
`delete_button_to`, `submit_button` and the rest have ~100 call sites; they now emit design
system classes and Bootstrap Icons, and their `type:`/`size:` options map onto the variants
above. Its own comment still holds: *anytime a button or pseudo-button is displayed, it
should be through one of these methods.*

### Status pills

A pill is a **state**, not a control: not focusable, does not look pressable.

```erb
<%= essentials_status_pill "Awaiting review", tone: :warning, icon: "bi-hourglass-split" %>
```

Tones: `:neutral` `:info` `:success` `:warning` `:danger` `:brand`. Each pairs a tint with a
word; pass an `icon:` when the pill is doing real signalling work rather than labelling.

### Icon tiles and avatars

```erb
<%= essentials_icon_tile "bi-box-seam", tone: :brand %>
<%= essentials_avatar_initials current_user.name %>
```

A soft coloured tile behind an icon means "a stat or a status". A **person** is an initials
avatar instead. Keeping these disjoint is what makes either one readable at a glance.

### Cards

The surface everything sits on: white, hairline border, `rounded-2xl`, `shadow-sm`.

```erb
<%= render "shared/essentials/card",
      title: "Filters",
      subtitle: "Narrow this list down.",
      actions: capture { essentials_link_button("Export", exports_path, variant: :secondary, size: :sm) },
      footer: capture { render "shared/essentials/pagination", collection: @donations },
      padded: false,
      card_id: "donations" do %>
  …
<% end %>
```

`padded: false` when the body is a table that should meet the card edges. `card_id` when
something needs to find the section — a spec, or an in-page anchor.

### Page header

Every page renders this, so the spacing cannot drift.

```erb
<%= render "shared/essentials/page_header",
      title: "New donation",
      subtitle: "Record essentials coming in from a donor.",
      back: {path: donations_path, label: "Back to donations"},
      actions: capture { essentials_link_button("Import CSV", …) } %>
```

It owns the page's only `<h1>`. Shape rules, measured rather than eyeballed: the back link
and title are one block with an 8px gap; `items-end` when there is no subtitle so a 40px CTA
sits on the `h1` baseline; `items-start` when there is one, so the CTA cannot be dragged down
to the subtitle's baseline.

### Filter bar

```erb
<%= render "shared/essentials/filter_bar", url: donations_path do %>
  <%= filter_select scope: :by_source, collection: Donation::SOURCES %>
  <%= render "shared/date_range_picker" %>
  <%= filter_button %>
  <%= clear_filter_button %>
<% end %>
```

Filters submit with **GET**, so a filtered view stays a shareable, bookmarkable URL. A plain
(borderless) bar sits 16px above the table it filters; wrap it in a card only when it is a
section in its own right.

`FilterHelper` builds the controls (`filter_select`, `filter_text`, `filter_checkbox`) and
gives each one a UUID-suffixed id with a matching label, so a filter control is always named.
`EssentialsUiHelper::FILTER_CONTROL_CLASSES` is the single definition of what one looks like.

The date range picker owns its own label. Callers used to add `label_tag "Date Range"`, which
pointed at `date_range` while the input's id is `filters_date_range` — the label named
nothing and clicking it did nothing, at all fourteen call sites.

### Tables

`.data-table` is a **component class**, not a utility string:

```erb
<div class="table-scroll">
  <table class="data-table">
    <caption>Donations received in the selected period</caption>
    <thead>
      <tr>
        <th class="date">Date</th>
        <th>Source</th>
        <th class="numeric">Quantity</th>
      </tr>
    </thead>
    <tbody>…</tbody>
  </table>
</div>
```

Composing these from utilities at each call site would mean a twelve-class string copy-pasted
across ~78 tables in 393 views, and it would drift on the first hurried PR. One definition is
what keeps a donations table and an audit table looking like the same app.

Column semantics reuse the class names the app already used under Bootstrap, so a table keeps
its meaning instead of re-deciding alignment cell by cell:

| Class | Effect |
| --- | --- |
| `.numeric`, `.quantity`, `.percent` | Right-aligned, tabular figures |
| `.date` | No wrapping |

Every table gets a `<caption>` (visually hidden) saying what it lists. `.table-scroll` is the
horizontal scroll container — a wide table scrolls, it does not squeeze.

### Forms

`simple_form`, with `:essentials` as the **default wrapper** — a plain `simple_form_for`
already produces design system markup. `essentials_form_for` is a convenience that also sets
the wrapper mappings explicitly.

| Wrapper | Applies to |
| --- | --- |
| `:essentials` | Everything by default |
| `:essentials_boolean` | A single checkbox — control and label on one line |
| `:essentials_collection` | Radio/checkbox groups — a real `<fieldset>`/`<legend>` |
| `:essentials_file` | File inputs, styled through `::file-selector-button` |

```erb
<%= essentials_form_for @donation do |f| %>
  <%= essentials_error_summary(@donation) %>
  <%= f.input :source, required: true %>
  <%= f.input :issued_at, label: "Date received" %>
  <%= submit_button %>
<% end %>
```

- **Do not pass a block to `f.input` just to restyle the field.** A block tells simple_form
  to skip the wrapper's input, which is why several forms ended up with the wrapper's own
  class string copy-pasted in by hand.
- `essentials_error_summary` sits above the form: `role="alert"`, names each field, links
  each message to its input.
- Error text is `rose-700`. `rose-600` is only a border.
- `required: true` sets the HTML5 `required` attribute regardless of `browser_validations`.
  Conditional validators are *not* inferred as required — mark them explicitly or not at all.

### Modals

Native `<dialog>`, opened with `showModal()`.

```erb
<button type="button" data-action="click->dialog#open" data-dialog-id-param="csv-import-modal">
  Import CSV
</button>

<%= render "shared/essentials/modal", id: "csv-import-modal", title: "Import vendors" do %>
  …
<% end %>
```

`showModal()` gives the focus trap, the Escape handler, inert background content and the top
layer for free — all things the Bootstrap modal reimplemented in JS and got partly wrong. The
`dialog` Stimulus controller lives on the app shell, so any page can open a dialog by id; it
adds backdrop-click closing and restores focus to whatever opened it.

A trigger names its dialog with `data-dialog-id-param`. A trigger that names nothing is a
trigger that does nothing.

### Flash messages

```erb
<%= render "shared/essentials/flash" %>
```

Rendered by the shells inside a `turbo_frame_tag "flash"`, so a Turbo response can replace
it. A message bar gets a **plain glyph**, never an icon tile: a soft `-50` tile on a `-50`
surface is invisible, and a filled one shouts and adds height. `role="status"` for
informational tones and `role="alert"` for warning and danger, so a screen reader interrupts
only when something actually went wrong.

Keys map `success → :success`, `error → :danger`, `alert → :warning`, anything else `→ :info`.

### Empty states

Never render bare empty table chrome. Three flavours, and every screen picks one
deliberately:

| `kind:` | Means | Offers |
| --- | --- | --- |
| `:cold_start` | Nothing exists yet | The create action |
| `:no_results` | A filter matched nothing | Clearing the filter |
| `:all_clear` | Genuinely nothing to do | Reassurance |

```erb
<%= render "shared/essentials/empty_state", kind: :no_results,
      title: "No donations found",
      body: "Nothing matched these filters.",
      action: capture { clear_filter_button } %>
```

`essentials_filtered?` decides between the first two. It reads `params` directly rather than
the controller's `filter_params`, because only about half the controllers define that — a
view calling it is one un-filtered controller away from a `NameError`, which is exactly how
the audits index started returning 500s.

### Tabs

```erb
<%= render "shared/essentials/tabs", tabs: [{id: "open", label: "Open"}, {id: "closed", label: "Closed"}] %>
```

Real `role="tablist"` semantics with roving `tabindex`: arrow keys move between tabs, Home and
End jump to the ends, `aria-selected` and `aria-controls` are wired to the panels. Panels
carry `data-tabs-target="panel"` in the same order as the tabs.

### Pagination

```erb
<%= render "shared/essentials/pagination", collection: @donations %>
```

Rendered **inside** the table card as its last child — a compact `border-t` strip, not a
detached bar floating below the card. Kaminari's own partials in `app/views/kaminari/` supply
the `<nav aria-label="Pagination">` landmark and the `.pagination-link` styling; the current
page is marked with `aria-current="page"` and styled off that attribute, so the two cannot
disagree. The truncation gap is a `<span>`, not a link to `#`.

### Charts

Highcharts, through `shared/_highcharts`. A chart is never the only representation of the
data — the table it summarises is on the same page, because a chart is not readable by a
screen reader and not printable in colour.

## App shell

Three layouts. All of them load `tailwind.css` and nothing else.

### Bank shell — `layouts/essentials_app.html.erb`

Fixed sidebar at `lg`, off-canvas drawer below it, sticky top bar, `<main id="main-content">`.
`data-controller="shell turbo dialog"` sits on the wrapper: the drawer, the account menu and
the collapsible nav groups are all `shell`, and `dialog` is there so any page can open a
`<dialog>` without scoping its own controller.

Navigation is built in `EssentialsNavHelper`, not written into the markup. Two flat
destinations — **Dashboard** and **My organization** — then four collapsible groups:

| Group | Contains |
| --- | --- |
| Operations | Donations, purchases, requests, distributions, pick ups & deliveries |
| Inventory | Items & inventory, kits, storage locations, transfers, inventory adjustments, inventory audit, barcode items |
| Network | Partner agencies, partner announcements, donation sites, product drives, product drive participants, manufacturers, vendors |
| Reporting | The fifteen reports, named `Subject — cut` so they sort together |

Groups collapse because there are 36 destinations in the sidebar — 34 inside the groups, plus
the two flat ones. A flat rail works up to a dozen or so; past that it becomes a wall of text
you scan rather than read. A group is open when the current page is inside it, so nobody has to
hunt for where they already are.

The information architecture is unchanged from the AdminLTE sidebar — this migration was not
the place to re-plan the app — with one exception: the "New X" items were dropped. Every one
of them duplicated the primary action already sitting at the top right of the index page it
pointed at.

### Partner shell — `layouts/essentials_partner.html.erb`

Same construction, a much shorter list: Dashboard, my profile, essentials requests,
distributions, and — when the partner is set up for them — families and children. Partners see
their own organization's name in the top bar, never the bank's internal navigation.

### Auth shell — `layouts/essentials_auth.html.erb`

Split: brand panel on the left at `lg`, form column on the right, single centred column below
that. Used by every Devise view and the account request flow, wired in `config/application.rb`.

No skip link here, deliberately: there is no repeated navigation block ahead of the content to
skip past, and a skip link that jumps two elements forward is noise in the tab order.

## Key patterns

### Turbo is opt-in per action

`<body data-turbo="<%= @turbo %>">`. Controllers opt in; it is not on by default. Turbo frames
are used for the flash strip and for the few index pages that update in place.

### Stimulus first

No jQuery in new code, and no framework JS at all. Controllers in `app/javascript/controllers/`:

| Controller | Does |
| --- | --- |
| `shell` | Drawer, account menu, collapsible nav groups, Escape handling |
| `dialog` | Opens/closes any `<dialog>` by id; backdrop click; focus restore |
| `tabs` | Roving tabindex, arrow/Home/End |
| `disclosure`, `expandable`, `accordion` | Show/hide with `aria-expanded` |
| `confirmation` | Pre-check, then a confirmation `<dialog>` before submitting |
| `form_input` | Add/remove repeated fieldsets |
| `date_range`, `highchart`, `select2` | Wrappers around the three third-party widgets |

Third-party widgets get accessible names added on top: Litepicker's month buttons and
FullCalendar's toolbar buttons both ship with none.

### Multi-tenancy is visible

The organization's name is in the top bar on every bank page, and the partner's name on every
partner page. It is not decoration: users work across several organizations and a screen with
no tenant on it is a screen you can act on by mistake.

### Print

`distributions/print` and the picklists are print targets. They render on the app shell and
rely on the browser's print stylesheet; there is no separate print layout.

## Build

Tailwind v4.3.3 through the **`tailwindcss-rails`** gem — the standalone CLI, no Node, no
`package.json`. This app has no Node in its deploy path, and `docs/code_standards.md` is
explicit that new dependencies need strong justification, so the alternative (`cssbundling-rails`
plus npm) would have meant adding a runtime to production to produce identical CSS.

```
app/assets/tailwind/application.css   → entry point: @import, @theme, @layer
app/assets/builds/tailwind.css        → compiled output, served by the layouts
```

```bash
bin/rails tailwindcss:build     # compile once
bin/rails tailwindcss:watch     # compile on change
bin/start                       # server + job worker + CSS watcher (Procfile.dev)
```

Notes that will bite you otherwise:

- **`@source` globs are required.** Rails puts markup outside the CSS tree, so Tailwind's
  automatic source detection cannot find `app/views`, `app/helpers` or `app/javascript`.
  A class only used in a file outside those globs will not be generated.
- **`config.assets.css_compressor = nil`.** libsass cannot parse Tailwind v4 output; leaving
  the compressor on fails the build with `SassC::SyntaxError: Internal Error: Not enough
  space`.
- **`app/assets/tailwind` is removed from the Sprockets load path** by an initializer, so the
  uncompiled entry point is never served.
- **Precompiled assets go stale.** If system specs fail with
  `Failed to resolve module specifier`, `public/assets` is out of date: `bin/rails
  assets:clobber assets:precompile`.
- Initializers do not hot-reload. Changing `config/initializers/simple_form_essentials.rb`
  needs a real server restart, not a page refresh.

## Building or changing a page

1. **Start from the partials.** Page header, card, table, empty state, pagination. If you are
   writing a twelve-class string that already exists in a partial, use the partial.
2. **One `h1`**, from the page header. Card titles are `h2`. Do not skip levels.
3. **Sentence case.** Every string.
4. **Give the table a `<caption>`** and use `.numeric` / `.quantity` / `.date` on the columns
   that need them.
5. **Pick an empty state deliberately** — cold start, no results, or all clear.
6. **Name every control.** If a control has no visible label, it needs `aria-label`.
7. **Colour is never the only signal.** Pair it with a word.
8. **A thing that changes state is a button, not a link.**
9. **Run the audit**: `pw bin/design/audit.js /your/path`. It catches heading skips, unnamed
   controls, duplicate landmarks and leftover Bootstrap classes that specs pass straight over.
10. **Run the specs, including the system specs for the area you touched.** Request specs do
    not load JavaScript and will not notice a page that renders but cannot be used. Three
    classes of defect in this migration were visible only to the system specs: markup that a
    browser reparses into a different shape, Stimulus controllers toggling classes that no
    longer exist, and forms whose fields had ended up outside the form.

### When the system does not cover it

Use industry best practice, keep it consistent with the tokens above, and **write down what
you decided and why** in [`docs/design-decisions.md`](docs/design-decisions.md). That file is
the running log; this file is the settled system. Anything in the log that turns out to be
general gets promoted into here.

Record the change itself in [`docs/changelog.md`](docs/changelog.md) in the same commit. The two
files answer different questions and both get asked: the log says why you chose this, the change
log says when it arrived and what to blame.

## Backlog

Known gaps, in rough priority order:

- **`app/views/static/`** (marketing home page, privacy policy) is still on its own
  stylesheet. It is public-facing and standalone, so it was excluded from the migration
  deliberately, but it is now the only part of the app that does not look like the app.
- **Charts are not accessible.** Highcharts output has no text alternative beyond the table
  beside it. A summary sentence per chart would be cheap.
- **No dark mode.** The tokens would support it; nothing has been built.
- **`shared/_custom_file_input`** duplicates what `:essentials_file` now does through
  `::file-selector-button`. It can probably go.
- **The partner profile forms** are the largest remaining views and still carry a lot of
  bespoke layout that predates the system.
