# To do

Things found, verified, and deliberately not fixed at the time. Each one names what it is, why it
was left, and what fixing it involves — so picking one up does not start with re-deriving it.

This is not a wish list. Nothing goes here that has not been confirmed in the code, and anything
fixed comes out in the same commit as the fix, with a row in [changelog.md](changelog.md).

## Test suite

**`bundle exec rspec --seed 43125` fails 7 examples in
`spec/services/reports/adult_incontinence_report_service_spec.rb`**, all of them
`create(:kit, organization: organization)` raising `Validation failed: Name has already been
taken`. It is order-dependent, not date-dependent: the file passes 8/8 on its own, and the same
seed reproduces the same seven failures on a tree with no local changes at all — checked by
stashing. Something earlier in that ordering leaves a kit name behind, or the kit factory's
`sequence(:name)` collides with one created through `kit_item`'s `after(:build)`. Reproducible,
which is the hard part of a flake already done.

## Design system

**The getting-started step badges repeat their class string five times.**
`app/views/dashboard/_getting_started_prompt.html.erb` writes
`mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full bg-brand-100 text-xs font-semibold text-brand-700`
once per step, for five steps. It is a numbered badge rather than an icon tile — `rounded-full`,
which is the line `page-audit.rb` draws between the two — so the tile sweep correctly leaves it
alone, and five copies in one file is a milder problem than one copy hiding in another component.
Fix: a small helper or a loop over the five steps. The steps carry different markup in their
labels (links, parenthetical user-guide links), so a loop needs the label as a block.

**The item list's pager could move to the card's `footer:` slot.**
`app/views/items/_item_list.html.erb` renders its pagination chrome inline. That was forced while
the card wrapped five tab panels; the card wraps one table now, so `footer:` would work. Left
because it renders identically and the move was not part of the tabs change. Comment in the file
says the same.

## Accessibility

**`/partners/family_requests/new` shows only an error summary, with no inline errors and no
`aria-invalid`.** The change log entry for `fc4e62d32` claims the form audit had no findings; it
has one now, and it is not from recent work — the form is `form_with` with no `f.input`, so it
never touches simple_form, and running the pre-change audit against the current app reports the
same thing. Fix: the form needs per-field error rendering, which for a non-simple_form form means
doing by hand what the `:essentials` wrapper does.

**The account menu trigger has `aria-expanded` with no `aria-controls`.** Both top bars. The
panel has no `id` for it to point at. design.md's accessibility rules ask for both on anything
that opens a region. Pre-existing; noticed during the avatar change and not folded into it.

## Filters and forms

**`admin/barcode_items` offers one filter where its non-admin twin offers three.** The two pages
are otherwise the same page now. Adding base item and barcode value would need `by_base_item_partner_key`
and `by_value` permitted in `filter_params` — both are real scopes on `BarcodeItem`, so it is
safe, but it is a feature rather than consistency work.

## Documentation

**`docs/table-audit.md` has not been re-run since 2026-08-18.** It covers 19 bank-side and 8
admin tables against a running app, asking how many visual weights a table's row actions use.
Nothing in the recent work obviously invalidates it — row actions were not touched — but three
tables were rebuilt (`admin/barcode_items`, `admin/ndbn_members`, the item catalogue's five) and
the count of tables in `app/views` is now 78. Worth re-running rather than re-reading.
(`docs/view-audit.md` was in the same state and has been brought up to date.)

## Seven tables with no empty state, deliberately

A sweep for a `<tbody>` or `.data-table` driven by a `.each` with no
`shared/essentials/empty_state` in the file found sixteen. **Nine were built** — see the change
log. These seven are the remainder, and each shows the line items of a *saved* record whose model
validates that it has at least one, so the empty branch is unreachable:

`adjustments/show`, `audits/show`, `distributions/validate`, `transfers/show`,
`transfers/_validate_modal`, `partners/requests/validate`, `requests/show`.

Worth revisiting only if one of those validations is relaxed. Written down so the next sweep does
not spend an afternoon rediscovering that they are fine.

## The document can be swiped sideways when a table overflows

`html { overflow-x: clip }` is set for exactly this and **does not work**. Measured on
`/purchases` at 375px *before* any of the `.notes` work: the `<h1>` could be swiped from
`left: 16` to `left: -670`, taking the heading and every control off screen. The computed style on
`html` really is `clip`, no element overflows once clipping ancestors are accounted for, and the
whole ancestor chain of the table is properly clipped — Chrome still counts the clipped table in
the root's scrollable overflow and lets the viewport pan.

`body { overflow-x: clip }` was tried and did not help; the change was reverted rather than left
in as dead CSS.

**`responsive-audit.js` does not catch it**, which is the more useful half of this finding. It
compares `scrollWidth` with `clientWidth`, and that is the very number the `clip` rule was written
to neutralise — so the audit reads a proxy and reports clean while the page pans. The honest check
is the one used here: scroll the window and see whether the `h1` moves.

Not fixed because it is pre-existing and its own piece of work. The `.notes` pass made it
*reachable at 1440* on `/purchases` for a while by widening the table past its scroll region; the
column is capped at 16rem specifically so that no longer happens.

## A column of links has no convention yet

`item_categories/index` renders "Items in category" as a `<ul>` of anchors — 651 characters in the
worst row, making it 439px tall. It cannot take `.notes`: clipping would leave focusable links
invisible. It needs a count, or the first few and a "+N more". One table, so it is recorded rather
than invented.

## The distributions table has more columns than it has room for

Analysed in `docs/mockups/distributions-columns.html` with per-column evidence. **Two claims
previously recorded here were wrong** and are corrected there: shipping cost is present on **50%**
of rows, not empty on all of them, and the created and issued dates **differ on all 24 rows**, so
they are two facts rather than a duplicate.

The measured shape of the problem:

| Change | Table width | Against the 1,118px region |
| --- | --- | --- |
| Today | 1,759px | scrolls |
| Actions as one action + a menu | 1,508px | scrolls |
| … and drop the three that are one click away | 1,153px | scrolls (35px over) |
| … and drop Initial allocation too | 1,118px | fits exactly |

**Dropping columns alone never makes it fit, and the biggest single win is not a data column at
all**: Actions is **331px**, the second-widest column in the table, holding up to five labelled
buttons. One action plus an overflow menu is ~80px — a 251px saving that costs no data. That is the
recommendation, and it needs its own preview because an overflow menu is a component this app does
not have. It would also fix `/items`, `/vendors` and `/requests`, which carry three to five actions
each.

