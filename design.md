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
| Whether a table conforms | [docs/table-audit.md](docs/table-audit.md) |

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

### Row actions

**Every action in a table row uses `:ghost`, whatever it does.** A table is read down a column,
so a second weight implies a hierarchy that does not survive the next row — on a partner list
"Review profile" and "Request recertification" are each the main thing to do for their own row,
and emphasising one of them tracks the action's name rather than its importance. Destructive row
actions stay `:ghost` too, tinted with `text-rose-700 hover:bg-rose-50`; the confirmation is
what protects the user, not the colour.

`:primary` belongs in the page header, once. If a row action looks like the page's main action,
the page has as many main actions as it has rows.

Do not reach for the legacy `edit_button_to` / `delete_button_to` / `view_button_to` shims in a
row: they map onto `:primary` and `:danger`, which are filled.
[docs/table-audit.md](docs/table-audit.md) lists the rows that still do.

### Filters

**One filter: apply on change, no button.** Several filters: keep the Filter button. Auto-applying
each of five controls fires a query per control while the user is still describing what they
want; making them press a button to change one select is friction with nothing on the other side
of it. Four index pages filter on one thing and pass `auto_submit: true`; twelve filter on two to
nine and do not.

**The first option is the reset, so a single-filter bar drops "Clear filters"** (`clear: false`).
Two ways to undo the same thing is one too many. Where "everything" is meaningfully different
from the default view, say so with its own option — the partner list defaults to `Active (6)`
and offers `All (7)` separately, because deactivated partners are hidden by default and were
previously unreachable alongside the rest.

Counts belong in the option label — `Awaiting review (1)` — not in a separate strip.

**Keep option labels short and put any rule in hint text.** `Active (6)`, not
`Active, excluding deactivated (6)`. An explanation inside an option is re-read every time the
list is opened, and it is invisible while the list is shut, which is exactly when someone is
wondering what the current selection means. `filter_select` takes `hint:`, renders it as meta
text and wires up `aria-describedby`.

**No `<optgroup>`.** Its label is drawn by the platform rather than by this stylesheet — macOS
renders it around 2.6:1 — so its contrast is not ours to guarantee. Grouping also implies a
hierarchy that a filter list rarely has.

Two things that bite:

- A select submits `""` where an absent link submits nothing. `Filterable#class_filter` skips
  blank values, so a blank option falls through to *unfiltered* rather than the default scope.
  Compact the params in the controller.
- `FILTER_SELECT_CLASSES`, not `FILTER_CONTROL_CLASSES`, for a `<select>`. The browser draws the
  chevron inside the right padding, so a select needs `pr-10` where a text input needs `px-3`.

### Stats

A figure and the words that say what it counts. `essentials_stats` renders a description list,
because that is the relationship: the label describes the value.

```erb
<%= essentials_stats([
      {label: "Items distributed this month", value: 1_284},
      {label: "Scheduled for future distribution", value: 310}
    ], title: "Totals", subtitle: essentials_stats_scope(@donations.size, "donation")) %>
```

**Give the band a header.** Without one it is a row of numbers with nothing saying what they
are, and a bare period above it reads as though it might belong to the table underneath. The
title names the thing (*Totals*); the subtitle states the **scope** —
`essentials_stats_scope(count, noun)` builds it:

> 13 donations, from June 19, 2026 to September 19, 2026
> 4 donations **matching these filters**, over the last 30 days
> No distributions, today

It says "matching these filters" only when something *other than the date range* is set. A date
range is always set, so counting it would make every page claim to be filtered when the user has
touched nothing. There is no leading "The": it does not survive the edges — "The 1 donation" and
"The 0 donations" both read as though a machine wrote them.

**One card, hairline separators, no fill per figure.** A summary band is one reading, and a
filled box around each figure makes it four objects instead. This is the metric strip Stripe,
Shopify and Linear all use.

The separators are a `gap-px` grid showing a `slate-200` backdrop through the gaps between white
cells. That draws a hairline between **every pair of neighbours — rows as well as columns**,
which `divide-x` cannot: in a grid of more than one row `divide-*` borders by DOM order rather
than by grid position, so a 2×2 arrangement comes out wrong.

**The figure count must divide the column count.** `STATS_COLUMNS` maps one to the other:

