# To do

Things found, verified, and deliberately not fixed at the time. Each one names what it is, why it
was left, and what fixing it involves — so picking one up does not start with re-deriving it.

This is not a wish list. Nothing goes here that has not been confirmed in the code, and anything
fixed comes out in the same commit as the fix, with a row in [changelog.md](changelog.md).

## Test suite

**Three flakes fixed on 2026-09-04, and eight consecutive clean runs since.** Before them, 15
full-suite runs produced 5 failures across 4 distinct examples, never the same one twice — about
one run in three. Afterwards: **3,298 examples, 0 failures, 1 pending, on eight fresh seeds.**

| Example | Cause |
| --- | --- |
| `request_system_spec:119` | no `wait_for_filters` after `click_on "Clear all"` — the only clear-all in the suite without one |
| `donation_site_spec:198` | the spec queried `DonationSite.active`, unscoped and unordered, where the app queries `current_organization.donation_sites.alphabetized.active` |
| `audit_system_spec:74` | `await_select2` took the starting `data-select2-id` from a non-retrying `Nokogiri` snapshot; before select2 initialised that read nil, so it waited for id `1` |
| *(one more)* | `PG::TRDeadlockDetected` — self-inflicted, a second `rspec` against the same test database |

**What eight clean runs does and does not support.** At the previous rate it would happen about
**4%** of the time, so that rate almost certainly no longer holds. It does *not* establish zero: a
5% residual rate would still give eight clean runs two times in three. If a failure appears, treat
it as new, keep the output, and diagnose by reading — all three above were solved that way, none by
bisecting.

**The `--seed 43125` entry is closed as unreproducible.** It recorded 7 failures in
`adult_incontinence_report_service_spec` from `create(:kit)` raising `Name has already been taken`.
It has not reproduced in **23 full-suite runs** across 2026-09-03 and 04, and no run has contained
that string at all. A seed is only a reproduction against an identical set of loaded files, and 31
spec files were added within a day of it being written, so it stopped selecting that ordering almost
immediately. `Seeds.seed_base_items` was found non-idempotent in the same area and fixed, which may
or may not be related — it is guarded in the factory, so it should not have been reachable. Kept as
a record rather than a task: if those seven ever return, this paragraph is the context.

## Design system

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

