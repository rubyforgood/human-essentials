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

**The suite has low-rate background flakiness, and a seed is not a handle on it.**
Characterised on 2026-09-04 across **15 full-suite runs**: 5 failures, **4 distinct examples, and
never the same example twice**. Seed 20085 gave a failure then two clean runs on identical code;
seed 51001 gave `donation_site_spec:198` on one run and `audit_system_spec:74` on the next. So it
is **timing, not ordering** — which also means `--bisect` is the wrong tool, since it assumes a
failure that an ordering reproduces.

Seen so far, and what each looked like:

| Example | Signature |
| --- | --- |
| `request_system_spec:119` | six `<<ERROR>>` stale reads after `click_on "Clear all"` — **a real missing wait, fixed** |
| ~~`audit_system_spec:74`~~ | `await_select2` exhausting a 10-second wait — **diagnosed and fixed** |
| ~~`donation_site_spec:198`~~ | a *model* spec, so not browser timing — **diagnosed and fixed**, see below |

**All three had genuine, identifiable causes, and all three are fixed** — including the select2
one, which was written off here as "the container being slow" before anyone read it. It was not:
`await_select2` took the starting `data-select2-id` from a single non-retrying
`Nokogiri::HTML.parse(page.body)`, so when the snapshot preceded select2's initialisation the
attribute was absent, `nil.to_i` gave **0**, and it waited ten seconds for an id of `1` that never
comes. Its wait selector also dropped the element it was given and matched any `select` on the
page. Proven by rebuilding the old selector from a nil id and getting the failure message back
byte-for-byte.

**The donation-site one is fixed.** It called a bare `DonationSite.active` where the app runs
`current_organization.donation_sites.alphabetized.active` — unscoped by organization, and unordered
while the assertions indexed `.first` and `.second`. Postgres promises no order without `ORDER BY`;
a sequential scan returns heap order, and the `before` blocks `update` a row, which writes a new
tuple at the end of the heap, so the expected order held by accident until one run in fifteen. The
spec now runs the query the app runs, with two guards that each fail against the old one.

**How to work on this, learned the expensive way**: run to a failure and *keep the output* — the
seed alone is worthless here. Do not run a second `rspec` against the same test database while a
run is in flight; it manufactures `PG::TRDeadlockDetected` in an unrelated system spec, which cost
a run before it was recognised.

## Design system

**`"detected a unknown item_id"` is the last developer-facing error string partners can see.**
`app/services/partners/family_request_create_service.rb:57`. Unlike the two fixed on 2026-09-04 it
is a should-never-happen guard — it fires when a submitted `item_id` is not in the partner's
requestable set — so a partner reaching it has hit a bug rather than made a mistake, and the copy
should probably say that and ask them to contact the bank, rather than being tidied into a sentence
about item ids. Grammatically wrong as well ("a unknown").

**The cancellation reason claims to be required and is not.** On
`/requests/:id/cancelation/new` the label carries a `*` and the textarea carries
`aria-required="true"`, but there is no HTML `required` attribute and
`RequestDestroyService` does not validate the reason — a blank one saves, and the partner's email
reads "Reason Provided: N/A". Found on 2026-09-04 while fixing the redirect on that form.

The form is lying either way round, so it needs a product call rather than a patch: **make it
genuinely required** (validate in the service, add the attribute) or **genuinely optional** (drop
the `*` and the `aria-required`). Recommendation: required. A cancelled request with no recorded
reason is the case the partner email handles worst, and the field is already presented as
mandatory, so enforcing it changes no one's expectations.

**One legacy button helper survives in `app/views`.** `organizations/_header.html.erb:23` calls
`edit_button_to`. It is in a page header rather than a table cell and renders `:primary`, which is
what design.md asks a page's single main action to be — correct output from a legacy call. The
table-cell grep that found nine of these now returns nothing.

**The brand link class is written out 40 times across 26 views.**
`font-medium text-brand-700 hover:text-brand-800` — measured 2026-09-04 while extracting the step
badge from the getting-started guide. Unlike that badge it is genuinely app-wide, so it is a
convention rather than a local copy-paste, and collapsing it means either a helper at 40 call sites
or a component class in `application.css`. The second is closer to how `.data-table` and
`.table-scroll` already work here. Left because it is a 26-file change with no visual effect, which
is the kind that wants its own commit and its own review.

**Two hand-rolled copies of the avatar disc remain**, in `layouts/_essentials_topbar` and
`layouts/_essentials_partner_topbar`: `h-8 w-8` versions of what `essentials_step_number` now
encapsulates at `h-5 w-5`. Not merged, deliberately — see the note on the helper — but if a third
size ever appears, that is the moment to make it one component with a size argument.