| Figures | Columns |
| --- | --- |
| 2 | 1 → 2 at `sm` |
| 3 | 1 → 3 at `sm` |
| 4 | 1 → 2 at `sm` → 4 at `lg` |
| 5 | 1 → 5 at `lg` (five columns at 640px leaves ~128px, which a currency figure does not fit) |
| 6 | 1 → 2 at `sm` → 3 at `lg` |

This was a flat `sm:grid-cols-2 lg:grid-cols-3` whatever the count, which orphaned a tile on
**every** page that had a band — four figures went 3 + 1 at desktop, three went 2 + 1 at tablet.
An empty cell matters more now than it did then: with the separators drawn by a backdrop showing
through, a missing cell shows as a grey block rather than as whitespace.

**A statistic is not a heading.** The reports marked six of them up as `<h2>`, which put the
page's figures into its heading outline — someone navigating by heading heard "Total spent on
diapers: $412" as document structure. They also set the figure in a `<p>` at `text-2xl` while
the real headings were `text-base`, so the visual hierarchy ran opposite to the semantic one.
A heading names a section; if the thing is data, it is a `<dt>`/`<dd>` pair.

### Status pills

A pill is a **state**, not a control: not focusable, does not look pressable. It is also
**exceptional** — badge the rows that need attention, not every row. A column where each row
carries a badge spends colour on something the reader already knows, and the eye learns to skip
the column, exceptions included. Most tables here get this right: "Inactive", "Expired" and
"Below minimum" appear only when true, next to the name, without a column of their own.

**An icon on a pill is decorative, and only earns its place on a pill that is rare.** The word
carries the meaning — which is also what stops the pill depending on colour alone — so a column
where every row is badged should drop the icon: six of them stack into clutter. Keep icons for
exceptions like "Inactive" and "Expired". Pills never wrap (`whitespace-nowrap`); a two-line pill
leaves its icon centred across both lines, which reads as a misalignment rather than a wrap.

Never build a control out of `PILL_TONES`. A filter chip that borrows the status palette is a
control that looks like data; the partner list does this and
[docs/table-audit.md](docs/table-audit.md) records it as a defect.

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

**At most three actions, exactly one of them primary, primary last.** Everything else is
`:secondary` or `:ghost`. Past three, the least-used collapse behind a "More actions" menu.
Six index pages here already carry exactly three — two secondary and one primary — so this
writes down what the app already does rather than changing it.

The actions container carries `data-page-header="actions"` so a spec can count what is in it
without walking ancestors.

**A page has one place for its main action.** If a fourth button appears, that is the signal
that something else is wrong — usually a section of the page wanting an action of its own. Do
not tuck it above a table; see the tabs rule below.

### Tabs

Two components, and picking the wrong one is an accessibility bug rather than a style choice.

| | Use when | Component |
| --- | --- | --- |
| **Panel tabs** | Panels swap in place, same URL | `shared/essentials/tabs` |
| **Page tabs** | Each tab is its own URL | `shared/essentials/page_tabs` |

`role="tab"` tells a screen reader that activating this swaps a panel in the current document.
If the tab loads a page, that promise is false, and the tablist takes the arrow keys from the
browser on the way. Page tabs are a `<nav>` of links with `aria-current="page"` on the current
one.

**Prefer page tabs when a tab needs its own action.** The page header can only follow the tab
if the tab is a URL — which is how "New partner group" stopped being a fourth button floating
above a table. It is also how a tab becomes something you can link to, bookmark and go back
from.

### Filter bar

```erb
<%= render "shared/essentials/filter_bar", url: donations_path, frame: "donations-results" do %>
  <div class="min-w-0"><%= filter_select scope: :by_source, collection: Donation::SOURCES %></div>
  <div class="min-w-0"><%= render "shared/date_range_picker" %></div>
<% end %>
```

Filters submit with **GET**, so a filtered view stays a shareable, bookmarkable URL. A plain
(borderless) bar sits 16px above the table it filters; wrap it in a card only when it is a
section in its own right.

**The bar is a grid, not a flex row**, and every cell is `min-w-0`:

```
grid-cols-1 · sm:grid-cols-2 · lg:grid-cols-3 · xl:grid-cols-4
```

A flex item sizes to its *content* — the longest option in the menu — so `flex-wrap` with
min-width boxes gave six different control widths across four pages (208 to 289px) and packed
each line left, leaving 337px, 793px and 852px of ragged space at the ends. Equal columns fix
both: the width follows the breakpoint, not the text, and a long option truncates rather than
pushing its column past its share.

