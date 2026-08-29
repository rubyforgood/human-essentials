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
<a id="inert-on-arrival"></a>
- **A control that leads nowhere is disabled only when pressing it would cost something.** Several
  can be pressed before they can do anything: Today on a calendar that opens on today, "Reset
  search" before a search, [pagination's ends](#pagination). The line is what the press actually
  does.
  - **Costs something → disable it.** "Reset search" with nothing searched is a full page reload for
    no change; a pagination end is a navigation to where you already are. Both are links, and a link
    cannot be `disabled` — it stays focusable and clickable and announces nothing — so an
    unavailable one is a `<span aria-disabled>`, which
    `essentials_link_button(..., available: false, reason: "…")` renders with the reason as sr-only
    text.
  - **Costs nothing → leave it live.** Today on today calls an idempotent function and returns.
    Dimming it was tried and **reverted**: the case against disabled controls is aimed at ones that
    *gate* a task, and every calendar a reader already arrives with — Google, Outlook, Apple, Notion
    — keeps Today pressable. A no-op is a smaller price than a control someone has to reason about.
    The reasoning, and the measurements that nearly went the other way, are in
    [design-decisions.md](docs/design-decisions.md).
  - **A no-op is only tolerable when the state it would take you to is visible.** Today is marked in
    all three calendar views now; it was marked in *none* of the list view, and fixing that mattered
    more than the button ever did.
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

<a id="collapse-by-table"></a>
**The threshold is per table, not per row — and a varying action set is itself a reason to
collapse.** Both halves were learned the hard way, from a column that was reported as jarring:

- **If any row in a table can reach three actions, every row in that table gets the menu.** Applied
  per row, one table ends up with three inline buttons on some rows and one on others.
- **If *which* actions exist depends on status, role or state, use the menu whatever the count.**
  `/partners` chose its actions from a five-branch `case` on partner status, so reading down one
  screen the column measured **170, 120, 170, 241, 0 and 170px** — a different label, a different
  width, and sometimes nothing at all. The trigger is the same 28px on every row whatever sits
  inside it, which is the entire point: the column stops moving. `/organization`'s users table did
  the same thing by role.
- **Below that, actions stay inline.** A table with a settled one or two keeps them visible and one
  click away. `/barcode_items` showed **View, Edit and Delete** inline for **349px** — the widest
  actions column in the app; dropping the View (its first cell links to the record) leaves a pair
  that is always both present, so those stay visible.

<a id="varies-in-code-not-in-a-seed"></a>
**Judge "does the set vary?" from the code, not from one screen.** `bin/design/row-actions-audit.js`
reports a menu holding two or fewer as **advisory**, not a failure, and this is why: `/items` builds
*Delete*, *Deactivate* or a **disabled** *Deactivate* from the item's state, and on seed data every
row happens to land in the same branch. Rendered once it looks like a settled pair inside a menu —
the shape the rule says to open up — and it is correctly collapsed. The audit sees one render; the
`case` in the row partial is the answer.

<a id="row-action-heights"></a>
**Every control in an actions column is the same height.** A visible action beside a kebab is
**icon-only at `size-7`**, named by `aria-label` and `title`. A labelled `sm` ghost button is 30px
and the trigger is 28, and the 2px step was visible on `/vendors` and `/requests` where the two sat
side by side. Uniform 28px icon buttons is also what Carbon and Salesforce ship for this column.

<a id="actions-column-header"></a>
**The actions column header is `<th scope="col" class="text-right">Actions</th>` — visible.**
Always present, always `scope="col"`, always right-aligned, on all 43 tables. Four variants were in
use before: 33 hidden and plural, **8 visible**, one `<th>Action` with no `scope` and no alignment,
and one hidden and singular.

**Industry is split, and it splits on what the column holds.** Salesforce Lightning uses assistive
text, GOV.UK uses `govuk-visually-hidden`, Carbon and Atlassian render it empty with an accessible
name; **Ant Design shows it**. The W3C tables tutorial only requires that every column *have* a
header, visible or not.

**Visible, because most of these columns are now a single unlabelled glyph.** When a column held
labelled buttons — *Edit*, *Delete* — it described itself and the header was redundant, which is the
case the hidden convention is built for. Collapsing nine tables turned most of them into one "⋯".
A column whose entire visible content is one glyph is where the header does real work.

It costs **15px** on `/partners` and `/items` and 18px on `/donation_sites` — measured, after an
earlier version of this rule justified hiding it on width and overstated that.

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
<a id="the-app-confirms-not-the-browser"></a>
**The app confirms, not the browser.** `data-confirm` on any control opens the design system's
`<dialog>` — `shared/essentials/confirm_dialog`, one per shell, filled in by
`confirm_dialog_controller.js`. No call site changed: all 44 carry `data-confirm` and always did.

The dialog names the action on its confirm button — **Delete**, not "Continue" — and reddens it for
a destructive variant. Both are derived from the control's own tone, so a call site cannot put a red
button on a harmless action.

<a id="why-intercept-the-click"></a>
**It intercepts the click rather than overriding `Rails.confirm`.** rails-ujs's confirm hook is
**synchronous** — it must return true or false immediately — and a `<dialog>` resolves when someone
presses a button. There is no way to answer synchronously from one. So the click is caught in the
*capture* phase before rails-ujs sees it, and replayed if the answer is yes.

Two details that are easy to get wrong and were:

- **`stopImmediatePropagation`, not just `preventDefault`.** rails-ujs binds on `document`; merely
  preventing the default still lets its handler run and raise its own native confirm.
- **The replay removes `data-confirm` from the element first.** Marking it as already-answered is
  not enough — rails-ujs still sees the attribute on the way past. It goes back afterwards so the
  next click asks again.

`window.essentialsConfirm({message:, title:, label:, tone:})` returns a promise, for the one place
that cannot use `data-confirm`: `utils/donations.js` guards a large donation from inside its own
click handler. Anything else should use the attribute.

<a id="a-menu-item-is-not-a-button"></a>
**A menu item is not a button — do not render one through `essentials_action_button`.** That helper
applies `essentials_button_classes`, which is `inline-flex justify-center` plus the size's own
padding, and wraps the form in `form_class: "inline-block"`. In a menu that is wrong twice:
`inline-flex` beats the item's `flex w-full`, and an inline-block form inside the actions cell —
which is `text-right` — shrink-wraps and floats to the right edge.

Measured on `/vendors` before the fix: *Edit* at **x=1 across 222px**, *Deactivate* at **x=117,
106px wide**, in the same 224px menu. Every enabled action in every row menu looked like that. A
menu item is a plain `button_to` carrying `item_classes` and `form_class: "block"`.

Keep `data-turbo=false` when you do: these submit from inside a results turbo-frame, and Turbo
intercepting them is what made *Reactivate* silently do nothing about half the time.

<a id="offer-it-and-explain"></a>
- **An action that will fail is offered anyway, and the server explains.** Do not disable a row
  action because of the record's *state* — offer it, let the request be made, and answer with a
  flash that gives the reason **and the next step**.

  ```
  Adult Briefs (Medium/Large) still has stock in a storage location, or belongs to a kit.
  Move or distribute the remaining stock and remove it from any kits, then deactivate it.
  ```

  This went through two earlier shapes and both were worse. **Omitting** the action made the column
  ragged and answered nothing. **Disabling** it with the reason as `sr-only` text meant a screen
  reader heard the explanation and everyone else saw a greyed-out word — reported as confusing, and
  worth remembering as a rule: *optimising an affordance for assistive technology is not a reason to
  withhold it from everyone else.* Making that reason visible fixed the silence but not the shape: a
  line under a label has room for a phrase, and what a user needs is **what to do about it**.

  The cost is honest: the click is spent before the answer arrives. It buys a menu whose items are
  all live, all one line, and a reason with room to be useful. GOV.UK take the same position and
  avoid disabled controls entirely.

