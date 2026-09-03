# To do

Things found, verified, and deliberately not fixed at the time. Each one names what it is, why it
was left, and what fixing it involves — so picking one up does not start with re-deriving it.

This is not a wish list. Nothing goes here that has not been confirmed in the code, and anything
fixed comes out in the same commit as the fix, with a row in [changelog.md](changelog.md).

## Test suite

**The `--seed 43125` recipe is stale, and the flake is unreproduced.** The entry recorded 7
failures in `spec/services/reports/adult_incontinence_report_service_spec.rb`, all
`create(:kit, organization: organization)` raising `Validation failed: Name has already been
taken`. Re-running the exact command on 2026-09-03 gives **3272 examples, 0 failures**.

A seed is only a reproduction against an identical set of loaded files, because RSpec shuffles the
groups it loaded. **31 spec files have been added and 1 removed since the entry was written**
(267 → 297), so seed 43125 stopped selecting that ordering within about a day of it being
recorded. Four further seeds were tried — 11111, 22222, 33333, 44444 — all **0 failures**, and no
run contained the string `has already been taken` at all. Five full-suite runs, nothing. That is
not proof the flake is gone; it is proof the recipe no longer finds it.

One cause of that exact message *was* found and fixed — `Seeds.seed_base_items` was not
idempotent — but it is guarded in the factory (`if BaseItem.count.zero?`), so it is not obviously
the path the report hit, and that should not be claimed. If it recurs, do **not** start from a
seed: run to a failure, then `rspec --bisect` on the failing seed, which finds the minimal
ordering that reproduces it and does not go stale when a spec file is added.

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

**Server-rendered error summaries are never focused.** A validation failure re-renders the page
with the summary at the top, and focus stays on `<body>` — measured on
`/partners/family_requests`, `document.activeElement` is `BODY` after the re-render. `role="alert"`
is reliable for content *inserted* into a live page; on initial page load screen readers vary,
because the region is present when the accessibility tree is first built rather than changing
afterwards. The usual fix is `tabindex="-1"` on the summary plus focusing it on load, which also
puts a keyboard user at the error instead of at the top of the document.

Not done here because it is app-wide, not one page: `essentials_error_summary` is rendered by 38
views and `partners/requests/_error` by 3 more, so doing it on one page would make the behaviour
inconsistent. `essentials_error_summary` already emits `data: {error_summary: true}`; no
JavaScript reads it, but 30 system-spec assertions use `[data-error-summary]` as their selector,
so it is a load-bearing test hook rather than dead markup — and it is the hook to hang the focus
behaviour on.

**`"completely empty request"` reaches partners as user-facing copy.** It is a model validation
message in `app/models/request.rb:89`, and it renders verbatim as a bullet in the error callout —
lowercase, unpunctuated, phrased for a developer. Three specs assert the exact string
(`spec/models/request_spec.rb:143`, `spec/services/partners/request_create_service_spec.rb:35`,
`spec/services/partners/family_request_create_service_spec.rb:27`) and all three request types
share it, so rewording it is a model change with a wider blast radius than the copy fix it sits
next to. Left deliberately; the surrounding guidance sentence now carries the actionable part.

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

## Skills: not yet available outside this repo

The five skills in `.claude/skills/` are only active when working *in this repository*. Claude reads
skills from two places — the current repo, and `~/.claude/skills/` — and nothing has been written to
the second.

**Asked to be reminded rather than done now.** The proposal is a symlink, not a copy: one set of
files, in git, visible from every project.

```bash
mkdir -p ~/.claude/skills
cd /Users/gia/essentials/worker-toolkit-human-essentials/repo
for s in audit-suite design-system-migration evidence-discipline wcag-conformance session-durability; do
  ln -s "$PWD/.claude/skills/$s" ~/.claude/skills/$s
done
```

It writes five pointer entries into `/root/.claude/skills/` and nothing else. The risk is that a
symlink points at a path: if this repo moves or is deleted, the skills silently stop working. A copy
avoids that and introduces two versions that drift, which is the worse failure.

Unverified: whether this client actually reads `~/.claude/skills/` on this setup — that directory
has never existed here. Confirm by opening a different project and seeing whether the skills appear.

## 24 Title Case labels on the partner profile forms

House style is sentence case, and `page-audit.rb` enforces it on **headings only** — form field
labels were never in its scope, so these sat outside a normative rule for the whole migration.

Measured 2026-09-03: **24 distinct labels** across `app/views/partners/profiles/`, from
`"Agency Age"` to `"Do You Verify The Income Of Your Clients?"`.

Left because it is a large user-visible copy change across **two parallel trees that must stay in
step** — `profiles/edit/` and `profiles/step/` render the same fields — and because it deserves to
be a decision of its own rather than a rider on something else. Fixing it means extending the
sentence-case check to `label:` as well as headings, or it will come back.

## Seven dead anchors in design.md

Seven `](#...)` links point at anchors that do not exist — `#contrast`, `#target-size`, `#pills`,
`#icons`, `#interaction`, `#reports`, `#behind-a-proxy-or-tunnel`. Down from twelve; the rest were
fixed in passing.

Each is either a section that was renamed or one that was never written. Fixing means deciding which
per link, so it is small but not mechanical. Worth a check in `page-audit.rb` afterwards so the next
one is caught when it is written.

## `ignored_columns` for the dropped address column

`StructuredAddress` still carries `self.ignored_columns += ["address"]`. The column was dropped by
`20260901200000`, so this is now a no-op.

It was kept deliberately for one release, for the mirror image of the reason the drop was staged:
new code meeting a database where the migration has not run yet. **Remove it once that migration has
been deployed everywhere.** This is the last thing left of the address change.

## The design skill has no adapter

`.claude/skills/design-system-migration/templates/adapter.md` describes the shape — five sign-in
values and a command that lists every screen — but no Rails/Tailwind adapter has been written, and
none of the 33 audits here have been generalised.

Deliberate, and the reasoning is in `docs/skill-proposal-v2.md`: there is no evidence yet about
which assumptions are shared between stacks, and inventing an adapter from a sample of one is the
mistake at prompt `[158]`, which cost 28 unevidenced claims. **Do this after the core has been used
once on another app**, not before.

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
all**: Actions was **331px**, the second-widest column in the table, holding up to five labelled
buttons.

**That half is done.** `shared/essentials/row_actions` was built and the column is now **76px** —
measured at 1440 on 2026-09-03, a 255px saving against the 251 predicted. The table is **1,521px**
against a 1,118px region, down from 1,759.

**It still scrolls, by 403px.** What remains is the column question the table above sets out:
dropping the three that are one click away, and possibly Initial allocation. That is a data
decision rather than a layout one and wants its own preview, because removing a column a user reads
is not the same kind of change as collapsing buttons they can still reach.