**Every cell is one column, including the date range**, which is a popover: one trigger showing
the current range, opening a panel with the presets on one side and a custom range on the other.
That is what Stripe, Shopify, Google Analytics, Metabase and Linear all do, and the reason is
layout — a panel is over the page, so it costs nothing below it. Inline, choosing *Custom* turned
a 64px cell into a 216px one and added 152px to the bar at every width.

The actions are an ordinary cell with `self-end`, so they follow the last filter. On
`col-span-full` they took a row of their own on every page, including the ones with a single
filter.

**Every bar collapses** behind a Filters button, whatever its size. This was a threshold — five
filters or more — and two behaviours across sixteen pages is worse than one whichever one it is:
learning the filter bar on donations and then meeting something else on transfers teaches nothing
transferable.

| Page | Filters | Before all of this | Now |
| --- | --- | --- | --- |
| `/donations` | 9 | 264px, 4 rows | **38px** |
| `/distributions` | 7 | 188px | **38px** |
| `/transfers` | 3 | 112px | **38px** |
| `/partners` | 1 | 112px | **38px** |

The collapsed bar **shows what is set**, as chips built by `filter_summary_controller.js`: a count
on the button, one dismissible chip per active filter, and *Clear all*. That is the price of
collapsing at all — a filter set that hides both itself and its effect is how someone concludes
their records have disappeared. The chips are built in the browser, not rendered by the server,
for the same reason the export link is: the bar is outside the frame and does not re-render when a
filter applies.

**One Clear, beside the chips.** It used to be duplicated inside the panel, where it is invisible
exactly when the panel is shut. It hides itself when nothing is set.

The date range counts as set only when it is not the range the page would have shown anyway; its
select carries `data-default-value` to say which that is.

**Filters apply on change. There is no Filter button.** Pass `frame:` and the bar submits into
that Turbo Frame, so only the results are replaced:

```erb
<%= render "shared/essentials/filter_bar", url: donations_path, frame: "donations-results" do %>
  …controls…
<% end %>

<%= turbo_frame_tag "donations-results", target: "_top", data: {turbo_action: "advance"} do %>
  …summary card, table, pagination…
<% end %>
```

Four things about that snippet are load-bearing, and all four were found by breaking them:

| | Why |
| --- | --- |
| **`target: "_top"`** | Without it, every link *inside* the frame navigates the frame. Row actions then fetch a page with no matching frame and Turbo discards the response: *"The response (200) did not contain the expected `<turbo-frame>`"*. This broke 66 specs. |
| **`data-turbo: true`** on the form (set by the partial) | Turbo Drive is off app-wide. Turbo only ignores that for elements *inside* a frame, and this form targets one from outside, so without an opt-in the browser does a **silent full page reload** — silent because the filter still works. |
| **`turbo_action: "advance"`** | Keeps the URL in step, so a filtered view stays shareable and bookmarkable. |
| **The form stays outside the frame** | Inside it, the controls are replaced on every change and focus is lost mid-filtering. |

The **Export link** is in the page header, outside the frame, so `auto_submit_controller`
rebuilds its query string from the form on every frame load. It listens on the **document** and
resolves the frame when it needs it, not in `connect()`: the form is parsed before the frame it
targets, so resolving it early can return null and leave the link — and the announcement —
silently dead.

The flash is **not** cleared when a filter applies. It was, briefly; removing 56px from above the
results moves everything below it under a cursor that is often already over a row action, and a
layout shift in response to an unrelated action is a hazard. A stale message describes something
that did happen, and it clears on the next navigation. Exporting the previous filter's rows
is a worse failure than a stale table, because the file looks right and nothing on screen says
otherwise.

Applying in place is silent to a screen reader — nothing navigates, focus does not move — so the
bar renders a `role="status"` region, **outside** the frame, and the controller writes the new
result summary into it. A live region that is itself replaced does not announce its new contents.
`turbo-frame[busy]` dims the results while a request is in flight, after a 150ms delay so a fast
response never flickers.

Text filters debounce at 400ms; selects, checkboxes and dates apply immediately. Choosing
*Custom* in the date range does **not** fire a request — it only reveals the two date inputs, and
the range has not changed yet.

**In specs, call `wait_for_filters` after changing a control**, and `open_filters` before
reaching a control on a bar that collapses. There is no longer a click to synchronise on. See
`spec/support/filter_helpers.rb` for why it waits on network idle rather than on the frame's
`busy` attribute, and why the quiet period is longer than the debounce.