<a id="disable-only-for-who-you-are"></a>
- **Disable only when there is no request to make.** The exception is an action unavailable because
  of *who you are* rather than the record's state — you cannot change your own membership on the
  organization's users table. There is no attempt to send and therefore nothing for a flash to
  answer, so it stays a disabled item with a visible reason under the label. A form action gets a
  genuinely `disabled` `<button>` and a link action a `<span aria-disabled>`; only a form control
  can be `disabled`.

  **Dim the label, not the item.** `opacity-60` on the whole row painted the reason at **2.32:1**
  against white. [1.4.3](#contrast) exempts an inactive control, and that exemption is no argument
  here — the point of showing a reason is that it gets read. The reason stays slate-500 at
  **4.75:1**.
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
- **`essentials_inline_select_classes` for a select in a toolbar**, not `SELECT_CLASSES`. The form
  constant carries `mt-1.5 block w-full` — layout for a field stacked under its label — which in a
  row of buttons means full width, a stray top margin, and 38px beside neighbours at 30px. The
  inline helper is the same surface and the same `.select-chevron`, sized from `BUTTON_SIZES`, and
  `CONTROL_SURFACE_CLASSES` is the look the two share with no size or layout in it. Measured on the
  calendar: month select, year select, Today, Prev and the view switcher all 30px, tops and bottoms
  flush. `pr-10` at both sizes on purpose — the chevron is positioned from the right edge rather
  than from the padding, so trimming the padding slides the text under it instead of moving it.

<a id="compare-in-words"></a>
**A card that exists for a comparison should make the comparison**, in its `subtitle:`, not leave
two facts near each other. The Service area card holds what a partner *declares* — counties, with
the share of their clients in each — beside where their families *actually* are. Its first version
put those in two columns and said nothing: measured, the right column was **273px tall holding one
number**, about 85% empty beside a four-row table, under two headings and two captions. It reads
*"They serve 4 counties. Their families live in 13 zipcodes."* now, which is the sentence a bank
would otherwise have to assemble.

**Stacked, not columned**, for the same reason: a table and a list are not parallel shapes and were
never going to balance, and full width lets "Berkshire County, Massachusetts" sit on one line. The
table sorts by share, so the county most of their clients are in reads first.

**The zipcodes are shown, not hidden behind a dialog.** Measured across the bank: **max 13, median
8** per partner. Truncation kicks in only when it saves something — a flat `first(12)` rendered
"and 1 more" for a partner with 13, which is a dialog to save one line — so the list shows whole up
to 16 and truncates beyond that. Below the threshold the dialog is not rendered at all.

<a id="code-boxes"></a>
**A set of codes is a row of bordered boxes**, square-cornered, neutral, `font-mono` with
`tabular-nums`, and nothing to click. Space-separated digits give the eye nothing to say where one
code ends and the next begins — which is the complaint the zipcode list drew.

**Square, specifically, and that is the whole distinction.** Both chip-shaped things this app already
has are `rounded-full`: a [status pill](#pills), which carries a tone colour and which is *a state*,
and a filter chip, which carries an `×` and means a filter you can remove. A square uncoloured box
that does nothing when clicked is a third object and reads as one. `font-mono` is the treatment
barcode values already get — a code you read a character at a time.

**An aligned grid was recommended first, and withdrawn.** The argument was that columns give the eye
a rail; measured at the real card width they do not exist. 1144px fits twelve five-digit codes
across, so thirteen rendered **12 × 2** — one row stretched by `1fr` with ~90px between neighbours,
and the thirteenth orphaned on a line of its own. Columns only help a list long enough to wrap into a
block, and at a median of 8 this one never is. A grid would be right for fifty.

<a id="five-digit-zipcodes"></a>
**A zipcode is five digits.** `Partner#family_zipcodes_list` truncates and deduplicates; **35 of 67**
stored values carry a `-NNNN` suffix, which names a block rather than an area. This was a counting
bug as much as a display one — two families at `45612-123` and `45612-126` live in one zipcode and
were counted as two — and the model spec asserted that pair *and* that count, so the wrong answer had
been pinned down rather than caught.

<a id="page-header-status"></a>
**A status goes on the title line, not in `actions`.** `status:` on the page header renders the pill
beside the `<h1>`. The partner page used to pass its pill *into* `actions`, where a pill among
buttons reads as a button that has been greyed out — and `actions` is documented as at most three,
exactly one primary, which a status is none of. A status belongs to the thing, which is where
GitHub, Linear and Stripe put it.

<a id="one-scrollbar"></a>
**A scrollable table gets one scrollbar, and it is the rail.** `.table-scroll` forces a persistent
native scrollbar; `.table-rail` builds a floating one. Both were on, both permanent, so a scrollable
table carried **two horizontal bars** — measured on `/distributions` at 1280, the rail's top edge and
the region's bottom edge both at **637**, the native bar occupying the last ~10px inside the region
and the rail beginning immediately below it. Because the rail rides the fold and travels down to
meet the table's end, the second bar appeared to arrive and leave: reported as *"a ghost scroll bar
appears above the actual scroll bar and then it disappears"*.

The native one is hidden under **`[data-railed]`**, which the controller sets only once it has built
a rail. No JavaScript, or a table that does not overflow, and the native scrollbar is untouched —
this hides a scrollbar only after its replacement is on the page.

**The rail is a track and a thumb — plus a ground, but only while it floats.** It carried a 25px
bar, a 92%-white backdrop over a table row, and a hairline border permanently: six elements
including the native bar, for a control that needs two. The bar is gone for good. The height stays
**24px**, because the track is the pointer target and 2.5.8 asks for 24; the bar you see is 6px of
it, and at rest the visible bar covers **no rows** (measured: 0.1px of sub-pixel contact with the
24px band, none with the 6px bar).

<a id="rail-backdrop"></a>
The backdrop and hairline came off entirely first, and that was **right for one of the rail's two
states and wrong for the other**. At rest the rail sits in a strip the card reserves for it with
nothing behind it, so a backdrop there only washes out the card. But it is at rest for the minority
of the scroll: traced down `/distributions`, which scrolls 611px, the rail rides the fold for **448
of them — 73%** — lying across live table rows the whole way. A 6px bar on row text with nothing
between them is what was reported as *"it hovers in an odd way"*.

So they come back **gated on `data-floating`**, which the controller sets from the same test that
places the rail. The hairline is an **inset shadow rather than a border**: `box-sizing` is
`border-box` here, so a border would take the track from 24px to 23 and put 2.5.8 a pixel short in
exactly the state where the control is hardest to hit.

<a id="rail-strip"></a>
**The reserved strip is 24px — the rail exactly fills it — the card footer drops its own rule where
the rail settles, and the settled bar sits at the bottom of its track rather than centred in it.**
Those three go together, and the spacing below a table is wrong without all of them. It took four
attempts to land, reported each time, so the failures are worth keeping:

| Strip | What was wrong |
| --- | --- |
| 24px | Rail's bottom edge **0.14px** above the footer's rule. |
| 32px | Still read as stuck: the bar sat **18px** from the rule where the card's other lines are 53–62px apart. |
| 44px | Rule gone, but the pager now had **42px** of air above it and **12px** below. |
| **24px + bottom-aligned bar** | **13px above the pager, 12px below.** |

**The unit that matters is the pager, not the strip.** Every one of the first three tried to fix
this by changing the strip's height, and the strip is not what anyone is looking at: the rail carries
**9px of dead space** beneath a centred 6px bar, so the strip's height and the visible gap differ by
a constant nobody can see. Measure from the bar to the pager's controls.

At 24px the strip was exactly the height of the thing that goes in it, leaving the rail's bottom edge
**0.14px** above the footer's border. Widening it to 32 was still reported as stuck, and scanning
every full-width line the card paints says why:

| Line | Weight | Gap to the next |
| --- | --- | --- |
| row divider | 1px, `slate-200` | 53px |
| row divider | 1px, `slate-200` | 62px |
| **the bar** | **6px, `rgb(122,140,166)`** | **18px** |
| footer rule | 1px, `slate-200` | — |

The bar is the darkest and thickest full-width line in the card, and it sat **18px** from the footer
rule in a card whose every other line is **53–62px** apart. A thing groups with whatever is nearest,
so it read as belonging to the pagination rather than to the table it scrolls. Padding alone cannot
fix that: closing the ratio would need a strip near a **row's height**, and a strip that tall reads
as an empty row.

So **the duplicated line goes**. One boundary gets one line, and the bar is the heavier of the two.
This app had already made exactly this call: `shared/essentials/_pagination` draws no border of its
own because doing so *"put the pager inside two stacked hairlines twelve pixels apart"*.

Removing the rule is also what lets the strip come back down to 24. The strip was widened to 44 to
separate the bar from a line that no longer exists, and with the pair gone that width was simply air
above the pager — **42px of it, against 12px below**. So the strip returns to 24, and the last 9px
come from the bar's own placement.

<a id="rail-bar-alignment"></a>
**Settled, the bar sits on the bottom edge of its track.** The track must stay 24px for
[2.5.8](#target-size), and a centred 6px bar leaves 9px of dead space under it — dead space that is
still a pointer target, so it cannot be allowed to reach the pager's controls or a click meant for
*Next* jumps the table sideways. That sets a floor: with the bar centred, the closest it gets to the
pager without the track overlapping a control is **22px**, against 12px below. Sitting the bar on the
track's bottom edge spends the dead space *upward* into the strip, where there is nothing, and the
gap becomes **13px against 12px** with 13px of clearance left.

Only when settled. While the rail rides the fold its bottom edge is the bottom of the window, so a
bar sitting there would be jammed against the screen edge; floating, it stays centred and 9px clear.

Gated on **`[data-railed="settled"]`**, not on `[data-railed]`: while the rail rides the fold it is
not above the footer, and the footer would lose its separator with nothing replacing it.

That cannot happen, and now for an exact reason rather than a comfortable margin. **The strip and the
rail are both 24px**, so "the rail's bottom sits at the fold" and "the footer's top sits at the foot
of the window" are the same boundary: floating means `region.bottom > innerHeight - 24`, and the
footer's top is `region.bottom + 24`, therefore always below `innerHeight`. The footer is never on
screen without the bar directly above it. The margin is *strictly* positive but can be a fraction of
a pixel, which is exactly why the gate is written down rather than relied on — verified across four
pages × four viewport heights at every scroll position: **0** positions where the footer has neither
a rule nor a bar above it. It carries `!important`, because the border is a Tailwind utility and a
utility beats a rule in `@layer components` whatever its specificity.

<a id="rail-radius"></a>
**The track and the thumb are pills, written as `calc(infinity * 1px)`.** Not `var(--radius-full)`:
**that token does not exist**. Tailwind v4's radius scale stops at `--radius-2xl` and `rounded-full`
compiles to the literal, not to a variable — so the declaration was invalid, the browser dropped it,
and both parts rendered as sharp rectangles from `015da3b36` until it was written out. Measured 0px
on each. Resolving every custom property `application.css` references against the running app,
**30 referenced, 28 resolve**, and the other unresolved one is `--pin-width`, which the controller
sets per element at runtime and is correct. One bad token, not a pattern — but a `var()` naming a
token that does not exist fails **silently**, so a value that must render is worth measuring once.

<a id="scrollbar-contrast"></a>
**The thumb has a contrast floor, and it is not a preference.** A custom scrollbar thumb is author
content, so 1.4.11 applies and asks 3:1 against what it sits on. Against the `slate-100` track:

| Thumb | Ratio | |
| --- | --- | --- |
| `slate-300` | 1.36:1 | fails — and this is what "match the app's resting weight" would suggest |
| `slate-400` | 2.40:1 | fails — what the bar shipped with first |
| `oklch(0.636 0.044 257.1)` | **3.13:1** | **what it is now**, painting `rgb(122, 140, 166)` |
| `slate-500` | 4.35:1 | passes, and was reported as very dark |

The floor decides which values are *available*; it does not pick one. slate-500 cleared 3:1 by 1.35
and was chosen only because the Tailwind scale **has no step between slate-400 and slate-500** — so
the value above is that missing step, solved for rather than picked: the lightest slate-hued value
that still clears the floor. Hover and drag stay on the scale at `slate-600` and `slate-700`, which
are darker, so the ramp stays monotonic.

The ratios above are sampled off **painted pixels**, not computed from the declarations, which is
why slate-400 reads 2.40 here against the 2.34 recorded when this table was first written — that
figure came from Tailwind v3's hex for slate-400, and this app is on v4.

**axe cannot catch any of it.** Nothing in the markup says that div is a control, so no automated
check knows to hold it to 1.4.11. It was found by computing the ratio, which is the only way it was
going to be.

<a id="modal-centring"></a>
**A modal keeps `margin: auto` whatever it is rendered inside.** `.modal-surface` on the dialog,
with `!important`. A native `<dialog>` is centred by the browser's own auto margins, and a spacing
container replaces them: measured on the partner page, `top: 0` and `margin: 0px 464px 24px` against
a healthy modal's `339.5px 336px`. Proven by toggling `space-y-6` on the parent with the dialog
open — **0, then 453 centred, then 0** — in the top layer throughout. The `!important` is required
because `.space-y-6 > :not([hidden]) ~ :not([hidden])` is three class-level selectors to this rule's
one. Five of the app's six dialogs were correct only by accident.

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

<a id="the-calendar"></a>
**The calendar is restyled too, and its toolbar is ours.** FullCalendar ships the same vintage of
defaults select2 does — measured on `/distributions/schedule` before this: buttons filled
`rgb(44,62,80)` at a **4px radius and 16px text**, a 28px/400 month title, day-of-week headings at
16px/700 where a table heading is 12px/600, day numbers at 16px, and grid lines in
`rgb(221,221,221)`, a grey outside the palette, with square corners inside a 16px card.

**The font was never the problem**, though it looks like it: the calendar renders in Figtree like
everything else. What reads as another typeface is **16px at weight 400 against the app's 14px at
500**.

The grid is restyled in CSS. The **toolbar is not** — `headerToolbar: false`, and Today, Prev and
Next are ordinary `:secondary, size: :sm` buttons in the view, driven by `calendar_controller`
through `today()`, `prev()` and `next()`. Three filled dark buttons were a page's worth of
primary-looking chrome for moving the month, on a page whose real action is a quiet secondary; and
three buttons are cheap to own outright, which means a library upgrade cannot silently revert them.
"‹ Prev" and "Next ›" rather than bare chevrons, because [icon-only](#icons) is for a repeating row
action and this is the shape the pager already uses for the same job.

<a id="calendar-views"></a>
**Two axes — a duration and a layout — and both live in the URL.** How long: Month or Week. How it
looks: Grid or List. There was no view switching at all before this; FullCalendar's default toolbar
carries none unless asked, and the only view decision was made *for* the reader by window width.

<a id="one-label-one-view"></a>
**One label answers one question, and that took three goes.** It shipped as two buttons, where
"Week" meant `dayGridWeek` above 992px and `listWeek` below it — and because the list was *also* the
narrow default, Week arrived already pressed, `switchView` returned early, and the button did
nothing at all. Month worked, so only Week looked broken. Measured at 1440, 1200, 1000, 991, 900,
768 and 375: every width below 992 was inert. **992 is not an unusual window** — a 1440 screen at
150% scaling is 960 CSS px, and any window that is not maximised can land under it.

Then it became three buttons, Month / Week / List — which fixed the dead button and left a subtler
version of the same fault: **"List" named a shape where its neighbours named a duration**, so
nothing on it said how much time it covered. It is a week; measured, the week of 7 September drew a
single row under a heading reading "Sep 7 – 13".

Splitting the two questions is the fix, and it reaches a fourth view that three buttons could not
express: **a whole month as one list**, which is the obvious thing to want for a monthly
reconciliation. FullCalendar has all four already — `dayGridMonth`, `dayGridWeek`, `listMonth`,
`listWeek` — so it costs no plugin. Its own toolbar labels these by duration for exactly this
reason: in the library, a list is a rendering of a range rather than a range.

The mapping was the mistake rather than the threshold. A list is a *third view*, not a narrow
rendering of a week, so it is a third button. **The threshold is separately wrong and left
alone on purpose**: 992 is Bootstrap's `lg`, the only place in `app/` that number outlived ADR 0011,
and it asks `window.innerWidth` when the sidebar docks at 1024 and takes 256px — so the grid is
narrowest at 1025 (94px day cells) and roomiest at 1023 (133px). Measured in
[design-decisions.md](docs/design-decisions.md); changing which view a width defaults to needs a
preview first. The regression test was run against the old controller
and fails there on `.fc-dayGridWeek-view`, which is the only way to know a regression test regresses
anything.

**No Day view, and that is a measurement.** Over a year: **22 days** had any distribution, mean
**1.9**, and **13 of those 22 held exactly one**. A day view is twenty-four rows of hour axis to say
what a month cell says in one line. Week earns its place on the same numbers — mean **3.5**, peak
**16** — because a crowded week is exactly what the month grid handles worst, and it is the horizon
the page exists for.

**Week is `dayGridWeek`, not `timeGridWeek`**, which is the more interesting call:

| | |
| --- | --- |
| The times are real | The form takes `as: :datetime, minute_step: 15` — a bank does record a 9:00 pick-up. |
| But there is no end | `created_at`, `updated_at`, `issued_at`. On an hour axis every event is a zero-length block. |
| And half a fresh database has no time | **24 of 48** rows sit at **00:00**, because `db/seeds.rb` writes a date and no time. A time grid stacks those at midnight and shows *missing data* as an appointment. |

It also needs no new plugin or importmap pin, on a library this app has already been caught trailing
a major version of. If banks start recording times on everything, `timeGridWeek` becomes the better
answer and the change is a view name.

<a id="calendar-url"></a>
**The parameter is `layout`, not `format`** — `format` is reserved by Rails routing for the response
MIME type, so `?format=grid` reached the action as a request for a "grid" representation and raised
`ActionController::UnknownFormat`, a 406, before anything rendered.

**Clicking one axis writes both.** A link that carried only the axis you changed would leave the
other to a default that depends on the *reader's* window width — the sender's view on the sender's
screen and something else on the recipient's. `?view=` from before the split is still honoured, so
links shared while it existed open on what they meant.

**The view is a URL parameter, not `localStorage`.** [Page tabs](#tabs) already settled this: *"it is
also how a tab becomes something you can link to, bookmark and go back from."* A view is a tab by
another name, and the URL is the only option that can answer "why does mine look different from
yours". `pushState` rather than `replaceState`, because Back has to actually return to the previous
view — otherwise the rule delivers two thirds of its own sentence. The parameter is `month`/`week`,
not the library's view names, so a shared link does not carry FullCalendar's vocabulary or break
when it changes.

**A narrow window defaults to a Week, as a List** — which is what the page already fell back to
before there was any choice about it. Both grids are still reachable there; they are squeezed, not
broken.

<a id="list-caption"></a>
**A list says what it covers and how much of it is empty.** `Monday, September 7 – Sunday,
September 13 · 1 of 7 days has a distribution`. A list draws only the days that hold something —
FullCalendar has no option for the empty ones, confirmed against its list-view documentation — so a
week with one distribution renders one row, and one row is indistinguishable from "there is one
distribution, ever". The caption is hidden in the grids, where the empty days are already on screen
as empty cells and the sentence would only restate the picture.

Built from `Intl.DateTimeFormat.formatRange`, which drops the parts the two ends share and does it
per locale. The first attempt asked for `{weekday, day}` on the near end and added the month only
when the range crossed one; Intl has no sensible pattern for a weekday and a bare day, and en-US
rendered it `24 Monday – Sunday, August 30`.

**The two list views order a day heading differently** — `listWeek` leads with the weekday,
`listMonth` with the date — and that is left alone because it cannot be fixed from here. Overriding
`listDayFormat` at all makes `listDayAltFormat` mirror it, globally or per view, so every heading
renders its own date twice: `Sunday | Sunday`. A heading that reads in a different order is a
smaller problem than one that says the same thing twice.

<a id="calendar-jump"></a>
**Month and year are two native selects.** Prev and Next move one step, so before this March next
year was **seven clicks** away and last December five, with no other route to either.

**Not `<input type="month">`**, which is the tidier control and the one this nearly picked. It is a
real picker in Chrome and Edge and degrades to a bare text box expecting `2026-08` in desktop
Firefox and Safari — and only Chromium was installed where this was measured, so the cross-browser
claim could not be made at all. Two selects need no such claim. It is the same argument that
[deleted Litepicker](#date-range-picker): native controls over a widget.

**The year list is bounded by the organization's own distributions**, `MIN(issued_at)` to
`MAX(issued_at)`, always including this year so a new bank with nothing in it still gets a usable
control. Prev and Next can walk off either end, and `ensureYearOption` inserts the year in sorted
position rather than leaving the select naming a year the calendar is not on.

**The selects follow the calendar as well as drive it.** Today, Prev, Next and a view change all
move the range, and a control reading August while the grid shows October is worse than no control.
They sync from `view.currentStart`, so a week straddling two months names the one it *starts* in —
pick March, land on the week of 23 February, and the selects say February. That is the honest
answer: the week really is mostly February.

**The month on screen is deliberately not in the URL, although the view is.** Prev, Next and Today
move the range without touching it, so putting only the select's jumps there would make two thirds
of the page's navigation linkable and one third not. If position should be shareable it should be
shareable however you arrived at it.

**Today stays pressable, and does nothing while today is on screen.** That is the deliberate
answer, not an oversight — it was dimmed for a day and reverted. See
[inert on arrival](#inert-on-arrival): pressing it costs nothing, and the alternative asks the reader
to work out why a control is greyed. What makes the no-op fair is the marker below.

**Today is marked in the list view now, and was not marked at all.** FullCalendar does put
`fc-day-today` on the list row, but `--fc-today-bg-color` only reaches day *cells* — measured, the
row painted `rgba(0, 0, 0, 0)` and its header plain white like every other day. The list is the
default view on a phone, so on a phone nothing said which day was today and the Today button was the
only thing that could. Same brand-50 / brand-700 pair as the grids.

**Prev and Next are labelled from the controller**, because they step a month in the month view and
a week in the other two — one fixed "Previous month" is wrong in two views out of three. The visible
word stays inside the accessible name, which is what 2.5.3 asks.

**A date *range* is not on this page.** The grid draws a month or a week; hand it "3 March to 19
August" and there is nothing to render. `/distributions` is the same data as a list and already
carries the [range filter](#date-range-picker), so the subtitle links to it instead.

Three things this taught that the select2 note does not cover:

- **`!important` is required, and for select2 it is not.** FullCalendar injects its stylesheet into
  `<head>` at runtime, unlayered and later in source order than anything `application.css` can emit.
  select2's is imported into this file, so leaving `@layer` is enough.
- **A palette swap breaks the contrast pair you did not change.** Setting `--fc-today-bg-color` to
  `brand-50` put the existing slate-500 day number at **4.0:1**, and axe caught it on the first run.
  The text colour was untouched; the background under it moved. Today's date is `brand-700` now,
  which is the pair the event chips already use.
- **The "+N more" link is an anchor pretending to be a widget.** FullCalendar renders it as an `<a>`
  with no `href`, carrying `aria-expanded` and an **empty `aria-controls`** — neither allowed on an
  element with no role, and axe reports it CRITICAL. It only appears once a day is crowded enough to
  overflow, which is why it went unseen until `db:seed:calendar` made one. `moreLinkDidMount` adds
  `role="button"` and drops the dead attribute. The behaviour was already right: **measured, Enter
  and Space both open the popover** — unlike `add_element_button`, where the same shape of markup
  also swallowed Space.
- **Check the library's version against its option names.** `defaultView` and `eventLimit` are
  FullCalendar **4** spellings on a **6** install, so both were silently ignored — the mobile list
  view had never once rendered. Verified by running the new spec against the old code, which
  reported `fc-dayGridMonth-view` at 375px. A wrong option name is not an error, it is nothing.

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

<a id="radio-spacing"></a>
**Radio and checkbox options are 24px rows with 8px between them** — a 32px pitch, set once on
`:essentials_collection`'s `item_wrapper_class`, so no page decides this for itself.

They were 24px rows with a **0px** gap, flush against each other, in every group in the app. That
passes [2.5.8](#target-size) on size alone — the row is exactly the 24px minimum — and sits on its
floor with no separation.

**The gap is what buys the separation; do not inflate the row.** A first pass took the row to 32px
as well, for a 40px pitch, on **GOV.UK**'s 40+10 and **Material 3**'s 48dp — and it was reported as
too loose, correctly. Those two are the wrong comparators: GOV.UK sizes for a full-page public
service form and Material for a touch list. The systems this app resembles agree with each other at
24/8 — **Carbon** 24px rows with 8px between, **Ant Design** 8px between 16px controls,
**Atlassian** 8px, **Bootstrap 5** a 24px `.form-check`. The row was already compliant; only the
gap was missing.

<a id="breadcrumbs"></a>
**Every page that is not a nav root carries a breadcrumb.** It sits above the `<h1>`, 8px clear of
it, and `page_header` renders it — no page draws its own.

```erb
<%= render "shared/essentials/page_header",
      title: "Itemized donations",
      back: {path: reports_path, label: "Back to reports"} %>
<%# => Reports › Itemized donations %>
```

The `back:` local is unchanged at all 99 call sites: the parent's name is derived from the label,
which is `Back to <noun>` everywhere in the app — checked before relying on it. `breadcrumb:` takes
an explicit `[[label, path], …]` when a trail is deeper than one level.

**The structure is the W3C ARIA APG pattern**, which GOV.UK, Carbon, Material and Bootstrap all
render identically: a `<nav>` with an accessible name, an **ordered** list because the order is the
hierarchy, links for the ancestors, and the current page as **plain text** carrying
`aria-current="page"`. The separator is a generated `aria-hidden` glyph — a literal `/` between two
links is announced as "slash". 14px, slate-500 for the trail and slate-700 for the current item,
each link 24px tall.

**It replaced a "Back to X" link, and subsumes it.** The first ancestor is the same destination, and
the trail also says *where you are*, which the back link never did. That is why there is one pattern
here rather than two.

<a id="every-page-is-leavable"></a>
**A page is finished when it can be left.** `bin/design/wayfinding-audit.js` checks every screen in
three roles: it must be a nav root, carry a breadcrumb, or have page tabs linking a sibling. It
found **10 real orphans**, of which the whole reports section was five — every report is reached
from the hub, none is in the sidebar, and none linked back, so the browser button was the only way
out.

<a id="one-page-wrapper"></a>
**One `px-4 py-6 sm:px-6 lg:px-8` per page, and the header goes inside it.** The gap between the
heading and the first card is **24px** — the header's own `mb-6`, and nothing else. Do not override
`wrapper_class`, and do not close the wrapper after the header to open a second one for the content:
that stacks the first wrapper's bottom padding on the second's top padding, and the measured gap
becomes **72px**.

This is worth stating because it was the single most common defect on the branch, and it is
invisible to every check: **14 templates** had two page wrappers, and each renders, validates and
passes the sweeps. `/organization` was reported by eye; the other thirteen were found by counting
the wrapper in the templates once the first one was understood. Below the header, a page with more
than one block spaces them with `space-y-6` — 24px again, from one mechanism rather than from two
paddings meeting.

```erb
<div class="px-4 py-6 sm:px-6 lg:px-8">
  <%= render "shared/essentials/page_header", title: "Users" %>

  <div class="space-y-6">
    <%= render "shared/essentials/card" do %>…<% end %>
    <%= render "shared/essentials/card" do %>…<% end %>
  </div>
</div>
```

Count them before believing a page is fine:

```bash
for f in $(grep -rl 'px-4 py-6 sm:px-6 lg:px-8' app/views --include=*.erb); do
  n=$(grep -c 'px-4 py-6 sm:px-6 lg:px-8' "$f"); [ "$n" -ge 2 ] && echo "$n  $f"
done
```

<a id="form-width"></a>
**A form is left-aligned at the page gutter, and its width follows its layout.** This had no rule at
all until now — thirty-six views set their own max-width and had drifted into two.

| | Width | For |
| --- | --- | --- |
| One column | `max-w-2xl` (672px) | Forms with nothing worth pairing — kits has three fields |
| Two columns | `max-w-4xl` (896px) | Forms with short fields that belong together, paired with `essentials_field_row` |
| Full | `max-w-none` (1120px) | Line-item forms: donations, purchases, transfers, adjustments, distributions |

**The content container is deliberately uncapped.** `<main>` is `flex-1` with no max-width, so a
page fills the monitor. That was measured and left alone on purpose: beside a form it wastes 22% of
the width at 1440 and 60% at 2560, and the distributions table renders at 2238 for content needing
1505. Capping it at 1600 was built, screenshotted and declined — see
[design-decisions.md](docs/design-decisions.md). Do not treat the emptiness beside a form as a bug in
the form.

**Left-aligned, and centring is ruled out by a measurement rather than a preference.** Every `h1` in
this app sits at **288**, on every index, show and form page. Centring a form moves its heading with
it: **144px** at `max-w-4xl`, **256px** at `max-w-2xl`. Clicking "New item" from the items list would
slide the page title a quarter of the screen sideways, between two views of the same resource.

It is also not the convention it is assumed to be. Centring belongs to **standalone** pages — sign
in, checkout, onboarding — which have no surrounding furniture to align against. An in-app form
under a page heading is left-aligned in GOV.UK, GitHub, Stripe, Shopify and Atlassian alike, sharing
its heading's edge. This app's own auth screens are not centred either: a split panel, form at
`left 888`.

<a id="field-row"></a>
**`essentials_field_row` puts two short fields on one line.** A price beside a quantity, a start date
beside an end date, a minimum beside a recommended. It exists because the alternative way to fill a
wider form is to stretch every input, which gives a twenty-character name an 896px box.

Two conditions, both of them real:

- **Short enough that a full-width input would be absurd.** A name, an address or a select of long
  option labels stays full width.
- **Related enough to read as a pair**, because the DOM order is the order the fields are announced
  and tabbed. A pair that is not really a pair costs a screen-reader user more than the layout saves
  anyone else.

A lone short field gets a row to itself, so it takes half a line rather than all of one. The row
stacks below `sm`. The `:essentials` wrapper already carries `mb-4`, so the helper adds the
horizontal gap and nothing else.

<a id="where-a-button-goes"></a>
### Where a button goes

**Three kinds of button, and the test is what pressing it affects.** Not where it looks tidy — scope
decides the home, and the three homes are already distinct components.

| If pressing it… | It belongs to | Where it goes |
| --- | --- | --- |
| acts on the page or the record as a whole — *New item*, *Export*, *Deactivate* | the **page** | the page header's `actions:`, right-aligned |
| acts on **that card's own contents** — *Add another item*, *View all users*, a pager | the **card** | the card's `actions:` (header) or `footer:` slot |
| **commits or abandons the whole form** — *Save*, *Cancel*, *Submit request* | the **form** | `essentials_form_actions`, **below the card**, no divider |

<a id="form-actions"></a>
**A form's buttons go below the card, not inside it.** `essentials_form_actions` renders the row:
`mt-6`, left-aligned, and **no divider of any kind**. Off the surface, the card's own edge is the
boundary; a rule under it would be a second mechanism for one job.

The reason is scope, not looks. A card groups related content; the submit commits the *form*, which
on seven of these forms spans two or three cards and belongs to none of them — donations, purchases,
distributions, transfers, audits, adjustments and kits all worked this way already. The other 33
forms drew the row inside the card under a divider, and that divider was the visible symptom:
measured on `/items/new`, **854px of rule in an 896px card, inset 21px each side**, because it was
drawn inside the card's 20px body padding. Every other divider in the app is full bleed. It was the
only rule in the app that did not reach the edges of what it divided.

**This means the form wraps the card, not the other way round.** 31 views had `card > form`, which
cannot put a submit outside the card and inside the form at once. Swapping the nesting is the part
that needs care rather than the styling: a form boundary in the wrong place puts fields outside the
form they submit, which is invisible to a request spec and to the eye. Both have happened here
before — `profiles/edit` and `partners/requests/new` each carry a comment about it. **Verified in a
browser across 12 form pages: 0 orphaned controls, every submit inside its form and outside its
card.**

<a id="buttons-inside-a-card"></a>
**The caveat: a button may live inside a card when the card is its scope.** *Add another item* sits
in the line item card's footer because it adds a row to that card. *View all users* sits in the
admin dashboard card's footer because it expands that card's list. A pager sits in the table card's
footer because it pages that table. These are right where they are, and they use the card's
`footer:` slot, whose rule **is** full bleed. The distinction to hold onto: **a card action changes
what is in the card; a form action commits the whole form.** If pressing it would be the last thing
you do on the page, it is a form action and it goes below.

**And it never competes with the page header.** A form page's header carries navigation — *Back to
items* — and no submit, so the two rows never appear on one page arguing about which is primary.

<a id="status-is-not-an-action"></a>
**A status is not an action, and does not go in `actions:`.** That container is "at most three,
exactly one primary", which a status is none of, and a pill among buttons reads as a button that has
been greyed out. Where it goes depends on whether the heading names the pill's subject:

- **The title names the thing** — `partners/show`, whose h1 *is* the partner — so the pill rides the
  title line via `status:`, which is where GitHub, Linear and Stripe put an entity's state.
- **The title names a page** — a portal's *Dashboard*, *Distributions* — and there is no subject in
  the heading to attach to. `status:` would render "Distributions Approved". Retitling the page to
  the agency's name was tried and reverted: a spec asserts `h1` text "Dashboard" to prove a redirect
  landed there, which is a fair use of a heading that names its page.
- **So on a page-titled page the status becomes a [callout](#callouts) — or nothing.** A pill saying
  *Approved* on your own dashboard every day is noise. A pill saying *Awaiting review* is
  load-bearing but bad at the job: on the partner dashboard the request options card is hidden
  outright for an unapproved partner, and the pill was the only thing explaining that, in one word,
  in a corner, with no statement of consequence. It is a callout now, shown only when there is
  something to say, naming the consequence — *you cannot make requests* — rather than the enum
  value. `partners/profiles/show` already answered `recertification_required` this way.

Four partner-facing headers carried a pill in `actions:` after the bank's partner page was fixed for
it. `bin/design/button-audit.js` did not catch them, and could not: it counts `a, button`, and a pill
is a `span`. `spec/system/page_header_status_system_spec.rb` counts spans in the container instead.

<a id="counts-are-not-pills"></a>
**The same applies to a card's `actions:`, and a count is not a status either.** The admin dashboard
put `essentials_status_pill("20 new users")` in two card headers' `actions:` slots. Three faults in
one control: a count is not a status, a status is not an action, and **the number was wrong** —
`@recent_users` is `.limit(20)`, and `.count` on a limited relation returns the *cap*, so the card
read "20 new users" when 23 had signed up. A page size presented as a total, which is the failure
[the pagination summary](#pagination) exists to prevent.

A count belongs in the card's **`subtitle:`**, where the third card on that same page already put its
explanatory line — and it earns its place only by saying something the list below does not. The
organizations card's count *equalled* the length of the list directly beneath it, which is the
redundancy that killed the `<tfoot>` totals. So `essentials_recent_subtitle` states the period, which
nothing did before (it appeared only in the *empty* state, so a reader who saw a list was never told
what "recently" meant), and states a total only where the list is truncated: **"The 20 most recent of
23 users added in the last week."** `total:` is optional and defaults to the shown count, so adding a
`.limit` later forces the caller to say whether the number is the whole of it.

<a id="primary-position"></a>
**A primary sits at the row's alignment edge**, which is why the two rules below look opposite and
are not. A page header's actions are right-aligned, so its primary is **last**. A form's action row
is left-aligned, so its primary is **first** — `[Save] Cancel`, which is what every form in this app
does: measured across twelve, the six carrying a primary and a secondary all read that way. Getting
this backwards is easy, because the header rule is the one written down; the calendar profile form
shipped `Save progress` before `Save and review` for exactly that reason.

`button-audit` checks the header rule only. The form rule holds by construction, since
`essentials_form_for` renders the submit before anything a view appends.

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

<a id="import-and-export"></a>
**Import is always offered; Export only when there is something to export.** The five index pages
that take a CSV — vendors, donation sites, storage locations, product drive participants, partners —
all carry `Import X`, `Export`, `New X` in that order, primary last.

Four of them used to make Import the `else` of the Export branch, so **the moment a bank had one
row the importer became unreachable**. Taking on a batch is not something that only happens to an
empty list. `/partners` had it right and the rest match it now.

Export stays conditional: an empty CSV is not a useful file, and the import modal carries its own
template, so there is nothing an empty export would give you.

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

### Rich text editor

Four screens have one: organization settings (two), the admin organization form, and the admin
question editor. It is Action Text on Trix.

The **editor body** was already styled to match a text input. The **toolbar** was not — it shipped
as Trix draws it, and that is the whole defect: the field looked like the design system and the
fourteen controls sitting directly above it did not. Measured before: `#bbb` borders, a **3px**
radius against the app's 8, `1.5vw` group margins, **42x26** buttons with no radius, and a
`#cbeefa` active state that appears nowhere else in this app.

| | Trix's default | Here |
| --- | --- | --- |
| Button | 42x26, no radius | **32x32**, ghost surface |
| Group | 3px radius, `#bbb` | `rounded-lg`, slate-300 |
| Active | `#cbeefa` | `bg-brand-50 text-brand-700` |
| Icons | 14 SVG data-URIs | **Bootstrap Icons** |
| Below 768px | shrinks to 19px wide | 32px, row scrolls |

**The icons were a second icon set.** Trix draws each button with an SVG data-URI background image.
This app retired Font Awesome specifically so it would have one icon set, and then carried fourteen
icons from another one on four screens. They are Bootstrap Icons now, added as `bi-*` classes by
`trix_toolbar_controller.js` rather than written as CSS `content` codepoints — so the name is the
same one any view would write, and a missing glyph fails the way it would anywhere else instead of
silently drawing nothing. The toolbar does not exist until Trix has run, so nothing is lost by
doing it in JavaScript.

<a id="toolbar-buttons-shrink"></a>
**The phone bug was flex, not width.** Below 768px Trix narrows the buttons with
`max-width: calc(0.8em + 3.5vw)` — about 22px at 375, under [2.5.8](#target-size)'s 24. Overriding
the width changed nothing, because width was never what was being ignored: the buttons are flex
children of `.trix-button-group` inside `.trix-button-row`, and fourteen 32px buttons do not fit a
375px row, so every one of them **shrank**. `flex: none` is the fix; the row is already
`overflow-x: auto`, so the toolbar scrolls sideways on a phone like every other editor toolbar.

Trix hides each button's label with `text-indent: -9999px`, which keeps the accessible name, so the
glyph is placed absolutely with the indent undone and the label stays where a screen reader reads
it. `trix_toolbar_controller.js` makes the toolbar an ARIA toolbar — one tab stop, arrow keys
within — because Trix ships all fourteen buttons as `tabindex="-1"`.

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

<a id="button-labels"></a>
**A button label is a verb and its object, and the page supplies the rest.** Two or three words:
`New donation site`, `Promote to admin`, `Import storage locations`, `Invite user`. Measured across
the app, **41 distinct button labels: 31 are one word, 26 are two, 12 are three, and two are four.**
A create action is `New <noun>` — that is what nine of them say, so a tenth should not say
`Add New Organization`.

**Do not restate the context the button is sitting in.** `Invite user to this organization` was the
longest label in the app at five words, in the footer of a card titled **Users**, on a page whose
`<h1>` is the organization's name — so three of its five words repeated what was already on screen
twice. WCAG 2.4.4 is Link Purpose *In Context*, and the card and the heading **are** that context.
Where a longer form genuinely helps, it belongs in the thing the button opens: this one's modal is
still headed "Invite a new user to {organization}", which is where naming the organization actually
tells you something.

Sentence case applies to buttons like everything else, and this is the rule that drifts quietest:
`page-audit.rb` checks Title Case in **headings only**, so four button labels sat outside it for the
length of the migration. The check that finds them is a scan of the button helpers —
`new_button_to`, `modal_button_to`, `essentials_link_button`, `essentials_action_button`,
`submit_tag`, `button_tag` — not of `label:`, which belongs to form fields and is a separate
question.

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

<a id="person"></a>
**The app speaks to the reader as "you".** Never "my", and never third person. Counted before this
rule existed: **49 strings second person, 8 first, one using both at once**, and no third person at
all — which was correct rather than an omission, since third person ("the user should…") is
documentation voice. GOV.UK, Polaris, Mailchimp and Apple all say second person, and Apple warns
specifically against mixing "my" and "your"; Nielsen Norman tested both and found consistency
matters more than the choice. It is **52 second person and nothing else** now.

Three cases, because the eight outliers were not one problem:

| The word meant | Rule | Example |
| --- | --- | --- |
| The reader's own thing | **Drop the possessive** where it adds nothing. A partner has one profile and one account, so nothing else it could be. | "Edit my profile" → **Edit profile** |
| Something that needs distinguishing | **Keep "your".** | "Our impact" → **Your impact**, against the bank's figures |
| The product or its maintainers | **Name the party, or drop it.** | "…and how to reach us" → **…and how to get in touch** |

<a id="interface-has-no-speaker"></a>
**An interface has no speaker; a letter does.** That is the line, and it is where the rule stops.

In the app, "we" is almost always filler in front of the actual news — "We're contacting you to
notify you that your password has been changed" is "Your password has been changed" with eleven
words of throat-clearing. Twenty-five such strings went, across the interface *and* the transactional
mailers, and every one of them got shorter.

Three places keep it, and each for a different reason:

| Kept | Why |
| --- | --- |
| **The onboarding welcome email** (14 lines) | Genuine correspondence with a voice — "We're delighted to hear from you", "We're supported by the non-profit Code for GoodOps". Stripping it produces a colder, worse email, and this is the one message that is a letter rather than a notification. |
| **The privacy policy** (13 lines) | A legal document, where "we" is the party making the commitment. Rewriting it into the passive changes what it says. |
| **The marketing page** (3 lines) | Brand voice on a public page, plus a **customer quotation**, which is someone else's words and not ours to edit. |

The mailers that lost their "we" were the ones announcing something — a change, a cancellation, a
rejection. What is left is the one that is genuinely a letter. If a fourth category appears, the test
is whether a reader would expect a sender: a notification has none, a welcome does.

**One grammar defect fell out of this.** The cancellation notification said "a essentials request"
in both its HTML and text parts, and had done since it was written; rewriting the sentence to drop
"We are emailing you to notify you that" removed it. Copy nobody reads aloud is copy nobody proofs.

**A title is a phrase, not a question.** "Need help?" was the only page title in the app that was a
question, and the same feature was already called **Help** on the bank side — two names for one
thing, on both the page and the topbar link. A question is right in a *prompt*: the "Still need
help?" card on that page asks something and stays.

**Describe the whole control, not the half you were thinking about.** "Say how many of each item you
need" sat above a form whose every row is *two* controls — a "Select an item" dropdown and a quantity
— so it read as though the items were already chosen. It is "Choose the items you need, and how many
of each." Check the form markup before writing the sentence over it.

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

### Reviewing copy

Copy is reviewed like code, and in this order — the mechanical checks first, because they are free
and they are the ones that catch what review misses.

**1. Run the audit, then prove it looked at your files.**

```bash
ruby bin/design/copy-audit.rb        # six checks: 2.4.4, 1.3.3, gendered, ableist, please, shouting
```

`0 finding(s) across 0 check(s)` is the pass — the second number counts checks *with* findings. It is
also exactly what a broken audit prints, so **plant a violation and confirm it is caught in your
file**, then revert:

```
"Please review this, using the button below. It is insane."
   -> politeness filler 1, sensory instruction 1, ableist wording 1
```

That took ten seconds and is the only thing that distinguishes "clean" from "not looking". A
`copy-audit` run that reports zero because it never read the file is the same failure as an audit
reading a proxy.

**2. Then the judgement half, which no audit can do.**

| Check | Fails when |
| --- | --- |
| **[Subtitles](#subtitles) say something the title cannot** | It is a definition of the heading. "Requests / Essentials requested by partner agencies". |
| **[Buttons take a verb](#copy)**, and it is the verb that will happen | "Calculate product totals" when nothing is calculated on press. |
| **Every claim is true of the code** | "…and what each of them is allowed to do" on a page whose table is Name and Email. |
| **[One person](#person)** | Any "my" at all, or a "we" that could name its party instead. |
| **A title is a phrase, not a question** | "Need help?" where every other page is a noun or verb phrase. |
| **The sentence covers the whole control** | Copy above a two-control row that describes one of them. |

**3. Verify a claim by reading the code that implements it, not by grepping for it.**

Writing twenty-two subtitles produced two sentences that were false, and both read perfectly well.
The rule that catches them is to open the view and look. And **an empty grep is not evidence of
absence** — three of mine were wrong file paths, most memorably looking for a donation site field in
`donations/_form.html.erb` when the file is `_donation_form.html.erb`. A missing feature and a
mistyped path produce identical output.

**4. Check the partner portal separately.** It is a second product with a second audience — an agency
volunteer rather than a bank one — and it is easy to sweep the bank side and call the app done. When
this review ran, the bank side was complete and the portal still had **three pages with no subtitle
at all** and one defining "family". The audits do not distinguish the two, so a person has to.

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
required fields are marked, submits it empty and reads what came back — **and opens the four modal
forms**, which have no route of their own and so had never been audited at all. That gap is how
`New quantity request` came to carry a `required` select with no visible marker: programmatically
required, and silently. A modal is checked for marking only; an empty submit in one either navigates
away or redirects with a flash, so there is no re-rendered form to read.

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

**A requirement that belongs to a group is marked on its `<legend>`, not on each control.** The
group is what is required — a radio set, or a pair where either one will do.

**A conditional requirement goes on the legend too, and is said once.** It used to be written into
both labels — `Phone (phone or email required)`, and the same sentence again on Email — which made
the *accessible name* of the field carry the condition and repeat it. The label names the field; the
legend states the rule; neither field carries `aria-required`, because neither is required alone.

```erb
<fieldset>
  <legend>Contact details <span>— a phone number or an email address is required</span></legend>
  <%= f.input :phone, label: "Phone" %>
  <%= f.input :email, label: "Email" %>
</fieldset>
```

`form-validation-audit` reads a legend for any field now, not only for a radio or checkbox, so a
condition stated there still counts as marked.

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

<a id="background-downloads"></a>
### A long export downloads in the background

A big CSV used to look like a hung page — the browser sat on the request with nothing to show.
`handle_csv_export` redirects instead, with two things on the flash: a **notice**, which the flash
strip draws like any other message, and **`trigger_csv_download`**, a boolean the layout's
`shared/essentials/csv_download` partial turns into a hidden element that fetches the file and
saves it.

Two rules fall out of that, both learned the hard way:

- **A flash entry that is a flag, not a sentence, goes in `EssentialsUiHelper::NON_MESSAGE_FLASH_KEYS`.**
  The strip renders every key it finds and `true` is not blank, so an ungated flag draws a message
  bar reading *"true"*.
- **An export link carrying a non-filter param must survive the filter rewrite.** `auto_submit`
  rebuilds an export href from the filter form, which dropped `export_csv=true` — so the first
  time anyone touched a filter, the export silently reverted to a foreground request. It now keeps
  any param on the link that the form does not supply.

The message is a flash rather than a pop-up **because there is no toast in this design system, and
`toastr` has been removed.** If a transient pop-up is ever genuinely wanted, it needs building here
rather than importing — see below for what happened to the last one.

<a id="messages-raised-after-load"></a>
### A message raised after the page loaded

**Append it to `[data-flash-region]`, rendered from `shared/essentials/flash_message`.** That is the
same partial the server-side strip renders each of its messages with, so a message raised by
JavaScript is the same object as one that arrived with the page — same tint, same glyph, same
`data-flash` hook a spec can find it by.

**The strip is always in the DOM, and hides itself while empty.** `.flash-strip:not(:has([data-flash]))`
is `display: none`, so an empty strip costs no space and appending a message is all it takes to
reveal it. CSS rather than a class the server toggles, so nothing has to remember to switch it back
off when the last message goes.

This exists because `barcode_items/create.js.erb` used `toastr.success(...)` and **nobody could see
it.** The essentials layouts load only `tailwind.css`; measured on `/donations/new`, **zero toastr
CSS rules load**, so the container rendered `position: static` with no background or padding,
appended at the foot of the document — **y=1284 on a 900px viewport**, below the fold. The scan
worked and said nothing. `toastr` is gone from the importmap and from `application.js` now, that
being its last caller.

**Assert these by `[data-flash]`, not by text.** The spec covering that message passed the entire
time it was invisible, because `have_content` finds text in the DOM whether or not it is on screen.

<a id="detail-list"></a>
### A record's details are a `<dl>`, and long ones are banded

**`essentials_detail` renders one field** — a `<dt>`/`<dd>` pair in a `<div>`, which is how HTML5
groups them inside a `<dl>` — on a `grid gap-x-6 gap-y-4 sm:grid-cols-2`. **A blank value is the em
dash**, which is why the helper takes the value rather than leaving each caller to write
`presence ||`: "Not defined" reads as a sentence and makes an empty field look like it says
something. `wide: true` spans both columns, for a paragraph, a list or an image.

**Past a handful of fields, group them into bands** rather than one long list —
`border-y border-slate-200 bg-slate-50 px-5 py-3` on the heading, `first:border-t-0` so the top one
does not double with the card header's rule. It is the line item card's band, marking a change of
kind, and it is the reason **a detail card needs no `<hr>` at all**.

<a id="a-band-has-no-last-case"></a>
**A band has no special case for the last one.** Every band is `px-5 py-4`, including the final one.
The card is rendered `padded: false` so its body supplies no padding of its own, and a last band
that drops to `pt-4` leaves its final field **1px** from the card's bottom edge against the 16px
every band above it has. If a container's padding is the reason a child can skip its own, check
that the container actually has some.

### Tag input

```erb
<%= render "shared/essentials/tag_input",
      id: "organization_request_unit_names", name: "organization[request_unit_names]",
      label: "Custom request units", hint: "Type a unit and press Enter.",
      values: current_organization.request_units.map(&:name) %>
```

For a free-form list of short values — the custom request units are the one use today. Type a word
and press **Enter**; comma and Tab also commit, and Backspace on an empty box removes the last chip.
Duplicates are refused case-insensitively, so `Pack` cannot join `pack`.

**The `<select multiple>` is the field.** It is what submits — a repeated `name[]` — and the
controller keeps it in sync and draws the chips from it. Hiding it is gated on
`[data-tag-input="ready"]`, which the controller sets only after the chips exist, so with no
JavaScript the native multi-select is exactly the control it always was. Same arrangement as
[the table rail](#the-rail).

<a id="tag-input-hide-rule"></a>
**That hide rule lives outside `@layer components`,** with the third-party overrides. The select
carries `block w-full` from `SELECT_CLASSES`, and **a utility beats a layered rule however specific
the layered one is** — written in the components layer first, it did nothing at all and the select
stayed visible underneath the chips.

It replaced select2 in free-tagging mode with `select2-hide-dropdown-value`, which was reported as
not intuitive and was: it looked like a select, so the first thing anyone did was click it expecting
a list, and nothing opened. Nothing on screen said the interaction was "type, then comma". Measured
before: the remove target was **9&times;21** against [2.5.8](#target-size)'s 24&times;24, and the
chips were select2's own `#aaa` border on `#e4e4e4`, which appear nowhere else here. Now a 24px
button in a brand-50 chip. Options and reasoning in
[docs/mockups/request-units.html](docs/mockups/request-units.html).

<a id="cta-icons"></a>
**Every action CTA carries a leading icon.** Measured across 39 screens in three roles: **27 of 27**
page-header CTAs have one, and they agree on which — `bi-plus-lg` to create, `bi-upload` to import,
`bi-download` to export. A create action anywhere else takes the same treatment: the users card's
invite button was the one action button without one, and takes `bi-person-plus`, pairing with the
`bi-person-dash` already used to remove a user.

Two things are deliberately **not** CTAs and correctly have no icon: **pagination** controls, and
**"View all …"** links, which are navigation rather than action and are consistent among themselves
across five screens.

<a id="inline-code"></a>
**An inline literal is a tinted chip.** `<code>` had no styling at all, so the four substitutions in
the email hints — `%{partner_name}` and friends — rendered as bare monospace mid-sentence and read
as a templating bug that had leaked into the page rather than as something to type.

<a id="form-section"></a>
**A long form is banded the same way a long record is.** `shared/essentials/form_section` is the
detail band's counterpart: a full-bleed tinted `<legend>` and the fields under it, in a card
rendered `padded: false`. So the organization page and the settings form that edits it are
sectioned identically.

It is a real `<fieldset>` with a real `<legend>`, so the group is still announced.

<a id="never-border-a-fieldset"></a>
**Never put a border on a `<fieldset>` that has a `<legend>`.** A legend is rendered *in* its
fieldset's top border and the browser cuts a gap for it, so `border-t` on the fieldset draws a rule
that **starts where the legend text ends** and runs to the right edge. That is a fieldset rendering
artefact, and the settings page carried seven of them. A legend also shrink-wraps, which is why it
looks unstylable — `display: block; width: 100%` makes it an ordinary block, and then it can be the
band. Both are in `.form-section`.

<a id="shell-first-audit"></a>
**`bin/design/shell-first-audit.rb` is the check for this.** Every other audit in `bin/design`
answers *is anything from the old system still present?* — a shell-first page passes all of them.
This one asks *is this built the way the new system builds things?* It looks for a `<table>` that is
not `.data-table`, a bare `<hr>`, `float-*`, a `<br>` standing in for a margin, four or more flat
`<p>` label pairs where a `<dl>` belongs, a hand-written card header, a button's classes copied out
instead of `essentials_button_classes`, and a Font Awesome icon.

**Four of its checks were narrowed after they produced false positives**, which is worth knowing
before adding a fifth:

- **Mailers and `static/` are skipped.** HTML email is laid out in tables by necessity, and the legal
  pages are complete documents `StaticController` renders with `layout false` and their own
  `<style>`. Neither is built from this design system.
- **A `<br>` between two lines of text is correct HTML.** An address, a second line in a cell. Only
  a doubled `<br>` or one straight after a block closes is a margin in disguise — unnarrowed the
  check reported 31 and **29 of them were right**.
- **A detail pair needs `font-medium`, and four of them.** `text-xs text-slate-500` alone is the
  documented *meta* style for a timestamp; `font-medium` is what `essentials_detail` puts on a `<dt>`,
  so it marks a label *above* a value rather than a stat card's caption *below* a number.
- **A hand-written card header only counts when there is a card.** A modal's header is the same
  markup exactly — hairline rule, heading, close button — and matching markup alone reported all
  fourteen modals, every one of them fine. Three of those have their `<dialog>` in
  `confirmation_controller.js` rather than in the template, so looking for `<dialog>` would not have
  excluded them either.

Like `page-audit.rb` and `copy-audit.rb`, it **proves its detectors against a probe table before
reporting anything** and refuses to run if one is wrong — a check that silently matches nothing
reports a clean sweep, which is the failure mode that looks like success. The probe table earned its
place immediately: `"…px-5 py-4">\n<h2>"` in a single-quoted Ruby string is a literal backslash and
an `n`, not a newline, so the card-header detector was dead on arrival and said so.

<a id="never-a-bare-hr"></a>
**Never a bare `<hr>`.** Preflight sets `border-color: currentColor`, so an unstyled `<hr>` draws in
the **text** colour. The organization page carried six of them and they rendered
`oklch(0.208 0.042 265.755)` — **slate-900**, six near-black rules through a card whose every other
divider is a slate-200 hairline. That page is the worked example for all of this: its shell was
migrated and its 28 fields were not, so it passed every automated check — 200, no legacy class, no
JS error — while looking nothing like the rest of the app. What it actually had:

| | Before | After |
| --- | --- | --- |
| Field markup | 28 `<p>` pairs, **zero `<dl>`** | 28 `<dt>`/`<dd>` in eight `<dl>` |
| Dividers | 6 `<hr>` in **slate-900** | 8 bands, slate-200 |
| Vertical gaps | **7 different** (24–93px) | **one**, 16px |
| Labels | **15 of 28** Title Case | sentence case |
| Icons | 14, one per row | none |
| Invalid nesting | `</address>` closed inside an `if`; **2 empty `<p>`** the browser made | valid |

**It did not get shorter, and that is worth recording** because the preview predicted it would:
1,519px to **1,516px**. The eight bands cost ~368px, almost exactly what two columns save. The
argument for the rebuild is consistency and the broken markup — not height.

<a id="callouts"></a>
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
  The card reserves a strip (`[data-railed]`) exactly the rail's own 24px, so at rest it covers
  nothing; the footer drops its own rule where the rail has settled, and the settled bar sits on the
  bottom edge of its track — see [the strip](#rail-strip).
- **It has two states and they are styled differently.** `data-floating` while it rides the fold,
  where it lies on live rows and needs a backdrop to be read against them; bare while settled, where
  nothing is behind it. That is the majority state, not the exception — 73% of the scroll on
  `/distributions`. See [the rail's ground](#rail-backdrop).
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

<a id="pin-only-what-scrolls"></a>
**Pin the identifying column only on a table that overflows.** `.pin-col` earns its place on the six
wide tables that scroll sideways; on a table that fits it freezes a column that was never going to
move. `/users` is Name and Email, and pinned, "Name" held **417px of a 740px** landscape phone. Two
columns never scroll, so there is nothing to keep in view.

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

<a id="pagination"></a>
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
