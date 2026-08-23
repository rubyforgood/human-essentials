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