`FilterHelper` builds the controls (`filter_select`, `filter_text`, `filter_checkbox`) and
gives each one a UUID-suffixed id with a matching label, so a filter control is always named.
`EssentialsUiHelper::FILTER_CONTROL_CLASSES` is the single definition of what one looks like.

The date range picker owns its own label, for the same reason. Callers used to add
`label_tag "Date Range"`, which pointed at `date_range` while the input's id was
`filters_date_range` — the label named nothing and clicking it did nothing, at all fourteen
call sites.

### Date range picker

```erb
<%= render "shared/date_range_picker" %>
```

A preset `<select>`, with two native `<input type="date">` fields revealed when **Custom** is
chosen. No calendar widget and no third-party dependency: it is built from the same
`FILTER_SELECT_CLASSES` and `FILTER_CONTROL_CLASSES` as every other filter, so it matches the
rest of the bar by construction rather than by being re-themed.

The presets come from `DateRangeHelper#date_range_presets` and are computed **server-side**, in
`Time.zone`. They are ordered shortest window to longest with the catch-alls last, and named in
sentence case like every other option in the app.

The wire format is a single string, and changing it is a bigger job than it looks:

| Parameter | Carries | Read by |
| --- | --- | --- |
| `filters[date_range]` | `"June 19, 2026 - September 19, 2026"` — one hidden field | `#selected_interval`, which splits on `" - "` and parses with `strptime` |
| `filters[date_range_label]` | the preset name, straight off the select | `#date_range_label`, which downcases before matching |

The `date-range` Stimulus controller exists only to keep that hidden field in step with the
visible controls. It does no date arithmetic — the server hands it the preset dates — and it
reports an end-before-start range in the page, with `setCustomValidity` to block the submit.

**Say the period in words as well as in the control.** `date_range_label` returns a phrase
built to be appended to a noun — `"13 distributions #{date_range_label}"` — so every branch
carries its own preposition: *over the last 30 days*, *in the prior year*, *since June 19,
2026*. It is always used mid-sentence, so it stays lower case.

Two places use it, and a third deliberately does not:

| Place | What it says | Why |
| --- | --- | --- |
| `essentials_stats_scope` | *13 donations, over the last 30 days* — the summary card's subtitle | The band says how many; it never said how many **of what window** |
| The `:no_results` empty state | *No distributions over the last 30 days* | Answers "did I filter wrong, or is there nothing?" |
| A standalone "Showing 13 distributions…" line | — | Rejected: the summary card already shows the count |

Both are **sentence case**, not the uppercase-with-tracking eyebrow this slot usually attracts.
A period is read, not scanned as a category, and the rule above has no exception for small text.

Every preset in `date_range_presets` needs a clause in `date_range_label`. Without one it falls
through to `selected_range_described` and gets described by its dates instead of its name;
`spec/helpers/date_range_helper_spec.rb` fails if a preset is added without one.

Which option is selected on load is decided by **matching the dates**, not by trusting
`filters[date_range_label]`. Nothing guarantees a hand-edited or bookmarked URL carries a label
that describes its range; a range matching no preset reads as *Custom*, with the two dates
filled in.

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

**Two things the browser does that preflight undoes**, both restored in `@layer base` on
`dialog:modal`:

| | Why it matters |
| --- | --- |
| `margin: auto` | A modal is centred by the UA's own `margin: auto`. Preflight sets `margin: 0` on every element, which put **every dialog in the app in the top-left corner** — 28 files. |
| `max-height` / `max-width` | Without them a long dialog grows past the viewport and its top scrolls out of reach. |

The dialog is `open:flex open:flex-col` — the `open:` variant, because a `display` utility applied
unconditionally would override `dialog:not([open]) { display: none }` and show it always. The body
scrolls rather than the whole dialog, so the header and footer stay put, and it carries
`tabindex="0"`: a scrollable region has to be reachable by keyboard (WCAG 2.1.1).

### Popovers

An anchored floating panel — the account menu, the date range filter. `popover_controller.js`
owns all of them.

```erb
<div class="relative" data-controller="popover">
  <button type="button" aria-haspopup="dialog" aria-expanded="false" aria-controls="panel-id"
          data-popover-target="trigger" data-action="click->popover#toggle">…</button>

  <div id="panel-id" hidden role="dialog" aria-label="…"
       data-popover-target="panel"
       class="absolute left-0 z-30 <%= EssentialsUiHelper::POPOVER_SURFACE_CLASSES %>">…</div>
</div>
```

