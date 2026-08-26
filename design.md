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

<a id="buttons"></a>
**A destructive action with no fill is `ghost_danger`, and it is `slate-600` at rest.** Rose comes
on hover and focus only. It was rose at rest, and a form with eight rows then carried eight red
marks down its edge, none of them louder than the others — the word "Remove" and the trash glyph
already say what the control does, and colour saying it a third time on every row says nothing at
all. The same argument that took the inline error message grey. Do **not** reach for `ghost` plus
`extra: "text-rose-700"`: two colour utilities in one class attribute are resolved by the cascade,
not by attribute order, and the rose loses.

### Sentence case

**Sentence case for everything a person reads**: headings, buttons, labels, table headers,
nav items, flash messages, empty states.

> New donation · Print unfulfilled picklists · Fair market value · Storage locations

Not `New Donation`, `Print Unfulfilled Picklists`, `FMV`. Proper nouns keep their capitals
(NDBN, Human Essentials, a partner's name). This is the house style across Ruby for Good and
it is the single most common review note on UI PRs here.

**That includes `uppercase`, which is how it keeps coming back.** Sentence case is about what the
reader sees, so a `text-transform` breaks the rule exactly as much as typing the capitals would.
The only `text-transform` in the stylesheet is `.data-table thead th { text-transform: none }`,
set deliberately. Uppercase also removes word shape, which is the thing you scan a column of
headings by.

**A column heading is `text-xs font-semibold text-slate-500`** and nothing else — no
`uppercase`, no `tracking-wide`. That is what `.data-table thead th` renders, and anything
outside a `<table>` that heads a column has to match it by hand: at the time of writing the only
one is the line item grid's heading row, which reintroduced the uppercase eyebrow and had to be
put back. The `uppercase` utility appears nowhere in `app/views` or `app/helpers`; if a grep
finds one, that is the regression.

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
- **An icon-only control is a `<button>`, never an anchor with `role="button"`.** A native anchor
  fires on Enter and ignores Space; the ARIA button pattern requires both, so an anchor that
  *announces* itself as a button and then ignores Space fails **WCAG 4.1.2**. `add_element_button`
  and `remove_element_button` were both built that way, and it was measured rather than reviewed:
  Enter removed a line item, Space did nothing. **axe cannot catch this** — it reads markup, not
  behaviour — so the keyboard audit and a real key press are the only things that will. Inside a
  form, `type: "button"` is not optional: a button defaults to submit.
- **Icon-only is for a repeating row action, not for a one-off.** The row gives the context the
  label would: sixteen "Remove this item" buttons down a column read as a column of removes, and
  the item beside each one says which. A single destructive action in a page header gets its
  words. That is why the line item rows are glyphs and the page actions are not.
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
- **A link inside a sentence is underlined.** Brand colour alone is not enough to distinguish it
  from the prose around it — WCAG 1.4.1, and axe reports it as `link-in-text-block`. Use
  `font-medium text-brand-700 underline hover:text-brand-800`. A link that is its own block —
  a table cell, a list item, a card row — does not need one, because there is no body text for it
  to be confused with.
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
actions use **`:ghost_danger`** — `slate-600` at rest, rose on hover and focus. Not `:ghost` with
`extra: "text-rose-700"`, which is what 27 views did and what none of them got: two colour
utilities in one class attribute are resolved by the cascade, not by attribute order. The
confirmation is what protects the user, not the colour.

`:primary` belongs in the page header, once. If a row action looks like the page's main action,
the page has as many main actions as it has rows.

**Three or more row actions collapse into a menu.** `shared/essentials/row_actions`. Five labelled
buttons made the actions column **331px** on `/distributions` — wider than Total items, Total value
and Status together, and the second-widest column in the table. Collapsed it is **60px**. This is a
named pattern rather than a convention: Carbon ships an `OverflowMenu` documented for table rows,
Salesforce Lightning calls it *row-level actions*, Polaris renders them as an `ActionList` in a
`Popover`, and GitHub, Drive, Gmail, Notion, Linear and Stripe all end a row with a kebab.

- **A visible primary only where the row does not already link to its record.** `/vendors` and
  `/requests` keep a **View**; `/distributions`, `/items` and `/purchases` do not, because their
  first cell is already a link to exactly that page — a View button beside it is two controls with
  one destination, which is what the tab-actions pass removed.
- **Always visible, never hover-revealed.** Several of the consumer apps reveal the kebab on hover.
  There is no hover on a phone, and a keyboard user cannot reach a control that does not exist yet.
- **The disclosure pattern, not the ARIA menu pattern.** A popover of links moved through with Tab.
  `popover_controller` gives Escape, focus back to the trigger, `aria-expanded` and click-outside;
  it does not do arrow-key movement, and promising `role="menu"` without that is worse than not
  promising it. The trigger takes `aria-haspopup` and a label naming the row — *"More actions for
  distribution 24"* — or a screen reader hears "button" once per row.
- **`data-popover-fixed-value="true"`.** The menu lives inside `.table-scroll`, whose
  `overflow-x: auto` forces `overflow-y` to compute to `auto` as well, so an absolutely positioned
  panel is clipped on **both** axes and the last row's menu was cut off by the bottom of the table.
  Fixed positioning is opt-in, because the account menu and date picker have no clipping ancestor
  and moving with the page is the better default.
- **`size-7`, not the 38px control height.** A row action is `sm` everywhere else; a 38px trigger
  made every distribution row 10px taller. 28px still clears WCAG 2.5.8's 24×24 floor.
- **An unavailable action stays in the menu**, disabled, with the reason as sr-only text. A form
  action gets a genuinely `disabled` `<button>` and a link action a `<span aria-disabled>` — see
  [Interaction](#interaction), and note that only a form control can be `disabled`.
- **The honest cost:** every action but the first becomes two clicks, and which one deserves to stay
  visible differs by who uses the page. A warehouse user printing picklists all afternoon will feel
  *Print* moving behind a menu.

**A row's actions are one unit and do not wrap.** `flex justify-end gap-1.5 whitespace-nowrap`,
never `flex-wrap`. Five row partials wrapped, and on a wide table the actions column gets squeezed
until the buttons stack one per line: `/distributions` had **155–171px** rows with its two visible
actions on two lines in a 114px cell, and `/items` **121px** with three on three. Not wrapping
makes the column take the width it needs and the table scroll inside `.table-scroll`, which is
what that region is for. Measured after: distributions **85–105px**, items **65–85px**, every
action on one line. Modal footers are the exception — those *should* wrap.

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
- `SELECT_CLASSES`, not `FILTER_CONTROL_CLASSES`, for a `<select>`. The browser draws the
  chevron inside the right padding, so a select needs `pr-10` where a text input needs `px-3` —
  and it needs `.select-chevron` to turn the browser's own arrow off. Seven selects in the app
  had been given the text-input constant and kept the native arrow because of it.

<a id="control-height"></a>
**Every button variant carries a border**, transparent where it is not meant to be seen. `border`
is 1px top and bottom, so without it a `:primary` is 36px next to a 38px `:secondary`. Measured
across 17 pages before the fix: 25 secondary at 38px, **16 primary and 4 ghost at 36px**. It was
invisible while headers carried enough buttons to wrap; two buttons on one row showed it at once.
`button-audit` checks the height now.

**The control height is 38px**, and it is not a Tailwind step. It falls out of `py-2` plus a
14px line box plus two 1px borders, so anything that has to sit level with an input — an icon
button beside it, a third-party widget, a grid column holding one — is `2.375rem` and not a
spacing utility. Three things in the app are that number by hand: `.select2-selection`, the line
item row's icon buttons, and the scan bar's joined button.

**select2 is restyled, not vendored as-is.** It ships a 28px-tall, 4px-radius, 16px-text control
in a `#aaa` border, and the app's is 38px, 8px and 14px in `slate-300`. Six selects across five
views use it — two single, four multiple — and beside a plain input all six read as a control
from a different application. `application.css` restyles the box, the arrow, the value's padding
and the focus ring, all **unlayered**, because the vendored stylesheet is imported unlayered and
a layered rule loses to it however specific it is. The multi-select takes `min-height`, not
`height`, because it is supposed to grow as chips are added.

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
<%= essentials_icon_tile "bi-graph-up", tone: :brand, size: :sm %>
<%= essentials_avatar_initials current_user.name %>
```

**Two sizes, named as the buttons are.** `md` (36px, `rounded-xl`) is the default and stands
beside a figure or a `text-base` heading. `sm` (28px, `rounded-lg`) is for a compact card header,
where the larger tile beside a `text-sm` heading reads as heavy. Never build one by hand: the
reports hub did, and drifted on all three of size, radius and text colour before anyone noticed.

A soft coloured tile behind an icon means "a stat or a status". A **person** is an initials
avatar instead. Keeping these disjoint is what makes either one readable at a glance, and it is
also the line `page-audit.rb` draws: a tone-coloured fixed-size box that is **not** `rounded-full`
is a tile and must come from the helper; a circle is an avatar or a numbered step badge and is
left alone.

**A tile earns its place by being different from the tile next to it.** In a row of stats or a
list of options each icon names its own item, so it is doing work. The same glyph repeated down
every row of a list is not — it gives the eye a second column of identical marks to skip and
distinguishes nothing. If every row would carry the same icon, it belongs to the card: pass
`icon:` to `shared/essentials/card` and it renders once, beside the `h2`. Both announcement
cards used to stamp a megaphone on every announcement, inside a card already titled
"Announcements".

The test is mechanical: **is the icon a literal, or does it come from the row?**
`essentials_icon_tile(stat[:icon], …)` varies per row and stays; `essentials_icon_tile("bi-megaphone", …)`
inside a loop does not and moves to the header.

The account menu's trigger in either top bar is the avatar **alone** — initials and a chevron,
no name beside it. The name is not gone, it is one layer in: the panel opens with the name, the
email and the role. A name in the bar is the one piece of text on the page that never changes,
so it competes with the page for the eye at every width and truncates at the narrow ones, and
the initials already say whose account it is. Because the avatar is `aria-hidden`, that makes
the trigger an icon-only control, so it carries the name in its own `aria-label` — `Account menu
for …` — and a screen reader is told what the initials tell everyone else.

### Cards

The surface everything sits on: white, hairline border, `rounded-2xl`, `shadow-sm`.

**That surface is `.card-surface`, and it is written in exactly one place** — a component class
in the Tailwind entry, beside `.data-table`. Never paste `rounded-2xl border border-slate-200
bg-white shadow-sm` into a template; `page-audit.rb` sweeps views, helpers and JavaScript for it
and reports every copy.

The class exists because the component is not the only thing that needs the surface, and the
other four callers should not be forced through it: `essentials_stats` builds its own container,
the admin dashboard and the partner header build `flex` stat tiles, the reports hub builds a
compact labelled `<section>`, and `shared/essentials/_disclosure` wraps a panel. None of them
wants a title/subtitle/actions header. All five were pasting the utilities, so a change to the
card reached one of six places.

**Use the component when you want a card; use the class when you only want the surface.** If you
reach for the class to avoid the component's header, that is the right call — if you reach for it
to build a second card, render the component instead.

```erb
<%= render "shared/essentials/card",
      title: "Filters",
      subtitle: "Narrow this list down.",
      actions: capture { essentials_link_button("Export", exports_path, variant: :secondary, size: :sm) },
      footer: essentials_pagination_footer(@paginated_donations),
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
`:secondary` or `:ghost`. Past three, the least-used collapse behind a menu — and **name the
menu after what is in it**. `/requests` had four, the only page in the app that did; its two
outputs became one `Export` menu. "Export" says what is inside, "More actions" only says that
something is.

The actions container carries `data-page-header="actions"` so a spec can count what is in it
without walking ancestors — and **`bin/design/button-audit.js` does**, across 27 page headers and
three roles. It has to run in a browser: half these actions are conditional on a role or on a count
being above zero, so `/requests` shows one action to an ORG_USER and two to an ORG_ADMIN. The rule
had been written here for weeks with nothing enforcing it, which is how the fourth button arrived.

**A page has one place for its main action.** If a fourth button appears, that is the signal
that something else is wrong — usually a section of the page wanting an action of its own. Do
not tuck it above a table; see the tabs rule below.

<a id="menu-button"></a>
**A menu of related actions is `shared/essentials/menu_button`.** A labelled trigger with a chevron,
`:secondary` at the normal control height, and a `role="menu"` panel — the page-level counterpart to
[`row_actions`](#row-actions), which is a kebab because a table row has no room for a word. A page
header has room, so it uses one.

```erb
<%= render "shared/essentials/menu_button", label: "Export", icon: "bi-download", items: [
      {label: "Requests as CSV", path: requests_path(format: :csv), icon: "bi-filetype-csv"},
      {label: "Unfulfilled picklists, PDF (12)", path: …, icon: "bi-printer"}
    ] %>
```

It **counts as one action** against the limit of three, which is the whole point of collapsing into
it. Both menus render their items through `shared/essentials/menu_items`, so what a menu item is —
its roles, its tones, and the difference between a disabled link and a disabled form control — has
one definition rather than two that drift.

**One item is not a menu**, and the component knows it: given a single item it renders a plain
button instead. Menu contents are usually conditional — the picklist on `/requests` only exists
while something is unfulfilled — so an organisation with requests but none outstanding would
otherwise get a menu holding one entry, which is strictly worse than the button it replaced: a click
to reach one thing, with its label hidden behind a general word.

It collapses to the **menu's** label, not the item's, and that is only safe because a menu is named
after its contents — so its name fits any one of them. It is also the verb: "Export" says what will
happen where "Requests as CSV" is a noun phrase. GitHub's Download menu does the same.

**How many items before it stops being the right control.** Two to about four closely related
outputs belong in one menu, each item naming what it produces — the content and the format, as
"Requests as CSV" and "Unfulfilled picklists, PDF (12)" do. Past that, or for anything that is not a
straight download, it belongs in the [reports hub](#reports) rather than a page header: `/reports`
already carries Distributions, Donations, Purchases, Requests, Compliance and Activity. A page
header menu is for getting *this page's* data out, not for browsing a catalogue of reports.

It is `popover-fixed-value`, so the panel is placed against the viewport and clamped to it. At 320px
a page header's actions wrap, which puts the trigger near the left edge, and a panel right-aligned
to a trigger there starts at a negative x. The overlay audit caught that at 320×640.

**A summary of a table is not a page action.** "Show product totals" on `/requests` was the fourth
button in the page header, and it does not act on the page — it summarises the rows in the card
below it. It sits on that card now, as `:secondary, size: :sm`, which is what a card action is
everywhere else. No card title with it: the page `h1` is already "Requests", and a card repeating it
says nothing.

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

**Nothing sits between a tab strip and the first row of its table except that table's own
filters.** A filter earns the space because it changes the rows underneath it; an action does
not, and an action there is the signal to use page tabs instead. A filter that lives there is
still the `filter_bar` component, and it **must apply into a frame**: a full reload re-renders
the tab strip with whichever tab the server marked selected, which throws away the tab the
person was on. `storage_locations/show` is the one instance. The item catalogue had this on
four of five tabs — a 55px strip holding one secondary button, and on two of them that button
was the page header's own "New item" a second time. It is five page tabs now: `/items`,
`/item_categories`, `/items/quantity_and_location`, `/items/inventory`, `/kits`, each with the
primary action for what it shows.

A page tab may lead somewhere that is also a destination in its own right — "Kits" is both the
fifth tab of the catalogue and a sidebar entry. When it is, the page keeps its own title rather
than borrowing the strip's, because the sidebar has to be telling the truth about where it just
sent you. Render the strip there anyway, so the tab is a way back as well as a way in.

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
rebuilds its query string from the form on every frame load. Exporting the previous filter's rows
is a worse failure than a stale table, because the file looks right and nothing on screen says
otherwise.

That controller listens on the **document** and resolves the frame when it needs it, not in
`connect()`: the form is parsed before the frame it targets, so resolving it early can return
null and leave the export link — and the announcement — silently dead.

The flash is **not** cleared when a filter applies. It was, briefly; removing 56px from above the
results moves everything below it under a cursor that is often already over a row action, and a
layout shift in response to an unrelated action is a hazard. A stale message describes something
that did happen, and it clears on the next navigation.

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

`FilterHelper` builds the controls (`filter_select`, `filter_text`, `filter_date`,
`filter_checkbox`) and gives each one a UUID-suffixed id with a matching label, so a filter
control is always named. `EssentialsUiHelper::FILTER_CONTROL_CLASSES` is the single definition
of what one looks like.

**Two of them submit under `filters[…]` and two do not, and the split is not arbitrary.**
`Filterable#class_filter` walks that hash and calls `public_send(key, value)` on the model, so
every name inside it has to be a real scope. `filter_checkbox` and `filter_date` submit a bare
param because what they carry — "include inactive", "at this date" — is not a scope, and putting
it under `filters[…]` would turn a filtered index into a `NoMethodError`.

`filter_date` is a single date, not a range: use the date range picker below when the question
is "between when and when", and this when it is "as it stood on". It takes `min:`, `max:` and
`hint:`.

The date range picker owns its own label, for the same reason. Callers used to add
`label_tag "Date Range"`, which pointed at `date_range` while the input's id was
`filters_date_range` — the label named nothing and clicking it did nothing, at all fourteen
call sites.

### Date range picker

```erb
<%= render "shared/date_range_picker" %>
```

One trigger showing the current range, opening a popover with the presets on one side and two
native `<input type="date">` fields on the other. No calendar widget and no third-party
dependency: it is built from the same `FILTER_CONTROL_CLASSES` as every other filter, so it
matches the rest of the bar by construction rather than by being re-themed.

**No Apply button.** The dates apply themselves. An Apply is a second click for something the
user has already said, and Stripe, Shopify, Linear and Notion all commit on selection; Google
Analytics is the well-known exception and the one people complain about. Three things make that
work with two fields rather than a calendar:

- **The panel stays open** while custom dates are edited, so the range can be adjusted without
  reopening it. Only choosing a preset closes it — a preset is a complete answer.
- **A 350ms debounce**, so setting From and then To costs one request, not two. That was the real
  argument for the Apply button, and it is a timing problem rather than a reason to ask twice.
- **The From/To fields stop their `change` from bubbling.** They sit inside the filter bar's form
  and the bar submits on any change reaching it, so without this, editing a date fired a query
  carrying the *previous* range and then a second with the new one. Measured: three requests
  became one.

**An end before a start is reordered, not refused.** Google Flights, Airbnb and Material's range
picker all reorder. This used to show *"The end date must be on or after the start date."* and do
nothing until the user corrected it; there is no error state left in the control.

**The trigger shows US short dates** — `6/19/2026 – 9/19/2026`. Spelled out it read
*"June 19, 2026 to September 19, 2026"*, which needed 233px inside a 223px button and was
truncated: the one thing the control exists to tell you was the thing cut off. The wire format
below is unchanged; `:date_picker_short` is display only.

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
writes two formats: `:date_picker` for the wire and `:date_picker_short` for the trigger.

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
| `.notes` | Free text of unbounded length: clipped to one line at 16rem |
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
- `essentials_error_summary` sits above the form: `role="alert"`, and names each field in a
  plain bulleted list.
- Error text on a **form field** is `slate-700` behind a `rose-600` glyph — the glyph signals and
  the sentence reads. See [required fields and validation errors](#forms-required-fields-and-validation-errors).
  `rose-700` remains the tone for error text that has no glyph beside it; `rose-600` is a border,
  a filled background, or a mark like the required asterisk.
- `required: true` sets the HTML5 `required` attribute regardless of `browser_validations`.
  Conditional validators are *not* inferred as required — mark them explicitly or not at all.
<a id="field-width"></a>
- **A field takes the width of its grid column. Narrow it only where there is a column of fields
  to narrow it inside.** Two rules from industry collide here and both are right about different
  situations. Carbon, Material, Polaris and Fluent fill the cell: the grid is the discipline, and
  a right edge lands on a line by construction. GOV.UK and USWDS ship fixed width classes
  (`govuk-input--width-10`, `--width-20`) for short values of known length, on the reasoning that
  width tells you how much is wanted, and accept a ragged right edge as the cost.

  **What decides it is whether the field has neighbours.** GOV.UK's narrow inputs sit in a column
  of stacked fields; the field above and the field below share the left edge, and that repetition
  is what makes a short width read as deliberate rather than unfinished. A control *alone* in its
  band has no such rhythm, so a short width reads as an accident.

  The line item scan bar is the worked example. It was a fixed `15rem`, sized to the 14-digit
  GTIN that is the longest barcode in common use — **138px** in Figtree at 14px. It aligned with
  nothing, and a fixed width cannot align to a fluid grid at more than one viewport: it was 106px
  short of the column at 1440 and **33px wider than it at 1024**, crossing a boundary every other
  control respects. It is on the same `gap-x-5 sm:grid-cols-2 lg:grid-cols-3` grid as the cards
  above it now and takes column one, so it lands on the storage location select's edges at every
  width. The content measurement did not go to waste — it is the check that the column is never
  *too small*: at 1024, the narrowest the grid gets, the field is 169px for 138px of barcode.

  Free text — a name, an address line, an item, a comment — has no known length and simply takes
  its column.

### Line item rows

A repeating collection of items with a quantity each — the body of "Items in this donation" and
its six siblings. **This is a table, not a stack of forms.** Every one of the seven forms that
takes line items renders one partial:

```erb
<%= render "shared/essentials/card", title: "Items in this donation", padded: false do %>
  <%= render "line_items/line_item_table", form: f, id: "donation_line_items",
        noun: "donation", object: donation_form.line_items %>
<% end %>
```

Four rules, all of which the hand-assembled version broke:

- **Label the columns once, in a heading row.** Not once per control per row. Three labels on a
  three-row form, not nine. The controls carry the same words as `aria-label`, because a control
  with no visible label still needs a name — and the heading row is `aria-hidden`, so it is not
  announced twice. Use the `:essentials_cell` / `:essentials_cell_select` wrappers: no label, no
  bottom margin, error still under the control.
- **One scan field per card, not one per row.** A barcode field belongs to the *document* being
  built, not to a line of it — Square, Zoho Inventory, Odoo and Amazon Seller all put one at the
  top of a receiving screen, and scanning appends a row or adds to the row that item is already
  on. Repeating it per row gave a ten-line donation ten barcode fields and ten "or"s.
- **The remove control is `remove_element_button`, the same one every other repeating row uses**
  — the trash glyph *and* the word, `ghost_danger`. It was icon-only here, which made this the one
  place in the app where the control had no label, while the partner request form — the same
  shape, a repeating row of item and quantity — rendered the words two screens away. Five call
  sites, one rendering. See [buttons](#buttons) for why `ghost_danger` is slate at rest.
- **The card has an empty state.** Remove the last row and the column headings go with it, because
  there are no columns left to head; `line_item_total_controller` swaps them for a `:cold_start`
  state. It offers no action, deliberately: the footer's **Add another item** is 60px below it,
  and two buttons doing one job is the thing the tab-actions pass removed.
- **The footer carries a running total.** "2 items · 36 units", from `line_item_total_controller`.
  Every inventory app has one; this card had none, so a long donation could not be checked without
  adding it up by hand.
- **No divider between rows.** A divider separates rows of *text*; between rows of *controls* it
  is redundant, because every cell already draws its own box, and it puts a second horizontal line
  between each pair. Four rows drew **7** card-wide rules and now draw **4**. Xero, Stripe and
  Shopify all draw none between editable line items. The rules that stay are the ones separating
  **bands** — under the scan bar, under the headings, above the footer — because those mark a
  change of kind. Index tables keep their row dividers: there the rows *are* text.
- **One spacing number: 20px.** `py-2.5` on the rows container and `py-2.5` on each row puts 20px
  between every pair of controls *and* 20px from either band border to the nearest one. The band
  edges must not be smaller than the gap between rows — at 12px against 20px the first row read as
  attached to the heading strip rather than as the first of a set, which is the grouping the
  divider had been papering over. Within a row, stacked below `sm`, the gap is 8px: between has to
  beat within.

The scan field and its button are **joined** — one rounded rectangle sharing a border — rather
than two controls with a gap between them. That is what keeps them the same height by
construction; as separate boxes they had drifted to 38px and 42px. The pair sits in **column one
of the same grid the cards above use**, not at a width of its own — see
[field width](#field-width).

**Below `sm` the row stacks** and the heading row disappears with it: item and the remove button
on the first line, quantity beneath. Four columns at 320px leaves the item picker **72px**, which
is not a control anyone can use, and 320 is the width [Reflow](#responsive) is defined at — the
stack takes it to 196px. Placement is explicit (`col-start-*`, `row-start-*`), because auto-flow
puts the remove button under the item rather than beside it. Each cell then carries **its own
label, `sm:hidden`**, since at that width there is no heading row to name it; the `aria-label`
stays on the control either way, which is what names it when the visible label is `display: none`.

**A camera scanner renders into its own viewport, never into the button that starts it.** Quagga
is given a `target` element and fills it with a `<video>` and a `<canvas>`; it used to be handed
the 38px button, which pushed the glyph 339px out of it, and on a successful read the code called
`.empty()` on that same button and deleted the glyph for good. Each scanner is a
`[data-barcode-scan]` region holding its input, its button and a `[data-barcode-viewport]`, and
the button toggles with `aria-expanded`. **Nothing is wired by id**: three partials carried
`id="barcode-scanner-btn"`, a donation form renders two of them, and the dialog's camera therefore
drew its picture inside the scan bar's button. axe will not catch that — `duplicate-id` was
deprecated in axe-core 4.9.

Two traps, both of which produced a defect here:

- **A `MutationObserver` must not observe what its callback writes.** Assigning `textContent`
  replaces a text node, which is a childList mutation like any other, so a summary inside the
  observed subtree is an unbroken loop. The total observes the *rows* container and guards the
  write; the first version did neither and hung the tab on the first scan.
- **`.val()` and `.trigger()` are jQuery's, and a native listener does not see either.** jQuery
  sets the property and runs its own handler list. Anything bound with `addEventListener` — every
  Stimulus controller — needs a real `dispatchEvent`, which is why the running total sat one scan
  behind the quantity it was adding up.

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

## Copy

The words are part of the design system. `bin/design/copy-audit.rb` checks the mechanical half of
what follows; the rest is judgement.

**Write the label, not the request.** No "please". GOV.UK, Mailchimp and Shopify all say the same
thing and the reasoning is the same in each: in an instruction the reader has no choice about it
is not really a courtesy, and it is a word on every screen. "Check your spam filter", not "Please
check your spam filter". Forty-seven instances went in one pass and none of them read worse for it.

**A link says where it goes** — WCAG 2.4.4. "Click here", "this link", "read more" and "here" are
all the same failure: a screen reader can list every link on a page, and out of context those say
nothing. Name the destination: "NDBN member spreadsheet", not "this link".

  Where the visible label has to stay short — a compact card, a dense row — give the link an
  `aria-label` that *extends* the visible words rather than replacing them. `More info` with
  `aria-label="More info about the announcement of 22 August"` satisfies 2.4.4 and also
  **WCAG 2.5.3 Label in Name**, which requires the visible text to be part of the accessible
  name. Replacing the words outright breaks 2.5.3 and voice control with it.

**No instruction depends on where something is** — WCAG 1.3.3. "The list above", "the link below",
"the button on the right" and "the green button" all fail for anyone who cannot see the layout,
and they go stale the moment the layout reflows — which on this app is at every breakpoint. Say
what the thing is called: "Confirm that this is what you want to distribute", not "confirm that
the list above is".

**Gendered and ableist wording.** No `he/she`, `s/he`, `chairman`, `manpower`; no `crazy`,
`insane`, `lame`, `dummy`, `sanity check`, or `blind to`. The app was already clean on both when
first audited — the value of the check is that it stays that way.

**Sentence case, and no shouting.** All-capital words are read out letter by letter by some screen
readers, so emphasis is `font-semibold`, not `TEXT LIKE THIS`. Acronyms are fine and the audit
keeps a list of the real ones — `FPL`, `NDBN`, `CSV`, `GTIN`. Adding a genuine one to `ACRONYMS`
is the right fix; rewording around it is not.

**Buttons take a verb**, and the verb is what will happen: "Save", "Add another item", "Remove
this item". Not "OK", not "Submit".

<a id="subtitles"></a>
**A subtitle says something the title cannot.** "Requests" over "Essentials requested by partner
agencies" is a heading and its own dictionary definition: anyone who can read the title already has
it. Measured before this rule existed — **all 40 index pages carried a subtitle and about 20 defined
their own heading**.

The test: read the title, then the subtitle. If the subtitle told you nothing you did not already
have, it is filler. By page kind:

| Page | The subtitle says |
| --- | --- |
| **Index** | What you do here, verb-led. "Review what partners have asked for. Fulfill a request to turn it into a distribution." |
| **Show** | Which record this is — source and date, name, location and status. **Twelve already did this**, and none changed. |
| **New and edit** | What submitting will do. "Record essentials coming in to X." |

**Never the scope on an index page.** It is the obvious thing to reach for, and design.md says the
opposite for a *card* — "the title names the thing; the subtitle states the scope". A page is
different because the [pagination line](#pagination) already says "Showing 1–15 of 119 requests" on
every one of them. Two places saying overlapping things is worse than either alone, which is the
same call that removed the `<tfoot>` totals from `/distributions`.

**Where the noun is genuinely jargon, the sentence carries the gloss *and* the action** rather than
only the gloss: "Items bundled to go out as one. Allocate a kit to change how many you have." This
app is run by volunteers at 200+ non-profits, and "kit", "product drive", "inventory audit" and
"base item" are not words anyone arrives knowing. Deleting the only in-place explanation to save a
line is a false economy.

**A subtitle that names an action has to be true.** Writing these found two of my own drafts were
not: "what each of them is allowed to do" for `/users`, whose table is only Name and Email, and a
claim about vendors being required before a purchase. Check the view before describing it — six of
the seven claims in these sentences were verified against the code that implements them, and the
seventh was cut.

Eight are left as they were, because they already passed: `/reports` says how the reports work,
`/events` says the ordering, `/admin/account_requests` says the scope of *both* halves, the dashboard
says the purpose, and the four admin lists say which population they cover — something their
one-word titles cannot.

### What the audit taught, twice

`copy-audit.rb` reads **copy**, not source, and it knows a **link** from a **heading**. Both cost
a rewrite, and both were caught by its probe table rather than by review:

- Grepping the repository cannot tell a sentence from an identifier. The first `he/she` pattern
  matched `render "organizations/header"` — "organization[s/he]ader" contains it.
- WCAG 2.4.4 is about link labels and nothing else. Run against all copy, the vague-text check
  reported all sixteen cards titled "Details", which are headings and entirely correct.

A third: in a Ruby `/x` regex, literal spaces are stripped, so the first `VAGUE_LINK` was quietly
looking for `clickhere`. Every multi-word branch now uses `\s+`, and every branch has a probe.

## Responsive

Tailwind's breakpoints, unchanged: `sm` 640, `md` 768, `lg` 1024, `xl` 1280, `2xl` 1536. The
shell switches at **`lg`** — below it the sidebar is an off-canvas drawer, above it a sticky
column.

Audit with `pw bin/design/responsive-audit.js`, which visits every screen at **320, 375, 639,
641, 767, 769, 1023, 1025, 1280 and 1440**, plus a landscape phone at **740×360**. 320 is not
arbitrary: WCAG 1.4.10 Reflow is defined at 320 CSS px, which is also 1280px at 400% zoom.

**The widths straddle each breakpoint.** 639 and 641 are different layouts and only one of them
gets looked at by hand — a layout that breaks usually breaks at the switch, not in the middle of
a range.

Beyond the page geometry it checks the things that make a squeezed layout unusable rather than
merely ugly: content clipped with no ellipsis to say so, a nav drawer that cannot be opened
below `lg`, and fixed chrome covering more than half a short viewport. `overlay-audit.js` opens
every dialog and popover at **320×640 as well as 1360×900** — an overlay that fits on a desktop
tells you nothing about a phone, and that is where a 26rem panel runs out of room.

### The document never scrolls sideways

`html { overflow-x: clip }`, in `@layer base`. A wide data table belongs in `.table-scroll` —
1.4.10 exempts content needing two-dimensional layout, so the *table* may scroll — but the page
must not.

That rule is load-bearing, and it is not what you would guess. **Chrome counts content clipped
inside a scroll container towards the root's scrollable overflow**, so a table in a working
`overflow-x: auto` container, inside an ancestor with `overflow: hidden`, still let `/items` be
swiped 821px sideways at 320px: the heading went from `left: 16` to `left: -805` and the user
was left looking at blank space. `min-width: 0` on the flex ancestors does not fix it; only
clipping the root does.

`clip` and not `hidden`: `hidden` makes the root a scroll container, which can break
`position: sticky` descendants, and the sidebar is `lg:sticky`. `overflow-x: hidden` is left in
front of it as the fallback for Safari below 16.

### How to measure it

**Swipe, do not call `scrollTo`.** They answer different questions, and the difference is why
this shipped:

| Measure | Says |
| --- | --- |
| `document.documentElement.scrollWidth` | Counts clipped content no user can reach. Over-reports. |
| `document.body.scrollWidth` | Stays at the viewport width even when the page does scroll. Under-reports. |
| `window.scrollTo(9999, 0)` | Scrolls past `overflow-x: clip`, which a gesture cannot. Over-reports. |
| **A wheel gesture, then read an element's `left`** | What a person on a phone gets. |

### Tap targets

WCAG 2.5.8 (AA) is **24×24 CSS px** — but with the exceptions, or the check is noise. A first
pass reported 28 failures on the dashboard, every one a date link in a table cell that passes on
spacing. The audit implements *inline* and *spacing* (a 24px circle centred on the target
touching no other target).

Controls that exist only on touch get the **industry 44×44**, not the 24px floor: the drawer's
open and close buttons are `size-11`. They were `p-1` and `p-2`, giving 22×32 and 32×32.

### Row actions are not Turbo's

`essentials_action_button` renders `data-turbo="false"`, so the browser submits the form itself.

Row actions are `button_to` forms and the tables sit inside a results turbo-frame. Turbo's
`elementIsNavigatable` returns true for anything inside a frame **even with Drive off**, which
it is app-wide here — so Turbo intercepted the submission, fetched the redirect and had to
promote it to a top-level visit because the frame carries `target="_top"`. About half the time
that promotion did nothing: the confirm was accepted, the server handled the request, and the
page never changed.

A row action is a whole-page navigation ending in a redirect and a flash, not a frame update.
**Anything that redirects out of a frame should opt out of Turbo rather than rely on
`target="_top"` to rescue it.**

### Keyboard

Audit with `pw bin/design/keyboard-audit.js`, at 1280 **and** at 375 — the two are different
layouts and the drawer bug below only exists at one of them.

**An off-canvas panel must be `inert` when it is closed.** The sidebar below `lg` is moved out of
sight with `-translate-x-full`, which hides it from the eye and from nobody else: closed, its 27
links stayed in the tab order, so a keyboard user tabbed from "Skip to main content" through the
entire navigation — invisible, with no way to know where focus had gone — before reaching the
page. `display: none` would remove it properly but would also break the slide. `inert` takes the
subtree out of the tab order and the accessibility tree and leaves the transform alone.

`shell_controller` keeps it in step: set on close, cleared on open, and **recomputed on resize**,
because at `lg` the sidebar is a visible column and must not be inert whatever the drawer's last
state was.

**A scroll container needs `tabindex="0"`.** `.table-scroll` can be scrolled with a mouse and,
without a tab stop, by nothing else — axe's `scrollable-region-focusable`, WCAG 2.1.1. It only
showed up on the historical trend tables because every other table in the app contains links,
which give the region a way in by accident. A focusable region also needs a name and a role, and
a visible focus ring like anything else that takes focus.

**Decoration that happens to be clickable is not a control.** The drawer scrim and a `<dialog>`'s
backdrop both close on click and are correctly *not* focusable: the scrim is `aria-hidden`, and
both actions are also on Escape and on a real close button. Adding a tab stop would put an
unnamed one in the way of everyone.

**Never use a positive `tabindex`.** It takes an element out of document order and puts it in
front of everything without one. The audit fails on any.

### select2 names nothing it builds

select2 hides the `<select>` and builds a combobox, a value display and a search input beside it.
None of them inherits the original's accessible name, and the combobox's own `aria-labelledby`
points at its value container — empty until something is chosen, so the control has no name at
all.

`utils/select2_accessibility.js` names all three. It lives in a util rather than in
`select2_controller` because **select2 is initialised in two places**: the fix lived in the
controller for a while and the select on `/admin/users/new` is set up by `double_select_controller`
instead, so it kept the exact fault the fix was written for.

### Forms: required fields and validation errors

Audit with `pw bin/design/form-validation-audit.js`, which opens every `new` form, reads how its
required fields are marked, submits it empty and reads what came back.

**Required is stated two ways, and both come from the wrapper.**

| | Where | Who it is for |
| --- | --- | --- |
| a **red asterisk** — `<abbr class="required-marker" title="required">*</abbr>` | in the label | sighted users |
| `aria-required="true"` | on the input | screen readers |

**The marker is `rose-600` and carries `text-decoration: none`, and the second half matters as
much as the first.** Every browser underlines `abbr[title]` with a dotted line, so for a year the
marker rendered as a slate-700 asterisk with three dots under it — neither red, nor plainly an
asterisk. The class comes from the `simple_form.*.yml` `required.html` key rather than an
attribute selector, because the `title` is localised and a marker that only turns red in English
is worse than one that never does.

**There is no legend explaining the asterisk.** There was — "Fields marked * are required.",
rendered by `essentials_form_for` and CSS-hidden on forms with nothing required — and it was
removed: a red asterisk is the convention, and a line restating it cost ~32px at the top of every
form's card. This reverses an earlier decision taken for WCAG 3.3.2; the reasoning both ways is in
[design-decisions.md](docs/design-decisions.md). Nothing programmatic changed — `abbr@title` and
`aria-required` both remain.

**Do not write an asterisk into label text.** A red one means required; a black one written by
hand means something the reader has to guess at. Four labels on the product drive participant
form used to do this for conditionally-required fields, and say the condition in words as well —
the words stayed and the asterisks went.

`aria-required` is added by `EssentialsInputAria` rather than by simple_form's `html5` component,
which derives `required` from `SimpleForm.browser_validations` — off here, deliberately, because
the server validates and a browser bubble competing with a rendered error is two answers to one
question. Turning it off also removed the only programmatic signal; this puts it back without
the browser's UI.

**A radio or checkbox group is marked on its `<legend>`, not on each option.** The group is what
is required. Conditionally required fields — "business or contact name required" — say so in
words and carry no `aria-required`, because none of them is required on its own.

**An error belongs to its field, not only to a summary.**

- `aria-invalid="true"` on the input, from simple_form's `html5` component.
- `aria-describedby` pointing at the message, from `EssentialsInputAria`. The message text is
  wrapped in a span with an id, because the `<p>` the wrapper builds cannot take a per-field one.
- `essentials_error_summary` above the form, listing every failure in one place.
- **The summary's items are plain text, not links.** They were anchors to each field once --
  the GOV.UK pattern -- and inside a red box they read as blue underlined links, a third colour
  in a component that already has two. Two rules were being broken at once: the underline,
  because [Interaction](#interaction) says a link that is its own block takes none, and the
  tone, because brand blue on a danger surface points at nothing the reader can act on. A plain
  bulleted list under a bold line is also what Polaris, Carbon and Atlassian show. The jump is
  not missed: every message is repeated at its own field and tied to the input by
  `aria-describedby`, so the summary says **what** is wrong and the field says **where**.
- **The glyph sits in its own column, and the heading and list share the next**, so the bullets
  line up under the heading's text instead of under the glyph. The alignment is structural --
  a flex row -- rather than left padding measured against the icon, which is a number that goes
  stale the moment the type scale moves.
- The inline message is **slate-700 body text behind a `rose-600` glyph**, from `.field-error`.
  The glyph is the signal and the sentence is the words — which is what lets the sentence be
  slate rather than rose. It reads better (10.35:1 on white against rose-700's 6.29:1) and a
  form with six problems does not become six lines of red. It is still distinct from a hint in
  the same slot: the hint is slate-500 with no glyph.
- **Where the glyph sits on white it gets a `rose-50` chip; on a tinted surface it does not.**
  The inline error is on the card, so its glyph is a 16px rounded chip. The summary sits on
  `rose-50` already, and a `rose-50` tile on a `rose-50` surface is invisible — the same reason
  [Flash messages](#flash-messages) says a message bar gets a plain glyph and never a tile.
- **The summary's words are slate too**: `slate-900` heading, `slate-700` items, on the `rose-50`
  surface inside a `rose-200` border. The frame and the glyph carry the danger; colouring the
  sentences as well is the same signal three times.

**One failure, one alert. The summary is the convention; a flash is the fallback.**

A validation failure gets the error summary and the inline messages, and nothing else. It used
to get a flash as well, on **18 forms** — two `role="alert"` regions for one event, announced
twice and disagreeing about what to say. The summary said "Storage location must exist"; the
flash said `storage_location: must exist` on `/adjustments`, and "Something didn't work quite
right -- try again?" on eight others.

Use `flash_error_unless_summarised(record, message)` rather than `flash.now[:error] =` in any
action that re-renders a form. It sets the flash only when the record has no errors, which is
the case a flash is genuinely for: a service raised, or a business rule failed without putting
anything on the record — `can_deactivate?` on an item, an inventory shortfall on a distribution.
Operational failure gets the flash; validation failure gets the summary; never both.

**Never render `f.input` with a block containing `f.input_field`.** It renders the label and then
the block, so the field never goes through the input pipeline: no wrapper classes, no
`aria-required`, no `aria-invalid`, no `aria-describedby`. It has been found three times — a
checkbox on the admin partner editor, a select on the account request form, and both fields of
the shared admin user partial, where the label said "Name *" and the input said nothing.

**On failure, re-render the record that failed — not a new one built from the same params.**
Rebuilding loses the errors, so every field comes back clean and the only sign of trouble is a
sentence at the top. `items`, `kits` and `admin/users` each did this.

### Callouts

A notice that belongs to the **page** rather than to the request. The flash says "that worked";
a callout says "this is how things are here" — the purchase is too old to edit, the kit cannot
be recomposed once saved, this cannot be undone. It is rendered on every load, for as long as
the condition holds.

```erb
<%= render "shared/essentials/callout", tone: :warning do %>
  <p class="font-semibold">This cannot be undone.</p>
  <p class="mt-1">You are cancelling the request made for …</p>
<% end %>
```

Locals: `tone` (`:info`, `:success`, `:warning`, `:danger`), `title`, `role`, `icon`,
`wrapper_class`, `callout_id`, `data`.

Tint, border and glyph come from `FLASH_STYLES`, the same map the flash strip uses, so the two
cannot drift into different shades of amber. The role follows the same rule — `alert` for
warning and danger, `status` otherwise — and `role: nil` is honoured for a callout that is
plain page furniture and wants no live region at all.

**`wrapper_class` is for the margin only.** A callout does not know where it sits, so spacing
stays with the page that places it.

Before this existed there were 21 copies of the same twelve-class string across 20 files, each
with its own margin baked in and no two agreeing on the role.

**Two traps, both of which bit while extracting it.**

Write the preamble with `local_assigns`, never `defined?()`. A partial that is rendered
somewhere with `role:` keeps `role` *defined* at the call sites that do not pass it — defined
and `nil` — so `defined?(role) ? role : default` silently drops the default. Every callout that
relied on it lost its `role` attribute, and nothing failed.

Do not put ERB tags inside an ERB comment. `<%# … %>` ends at the first `%>`, so an example
`<%= render … %>` in the documentation block terminates the comment and the rest of the file
becomes markup. The same mistake had already been made once in `_pagination.html.erb`.

### Disclosures

A card whose body opens and closes — the FAQ lists, and the partner profile accordion.

```erb
<%= render "shared/essentials/disclosure", panel_id: "question-1", title: q.title do %>
  <%= q.answer %>
<% end %>
```

Locals: `panel_id` and `title` are required; `icon`, `badge`, `actions`, `open`, `heading`.

The trigger is a real `<button>` carrying `aria-expanded` and `aria-controls`, never an anchor
with a fragment `href`: it toggles content in place rather than navigating. `disclosure_controller`
toggles `hidden` and rotates whatever carries `data-disclosure-chevron`.

**`actions` render beside the trigger, never inside it.** A link inside a button is invalid, and
a screen reader announces the whole thing as one control. The admin questions list had its Edit
and Delete buttons next to a trigger that was itself a button, in a shared padded row; the
component keeps that arrangement and makes it the only one available.

**Pass `heading:` when the disclosures form a set.** The partner profile accordion uses
`heading: "h2"`, which is what makes eleven collapsed sections navigable by heading rather than
by tabbing through eleven buttons. A one-off disclosure does not need one.

Three copies of this markup existed before it, and they had drifted: only one wrapped its
trigger in a heading, and only one put its actions outside the button.

<a id="a-scrolling-table-says-so"></a>
**A scrolling table says so.** A wide table is allowed to scroll — [Reflow](#responsive) exempts
data tables — but it has to admit it. Measured on `/distributions` before this existed: **486px of
columns off screen**, the scrollbar an overlay one taking **0px** of height, and no fade, shadow or
hint of any kind. The only signifier was `aria-label="Table, scrollable"`.

That gap is instructive about the audits. The region was built for the keyboard and the screen
reader and serves both — a focusable `role="region"` with a name — and **that is exactly what the
audits check**. An overlay scrollbar is invisible to a computed-style test, so nothing flagged the
one group left out: people looking at it with a mouse.

Two things are needed, and they answer different questions. **The edge signal says there is more;
the rail is the part you can act on.** Neither substitutes for the other.

- **A shadow at whichever edge has content behind it.** `table_scroll_controller` puts `start`,
  `end`, both or neither in `data-overflow`; the CSS draws what it names. **Directional on purpose**:
  a signal on both edges always is decoration, one only where content is hidden is information — a
  table that fits gets none.
- **A rail**: a real horizontal scroll control, described below.

<a id="a-white-fade-is-not-a-signal"></a>
**Do not fade to white on a white table.** The edge signal was a white gradient to begin with, which
is the standard trick for text running out of a box and does nothing whatever here. Screenshotting
the 68px strip on `/distributions` with it on and off and diffing the painted pixels:

| Edge signal | Max change (of 255) | Area of table tinted | Text erased | |
| --- | --- | --- | --- | --- |
| White fade | ~1 | — | **26%** | imperceptible, and damaging |
| **Ant Design's 6% over 10px** | **10.0** | **6.6%** | 0% | **what is built** |
| Light, 12% | 18.9 | 10.6% | 0% | visible |
| Hairline rule | 43.4 | 1.3% | 0% | visible, but says "edge of card" |
| Inset shadow, 40% | 62.1 | **28.5%** | 0% | a vignette |

The white version was invisible, and its only measurable effect was **erasing a quarter of the text
it lay over**. Its replacement went too far the other way — 40% over 64px tinted **28.5% of the
visible table** and read as a vignette. It is **Ant Design's production value** now,
`inset -10px 0 8px -8px rgb(5 5 5 / 0.06)`, from the most-used table component on the web.

Two lessons, and the second cost more than the first:

- **A scrim only works against content darker than the scrim.** Fading to white is right for dark
  text running out of a container and wrong for a white table.
- **Do not judge a visual signal by its area mean.** The first pass ranked these by average
  luminance change over a 68px strip, which rewards a broad smear and punishes a crisp line — it
  scored the hairline 1.83 and called it *imperceptible*, when by sharpest local step it is **43.4**,
  among the most visible options there is. That bad metric is why the heaviest option won.

<a id="the-rail"></a>
**The rail.** An edge shadow cannot say *you can move*, and the platform will not say it either:
its scrollbar is an **overlay taking 0px** — painted only *while* a gesture is under way, so it can
only ever confirm scrolling after you have guessed at it — and even a visible one sits at the bottom
of the *table*, which on **five of the seven** overflowing tables is below the fold: 296px below on
`/distributions`. Ant Design ships this as `<Table sticky />`; Confluence and Jira both float one.

- **`position: fixed`, not `sticky`.** `section.card-surface` is `overflow: hidden`, which makes it
  the sticky container — a probe rail inside it did not track the viewport. Same reason `popover`
  grew a `fixed` value.
- **It rides the fold, then settles *below* the table.** Not over it: at `bottom - height` the rail
  overlaid the last row and, being a control, took the pointer with it — the hover on the bottom
  row's comment cell went to the rail and the tooltip never opened. Three passing specs caught that.
  The card reserves a strip (`[data-railed]`) so at rest it covers nothing.
- **`aria-hidden`, exactly as a native scrollbar is.** The region is already a focusable named
  `role="region"` that the arrow keys scroll, so a focusable rail would be a second tab stop per
  table duplicating a path that already works and is already announced. This is the pointer
  affordance that was missing, and nothing else.
- **The track is the target, 24px tall** for [2.5.8](#target-size); the bar you see is 6px of it.
- **Injected by the controller, not written into 66 views**, and removed again when a table fits or
  goes away.

A styled native scrollbar is a **bonus and not a signal**: `::-webkit-scrollbar` makes Chrome and
Safari draw one that takes real space, Firefox ignores it, and Chrome ignores the pseudo-element
entirely on any element that also sets `scrollbar-width`. **No** combination of
`--disable-features=OverlayScrollbar,FluentOverlayScrollbar,FluentScrollbar` makes headless Chromium
141 reserve a single pixel, so it cannot be verified here at all.

<a id="never-fade-a-frozen-column"></a>
**Never fade a frozen column.** The first version of the fade drew it at the container's left edge,
which is where `.pin-col` sits. That is wrong twice over: it dims a column that is *not moving*, and
it obscures the one column pinning exists to keep readable. Sampling the painted pixels of the ID
cell on `/distributions` at 4×, the fade lifted the darkest ink from **69 to 144** — **9.59:1 down
to 3.19:1** against white, which fails [1.4.3](#contrast). A column-by-column profile put **19 of
the 26 inked columns** under it. **Six of the seven tables that overflow have a frozen column**;
only `/items` does not.

So the start of the scroll is marked two different ways, and the controller writes `data-pinned` on
the region to say which applies:

So the start-of-scroll shadow **begins where the frozen column ends** rather than on top of it. The
controller measures that column and sets `--pin-width` on the wrapper; it is `0` where nothing is
frozen, and the same rule serves both cases.

<a id="a-box-shadow-on-a-td-never-paints"></a>
**A `box-shadow` on a `td` is never painted here, so do not reach for one.** `.data-table` is
`border-collapse: collapse`, and under it Chrome does not draw a cell's box-shadow at all. Verified
with a solid red 40px shadow: **0%** of its pixels appeared on the cell, against **50.9%** on a
control `div`.

This is worth knowing because it is silent. The first fix for the fade-over-frozen-column defect put
a shadow on `.pin-col`, and **it drew nothing for as long as it shipped** — as did the
`1px 0 0` hairline that had been the column's divider since it was written. The spec covering it
passed throughout, because it read `getComputedStyle().boxShadow`, which reports the declared value
whether or not a single pixel changes. So:

- the frozen column's divider is a **`border-right`**, which paints under `border-collapse`;
- the boundary shadow lives on the **wrapper**, offset by `--pin-width` — which is Ant Design's
  arrangement, and the reason they use a pseudo-element for it too.

The controller still supplies `data-pinned` because CSS cannot work it out — **`:has()` may not be
nested**, so "a div whose `.table-scroll` child contains a `.pin-col`" is unwriteable.

**axe reported no violations across all 156 pages while this was live.** It computes contrast from
declared colours, so a gradient painted on top by a pseudo-element is invisible to it. Painted
pixels are the only way to check a contrast question involving an overlay.

Three things about how it is built:

- **The fade is on the *parent*, via `:has()`**, because a pseudo-element on the scroller scrolls
  away with the content — the usual way this gets built wrong. Every `.table-scroll` sits directly
  inside a card's body div, so the parent is a reliable anchor and none of the **66** regions needed
  a wrapper adding by hand.
- **`pointer-events: none`, always.** It is decoration over the rightmost column, which on these
  tables is the actions menu. Hit-tested: the trigger and the pinned cell's link are both reachable
  through it.
- **One controller on the shell, not 66 attributes in views.** `scroll` does not bubble but it does
  capture, so a single listener on the root hears every region, and a table arriving in a Turbo
  frame is picked up without the view knowing the controller exists.

A background-gradient version needs no JavaScript — the `background-attachment: local` trick — and
does not work here: the table's rows are opaque white and paint straight over it.

<a id="a-narrow-table-stops-being-a-table"></a>
**A narrow table stops being a table.** Below **640px of card** a `.data-table` becomes a list of
labelled fields: one field column below 416px, two above it. `table_stack_controller` puts the count
in `data-stack` and the CSS does the rest.

The Reflow exemption above is *permission, not advice.* Measured before this existed: **all fifteen
tables scrolled sideways at 320px and at 375**, thirteen at 640. The worst hid **80% of its width** —
`/distributions` needs 1,638px and had 320; on `/purchases` you could see a fifth of the table. The
design system was also contradicting itself, since the [line item row](#line-item-rows) already
stacked below `sm` with a label per cell, for the recorded reason that "four columns at 320px leaves
the item picker 72px, which is not a control anyone can use".

| Card width | Layout |
| --- | --- |
| below 416px | Stacked, **one** field column |
| 416–640px | Stacked, **two** field columns |
| 640px and up | A table, scrolling sideways if it must |

**The threshold is the card's width, not the viewport's.** Measured on `/purchases`: at a **1023px**
viewport the card is **973px**; at **1024px** it is **702px**, because that is where the sidebar
appears. A viewport breakpoint at `lg` would return the table to table form exactly where it has
least room. 640 was chosen so the behaviour is also monotonic in the viewport — a threshold of 704
would have stacked a 1024px viewport while leaving 768 a table.

Four things this needs, and the last two are the ones this pattern is usually built without:

- **The identifying column is the card's title.** `.pin-col` loses its label, its stickiness and its
  shadow, and goes up to 16px. It carries no `font-weight`: the views put `font-medium` on that cell,
  and a utility beats a rule in `@layer components` whatever its specificity, so a `font-weight`
  there would sit in the stylesheet doing nothing.
- **The row's actions sit on the title line.** The actions cell has no heading to borrow — it is an
  `sr-only` span — so the controller finds it and marks it `.cell-actions` rather than guessing by
  position.
- **The labels come from `<thead>`, by column index, into a real element.** Not `data-label` and
  `::before`: hand-written attributes would mean **299 headings across 71 views** kept in step
  forever, and generated content is not reliably announced. `.cell-label` is `display: none` until
  the table stacks.
- **The table's semantics are restored explicitly.** A browser stops exposing rows and cells as a
  table the moment `display` is not `table`, and `thead` is `display: none` here, so a screen reader
  would be left with unlabelled text in no structure. `role="table"`, `rowgroup`, `row`,
  `columnheader` and `cell` are set on every table, always — redundant while it is a table and
  load-bearing while it is not, and there is no way to apply a role conditionally.

**It is driven by an attribute, not a `@container` query**, which would have been tidier.
`container-type: inline-size` computes to `contain: layout`, which makes the element a containing
block for **fixed** descendants — and the [row action menus](#row-actions) are fixed precisely to
escape this card. Every one of them would have been positioned against the wrong box.

**And it is a long page.** `/purchases` at 320px goes from 1,448px to **7,614px**. That is the
trade: down a page you can read, rather than sideways through one you cannot. If it becomes too much,
the alternative already measured is folding the trailing fields behind a per-row disclosure, which
was 37% shorter — see `docs/mockups/table-stacking.html`.

<a id="table-rows-are-one-line"></a>
**A table row is one line — while it is still a table.** `.data-table td` is `nowrap`. A wide table
can have short rows or fit the screen, not both, and every system that ships data tables picks the
short row — Carbon, Material, Stripe and Linear all scroll sideways instead. A table is read *down* a
column, and a ragged row height breaks that; a sideways scroll is a deliberate act you take once.
**WCAG 1.4.10 Reflow exempts data tables** from the no-sideways-scroll rule for this reason, and a
table sits in a focusable `.table-scroll` region. Measured: `/distributions` went **1,339px tall with
three row heights to 943px with one**, `/purchases` 1,111 to 783.

None of that holds once the container is too narrow to hold columns at all — see
[a narrow table stops being a table](#a-narrow-table-stops-being-a-table). Below 640px of card the
`nowrap`, the width caps and the ellipsis are all switched off, because every one of them exists to
keep *columns* in order and there are no columns left.

`td` only — measured, adding `th` changes nothing, because these columns are sized by their content
rather than their headings, and leaving a heading free to wrap stops a long one widening a column
by itself.

Three classes go with it, and each exists because the rule alone is not enough:

- **`.wrap`** — the escape hatch, for a cell holding a *list* or a paragraph rather than a value.
  `/item_categories` renders a `<ul>` of item links in a cell, and a list on one line is unusable.
  Without the hatch the next person meets the rule as an obstacle and reaches for an inline style.
- **`.name`** — a **18rem** cap on a column holding a name. `nowrap` alone hands the layout to
  whoever typed the longest value: one 72-character partner name took that column from 263px to
  **493px** and dropped the columns visible without scrolling from **8 to 6**, the first to go being
  Total value. The cap is **measured, not chosen** — the longest values in the database are a
  32-character partner and a 36-character item, about 263px, so it is inert on everything that
  exists today and engages only on outliers. It is a *width*, not a character count: in
  proportional type "Illinois" and "Warehouse" are both nine characters and 12px apart.
- **`.pin-col`** — the column that says which row you are on, pinned with `position: sticky` so a
  sideways scroll does not cost you it. Without it the partner cell sits at **−542px** once
  `/distributions` is scrolled right. Excel, AG Grid and Carbon all pin the identifying column.
  `background-color: inherit`, so the cell keeps whatever the row is doing — hover, the highlight on
  a just-created record, zebra striping — instead of showing a white stripe through it.

Anything clipped by `.name` or `.notes` is revealed by `clipped_text_controller` on hover and
focus, so capping costs the reader nothing. **The ellipsis is the affordance — the cursor does not
change.** `cursor: help` was tried and removed: `help` means "there is an explanation of this", and
a name whose end is cut off is not a thing needing explanation but a thing needing reading. It put
a question mark under the pointer over a partner's name. Carbon, Ant Design and AG Grid all leave
the cursor alone on truncated text.

A clipped cell takes focus, so it gets the app's ring — keyed on `td[data-clipped]`, **not** on a
column class. While that selector said `.notes`, a capped `.name` cell was focusable with the
browser's default `1px` black outline instead of the brand ring, which is the same failure as
scoping the controller by class and is worth checking for together. That controller keys on **any** cell that overflows,
not on a list of column classes: `scrollWidth > clientWidth` *is* the property, since a wrapping
cell grows downwards and an uncapped `nowrap` cell grows sideways. It was scoped to `.notes` at
first, which meant capping a second kind of column silently produced text nobody could read.

<a id="long-text-in-a-table"></a>
**Free text in a column gets `.notes`.** A comment, a note, a reason, an address — anything a
person types with no length limit. The cell sets the row height to whatever was typed, and a
table's whole value is that rows are comparable at a glance: `/purchases` measured rows of
**145–245px** against a normal 45px, fourteen of them making a **2,711px** table. With `.notes`
that table is **1,111px** and the rows are one height.

Every design system says the same. Carbon: truncate, full value on the detail page. Material,
Salesforce (`slds-truncate`), Atlassian, Stripe, Linear and GitHub all clip to one line; Polaris
and Notion allow two. Nobody lets the cell grow. Two lines was the near miss here — it gives the
column two row heights, which is the original problem in miniature.

Three things about it:

- **The text is not lost, and that is what makes clipping safe.** CSS clipping leaves the whole
  string in the DOM, so a screen reader reads all of it, and every row carrying one has a **View**
  action to a page that shows it in full.
- **A clipped cell reveals its text on hover and focus**, from `clipped_text_controller`. This is
  the second half of the pattern and the systems ship both: Carbon has a documented tooltip for
  truncated table text, Ant Design pairs `ellipsis` with a Tooltip, AG Grid has `tooltipField`.
  Three things about ours:
  - **Only where the text is actually clipped**, from `scrollWidth > clientWidth` per cell. A
    tooltip repeating text you can already read is noise, and only clipped cells take a
    `tabindex`, so a table of short comments adds no tab stops — `/adjustments` has 42 notes cells
    and 0 of either.
  - **The bubble is `aria-hidden` and the cell gets no `aria-describedby`.** The whole string is
    already in the DOM and has already been read; describing the cell with a copy of its own text
    would announce it twice, which is the main fault of `title` and no better for being ours.
  - **WCAG 1.4.13**: dismissible with Escape, hoverable — you can move onto the bubble to read or
    select it — and persistent. A `title` is none of those and shows nothing on keyboard focus,
    which is why this is a controller. Touch has no hover; the detail page is the answer there.

  **Not a general tooltip component.** It reveals text that is present and clipped. A control that
  needs a *name* gets a visible label or an `aria-label` — see [Icons](#icons).
- **Not where the row leads nowhere.** `partners/requests/_history` and the partner dashboard have
  no detail page, so a clipped comment would be unreadable rather than one click away. Those use a
  `<details>` disclosure — bounded when collapsed, full text in place, keyboard reachable. That is
  the test: **is the full text one click away? clip. Is it not? disclose.**
- **Not for a cell of links.** `item_categories` lists its items as a `<ul>` of anchors; clipping
  would leave focusable links invisible. A long list of links needs a count or a "+N more", which
  is not built.

**`max-width` is load-bearing at 16rem.** `nowrap` makes the column *demand* its max-width rather
than shrink by wrapping, so this one number sets how wide every table carrying a `.notes` column
gets. At 22rem the purchases table grew from 1,061 to 1,298px, crossed its scroll region, and
started the whole document swiping sideways at 1440 — which it had not done before.

### Empty states

Never render bare empty table chrome. Three flavours, and every screen picks one
deliberately:

| `kind:` | Means | Offers |
| --- | --- | --- |
| `:cold_start` | Nothing exists yet | The create action |
| `:no_results` | A filter matched nothing | Clearing the filter |
| `:all_clear` | Genuinely nothing to do | Reassurance |

**`cold_start` offers the create action unless one is already on screen.** Eighteen of them offer
none, and that is right in two situations: a nested list on a detail page where creating happens
elsewhere, and a card whose footer already carries the button — the line item card's state sits
60px above **Add another item**, and two buttons doing one job is what the tab-actions pass
removed.

**A collection-driven table needs one, and the check is whether the collection can be empty.** A
sweep of `app/views` for a `<tbody>` driven by a `.each` with no empty state found sixteen; nine
were reachable-empty and were built, and the other seven show the line items of a *saved* record
whose model validates it has at least one. Those are listed in [todo.md](docs/todo.md) so the next
sweep does not rediscover them.

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

**Every index table is paginated.** A table whose row count grows with use and has no pager is
a page that gets longer forever. The tables still without one are bounded by something outside
the software, and each is listed with its reason in `docs/migration-map.md`.

Go through the helper, never the partial directly:

```erb
<%= render "shared/essentials/card", padded: false,
      footer: essentials_pagination_footer(@paginated_donations) do %>
```

**The strip renders for every table that has rows**, including one that fits on a single page.
The count is the point, and a card that gains and loses a footer depending on how much data
happens to be in it is a card of no fixed shape. The helper returns `nil` only when the
collection is empty, so an empty state is not followed by a strip reading "0 of 0".

Call sites used to do `capture { concat(render(...)) }` and let the card test the result for
blankness; that worked in production and failed in development, where
`annotate_rendered_view_with_filenames` puts an HTML comment in the buffer and a "blank"
capture is never blank. Nine pages carried an empty bordered strip under the table.

The pager draws no chrome of its own — the card footer supplies `border-t border-slate-200
px-5 py-3`. It used to draw both, which put the pager between two hairlines twelve pixels
apart on every page that used the footer slot. A table that is *not* the card's last child —
one tab panel of five, say — supplies that chrome itself:

```erb
<% if (pager = essentials_pagination_footer(items)) %>
  <div class="border-t border-slate-200 px-5 py-3"><%= pager %></div>
<% end %>
```

Kaminari's own partials in `app/views/kaminari/` supply the `<nav aria-label="Pagination">`
landmark and the `.pagination-link` styling; the current page is marked with
`aria-current="page"` and styled off that attribute, so the two cannot disagree. The
truncation gap is a `<span>`, not a link to `#`. Every page link carries
`data-turbo-frame="_self"`, so paging updates the results frame instead of doing a whole-page
visit and throwing away the scroll position.

#### The label states the range, not the page

**"Showing 31–45 of 272 requests"**, from `essentials_pagination_summary` — never "Page 3 of
19". A page number is a proxy: it changes meaning whenever the page size does, and it does not
answer the question the filter bar above it raises, which is how big the result set is. Someone
reading "Page 3 of 19" cannot tell whether the filter matched 140 records or 1,400.

The range and the total are `font-medium text-slate-900` inside `text-sm text-slate-600`, so
the numbers carry the emphasis and the words around them recede. The noun comes from Kaminari's
`entry_name`, lowercased word by word — a word with an internal capital keeps it, so a future
`/admin/ndbn_members` reads "NDBN members" and not "ndbn members".

#### The control set does not change width

`‹ Prev` and `Next ›` are **always drawn**, disabled when they lead nowhere. They used not to be
rendered at all at the ends, which meant the row of buttons changed width as you paged —
`/requests` was 7 controls on page 1, 14 on page 5 and 8 on page 10, so a target moved out from
under the cursor of the person using it.

`« First` and `Last »` are the exception: on a table that fits on one page they do not name
anything, so they are not drawn. On a longer table they are, disabled at the ends. Keeping them
at all is deliberate — jumping to the oldest record is a real task on the audit and event
tables, and a page number that moves as the result set changes is a worse target than a button
that does not.

Disabled means `<span aria-disabled="true">`, never a disabled link: an `<a>` cannot be
disabled, it stays focusable and announces nothing. This is the same treatment every
unavailable action gets here (`ui_helper.rb`). The styling hangs off the attribute, so markup
and appearance cannot disagree:

```css
.pagination-link[aria-disabled="true"] { opacity: 0.6; cursor: not-allowed; }
```

That measures **2.88:1** against white where a live link is 7.56:1 — plainly inactive, still
legible. WCAG 1.4.3 exempts an inactive control from the 4.5:1 minimum, but being invisible is
not the goal; `slate-300` was tried first and is 1.48:1.

Kaminari's `Paginator#render` evaluates its template only when there is more than one page, and
returns `nil` otherwise so the call site can supply fall-back HTML. That is the hook the
single-page control set uses — it is written out in `_pagination.html.erb` rather than coming
from `app/views/kaminari/`.

#### Page size: three bands

One number does not fit every table, because the rows are not the same height. Measured at
1440×900 in this app, a row on `/users` is 45px and a row on `/purchases` is 205px — a 4.5×
spread. `Pagination` (`app/models/pagination.rb`) names three bands, and an index states
which one it is:

| Band | Rows | Row height | Full page | For |
| --- | --- | --- | --- | --- |
| `Pagination::TALL` | 15 | 121–205px | 1,815–3,068px | rows that wrap: line items, addresses, multi-line summaries |
| `Pagination::MEDIUM` | 25 | 65–85px | 1,625–2,125px | the ordinary case: short cells that may wrap to two lines |
| `Pagination::COMPACT` | 50 | 45–53px | 2,250–2,650px | dense rows: a few short cells, no wrapping |

```ruby
@paginated_purchases = @purchases.page(params[:page]).per(Pagination::TALL)
```

Every band lands a full page between **1.8 and 3.4 screens** — the range where scrolling still
feels like reading one page rather than paging by hand. Pick the band by measuring the row,
not by guessing: `/broadcast_announcements` looks dense and is 85px, because the message body
wraps, and 50 of those is 4.7 screens.

Name a band even where the Kaminari default would do the same thing. That default is
`Pagination::MEDIUM`, written out as `25` in `config/initializers/kaminari_config.rb` because
an initializer runs before autoloading.

When a controller also exports CSV, paginate into a **separate** `@paginated_*` ivar and leave
the full collection for the export — otherwise "Export" quietly means "export this page".

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
- **The pipeline is Propshaft** (ADR 0012). It compiles nothing: no directives, no ERB assets,
  no Sass, no minification. It digests filenames and rewrites `url()` in CSS, and there is no
  precompile list — everything on the load path is served.
- **`app/assets/tailwind` is excluded from the load path** via `config.assets.excluded_paths`,
  so the uncompiled entry point can never resolve as `application.css`.
- **Do not precompile in development or test.** Propshaft serves from the load path in both, so
  `assets:precompile` *freezes* assets behind `public/assets/.manifest.json` until that file is
  deleted. This is the opposite of the Sprockets trap it replaced.
- **`assets:clobber` deletes the Tailwind build**, because `tailwindcss-rails` enhances the task.
  Always follow it with `tailwindcss:build`, or every page 500s on a missing `tailwind.css`.
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
gives the eye a second column of glyphs to skip and marks nothing out. This is not a rule about
grids — it is the general one under [Icon tiles and avatars](#icon-tiles-and-avatars), and it was
written here first, which is most of why the dashboard's announcement cards went on breaking it.

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