**The item list's pager could move to the card's `footer:` slot.**
`app/views/items/_item_list.html.erb` renders its pagination chrome inline. That was forced while
the card wrapped five tab panels; the card wraps one table now, so `footer:` would work. Left
because it renders identically and the move was not part of the tabs change. Comment in the file
says the same.

## Filters and forms

**`/admin/barcode_items` has no seeded data, so it cannot be eyeballed.** `BarcodeItem.global.count`
is **0** in the development database while 13 org-scoped barcodes exist, so the admin page renders
an empty state and its filters cannot be exercised in a browser — the `by_value` filter added on
2026-09-04 had to be verified by request spec instead. A couple of global barcodes in `db/seeds.rb`
would make the screen reviewable. Small, but it is the reason a filter sat inert on this page for
years without anyone noticing.

## Skills: not yet available outside this repo

**Standing item, asked for twice.** The five skills in `.claude/skills/` — **17 files, 1,383 lines**
as of 2026-09-04 — are only active when working *in this repository*. Claude reads skills from the
current repo and from `~/.claude/skills/`, and **nothing has ever been written to the second**:
that directory does not exist on this machine (checked 2026-09-04).

Most of what is in them is not specific to this app, this stack, or even to design —
`audit-suite`, `evidence-discipline` and `wcag-conformance` are about method — so the whole of it
is currently unavailable to every other project.

**The proposal is a symlink, not a copy**: one set of files, versioned in this repo, visible from
everywhere.

```bash
mkdir -p ~/.claude/skills
cd /Users/gia/essentials/worker-toolkit-human-essentials/repo
for s in audit-suite design-system-migration evidence-discipline wcag-conformance session-durability; do
  ln -s "$PWD/.claude/skills/$s" ~/.claude/skills/$s
done
```

It writes five pointer entries into `/root/.claude/skills/` and nothing else. **The tradeoff**: a
symlink points at a path, so if this repo moves or is deleted the skills silently stop working. A
copy avoids that and introduces two versions that drift — which is the worse failure, and the one
this project has spent a week finding in its own documents.

**Still unverified**, and it is the one thing worth checking before relying on it: whether this
client reads `~/.claude/skills/` on this setup at all. Confirm by running the loop, opening a
different project, and seeing whether the skills are offered. If they are not, the answer is a copy
into whatever directory this client does read, and the drift problem comes back and needs a
different solution.

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

## The sideways swipe: closed, both halves of the entry were wrong

Kept as a record because the entry was confidently wrong twice, and the way it was settled is the
reusable part.

**The page does not pan.** Checked at 320px and 375px across all 154 routes: nothing swipes. Then
checked properly, by removing `html { overflow-x: clip }` entirely and rebuilding — still nothing
pans, `root 320/320`, `body 320`. The layout no longer overflows the root at all, so there is
nothing left for the rule to clip. The `.notes` column cap is the likely reason. The rule stays as
a guard; it is simply no longer load-bearing on any screen we have.

**`responsive-audit.js` was never blind to it.** The entry said it "compares `scrollWidth` with
`clientWidth` … reads a proxy and reports clean while the page pans", and asked for a check that
swipes and watches the `h1`. That check was already in the audit — added in `cfeee9130` on
**2026-08-21**, three days *before* this entry was written on 2026-08-24. It uses a real
`page.mouse.wheel` gesture, and `bodyOverflow` is only its `else` branch. Proven with a positive
control: a 2000px element with the clip rule removed pans the page 900px, and the audit reports
`swipes 900px sideways`.

**The first control was invalid, which is the lesson.** Removing the clip rule on its own produced
no pan and an audit that said "clean" — which looks exactly like a false negative and is not one.
Nothing overflowed, so there was nothing for clipping to suppress. A control for a *guard* has to
restore the condition the guard exists to suppress, not just remove the guard. Two changes were
needed together: clip off **and** overflowing content.

One real gap was found and hardened: the gesture sat inside `if (anchor)`, so a screen with no
`<h1>` skipped the swipe entirely. That is 0 of 151 screens today. In the case tested, the
`bodyOverflow` fallback still flagged the page — with the wrong message — so the old code was not
blind there. The case it would genuinely have missed is the original bug's own signature: clip on,
body not overflowing, page pans anyway, no heading. That last step is reasoning, not a
measurement; it could not be reproduced, because the pan itself no longer happens.