**A popover is not a modal**, and the difference is deliberate: it must not trap focus or make the
page inert, because you are meant to see what you are filtering while you filter it. What it does
share is the rest of the contract, and every part of it is a thing hand-rolled versions get wrong:

- **Escape closes it and focus returns to the trigger**, so the keyboard never ends up somewhere
  invisible.
- **A click outside closes it; a click inside does not** — otherwise choosing two dates would be
  impossible. Closing by outside click does *not* pull focus back, because the click has already
  put focus where the user meant it.
- **`aria-expanded` on the trigger** tracks the state, and the panel is `hidden` while closed, so
  it is out of the accessibility tree rather than merely invisible.
- **It flips above the trigger** when there is no room below, and shifts left rather than leaving
  the viewport. Measured from the trigger's rectangle: CSS anchor positioning is still Chrome-only.

**One elevation for anything above the page.** `POPOVER_SURFACE_CLASSES` is the same surface as a
dialog — `rounded-2xl border-slate-200 bg-white shadow-xl`. The scale has two steps on purpose:
`shadow-sm` for things in the page, `shadow-xl` for things over it. The account menus used
`shadow-lg`, a third step nothing else shared.

**Open one in a test.** `bin/design/overlay-audit.js` opens every dialog and popover and checks
centring, viewport fit, accessible name, Escape, focus return and surface, and runs axe on the
opened overlay. It exists because the dialog centring bug survived both other audits: one reads
markup and the other scans the page as loaded, and **neither had ever opened anything**.

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

### Sidebar rules

Four rules, and the first three exist because breaking any one of them was reported as
"the nav looks busy".

1. **Icons mark the top level, and only the top level.** A standalone rail item, a group
   header, a pinned item: icon. Anything nested inside a group: no icon, indented instead.
   Icons on both levels give the eye two columns of glyphs and stop either one meaning
   anything. `NavItem` takes an optional `icon:` for this; sub-items omit it.
2. **Sentence case, including group headers.** Uppercase is a convention for a static section
   *label*. These headers are buttons the same size as the destinations beneath them, and
   uppercase removes word shape, which is what you scan a rail by.
3. **One glyph, one meaning, across the whole app.** A circled question mark means "this needs
   your attention" on a status, so it cannot also mean "help" in the top bar. The user guide is
   `bi-book`; in-app help is `bi-life-preserver`.
4. **A group holds at most about seven items.** Past that it is a menu inside a menu and wants
   a landing page instead. `Reporting` held 15 and became the reports hub for exactly this reason.
5. **Weight follows the level, not the behaviour.** Every top-level item is
   `font-semibold text-slate-700`, whether it expands or not; every nested item is
   `font-medium text-slate-600`. The chevron says "this opens"; type says how deep you are.

Groups collapse and the one containing the current page opens on load.

Rule 5 was added after Dashboard, Reports and My organization were found sitting at the *child*
weight beside Operations and Inventory at the parent weight — all four at the same indent. A
top-level destination read as a child that had lost its parent, which is what "the nav looks odd"
turned out to mean. This is the convention in GitHub, Linear, Notion, Jira, Stripe and Vercel:
disclosure is marked by an affordance, hierarchy by type.

**Ordering.** Home first; then the work, grouped by the thing it acts on; then read-only views of
that work; then the pinned account item. Stripe, Shopify, Xero and QuickBooks all order a rail
this way, and the reason is frequency: you visit a report about what you did less often than you
do the thing. So: *Dashboard*, the three working groups, *Reports*, and *My organization* pinned.

**Spacing follows the same idea as weight.** One `space-y-4` between every top-level entry —
group or lone destination — and `space-y-0.5` between items inside a group, `mt-1` under a group
header. *Dashboard* and *Reports* used to share a list at the inner spacing, so they clustered at
2px while everything else sat 16px apart. A section is a meaningful grouping, not "the leaves that
happen to be adjacent": each of those two is a section of one.

| | Gap |
| --- | --- |
| Between top-level entries | 16px |
| Group header to its first item | 4px |
| Between items in a group | 2px |

**The bottom strip.** The rail's pinned item and the page footer are both `h-14` with a full-bleed
top border, so their rules meet at the same height and run into the rail's own `border-r` as one
line across the screen. They were 12px apart, which reads as a mistake rather than a separation.
The two carry different type on purpose — the rail item is a destination at `text-sm`, the footer
is a colophon at `text-xs` — but they share a baseline grid.

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
| `date_range` | Keeps the date filter's hidden `filters[date_range]` string in step |
| `auto_submit` | Applies a filter bar on change; announces the result, keeps the export link current |
| `filter_summary` | The chips and count beside a collapsed filter bar |
| `highchart`, `select2` | Wrappers around the two remaining third-party widgets |

Third-party widgets get accessible names added on top: FullCalendar's toolbar buttons ship
with none. Litepicker used to need the same treatment for its month buttons; it was replaced
by the date range picker above and its two CDN pins are gone.

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

### A summary belongs on the page that holds the data

**Do not build a page whose job is to total another page.** Filters at the top, the figures
those filters produce directly beneath them, the table under that. One page, one set of filters,
one export. Nobody should navigate to see the total of what they are already looking at.

Four "summary reports" were removed for this reason. Each had fewer filters than the index it
summarised, no full table, and the same totals — `/distributions` has seven filters and thirteen
columns against the report's one filter and a preview list — and then linked back to the index it
was a copy of. Their figures now sit at the top of the index, driven by the same filters as the
rows.

Retired URLs redirect rather than 404. A report link may be in someone's bookmarks or in an email
to a funder.

### Cards in a grid

**Equal cards need a uniform unit.** Six subject cards holding lists of one to four reports ran
143px to 378px, and stretching only ever equalises a row against itself. Fifteen tiles, one per
report, were uniform and pushed everything below the fold. What works is the middle: a card per
subject, `auto-rows-fr` so the grid equalises them, and inside it one line per report plus a
short qualifier.

**A qualifier, not a sentence.** "Itemized · by item and partner", not a full description. A hub
is a menu; a sentence per entry turns a menu into reading.

**One icon per card, not one per row.** The icon marks the subject. Repeating it down every row
gives the eye a second column of glyphs to skip and marks nothing out.

**A drill-through link names its destination.** Not "See more…" — it went from the distributions
*report* to the distributions *table*, which is a different page about different things.
"View all distributions" says where it goes.

### Figures in a band

`dollar_value` blanks a zero, which is right in a table column where zeros are noise and wrong in
a stat band where the figure is the content — an empty figure reads as broken rather than as
nought. Use `dollar_presentation` for a stat.

### Building a form page

Every form page renders `page_header` with a `back:` link, then one
`shared/essentials/card`, then fields through `f.input` so the `:essentials` wrapper owns the
label, the spacing and the error message.

- **Never pass `class:` to `f.input`.** simple_form ignores it; the field is then styled by
  whatever the wrapper happens to do. `input_html: {class: …}` is the argument that works.
- **A radio or checkbox group is a `<fieldset>` with a `<legend>`.** A label followed by `<br>`
  and a run of `&nbsp;` announces the question once and connects nothing to it.
- **Load the page when you are done.** Two assertions catch the whole class of unbalanced
  markup, and a class-name audit catches none of it:

  ```js
  form.contains(submitButton)                              // must be true
  fieldsOutsideForm(document.querySelector('main form'))   // must be 0
  ```

  Three pages in this app had a submit button *outside* the form holding its fields. They
  worked, because the HTML parser splits malformed markup into two forms and re-associates the
  button — which is exactly why nobody noticed.

`ruby bin/design/page-audit.rb` checks the mechanical part and exits non-zero on a defect.
It cannot check the two assertions above.

## Backlog

Known gaps, in rough priority order:

- **Review the Brakeman warning on every release.** It currently reports one: Rails 8.0.2.1
  reaches end of support on 2026-10-07 (`Gemfile.lock:539`, weak confidence, unmaintained
  dependency). It is not introduced by the design work — `main` reports the same one — but
  nothing in this repo's routine says who looks at Brakeman or when. Run
  `bundle exec brakeman` as part of the release check, and either clear the warning or record
  why it stands.
- **`Reporting` holds 15 of the sidebar's 34 destinations.** Operations has 5, Inventory 7,
  Network 7. A group with 15 children is a menu inside a menu. The likely fix is a reports
  landing page with one rail entry, which is what most applications of this size do; see the
  note under "App shell" before changing it.

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
