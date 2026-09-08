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

**`UiHelper` is a retained shim, not outstanding work — the entry that said otherwise was wrong.**
It read "one legacy button helper survives", which implies a straggler in an otherwise finished
migration. Measured 2026-09-04 and re-measured 2026-09-08, unchanged: **11 of its 27 methods are
live**, `submit_button` alone in 18 files, and `migration-map.md:180` records the decision to keep
them — "unchanged API, design system output; `type:`/`size:` map onto variants". It emits design
system classes, not Bootstrap. The nine that genuinely mattered were *table cells*, where `type:
"primary"` produced a filled button in a row, and that grep returns zero. `edit_button_to` in a
page header renders `:primary`, which is what design.md asks a page's main action to be. **There
is nothing here to complete.**

**The avatar disc is `essentials_avatar_disc`, and the deferral that kept it duplicated was
wrong.** The entry said merging it with `essentials_step_number` needed a size and a semantics
argument — true, and beside the point. The two copies were *identical to each other*, so extracting
them needed no argument at all; the question about `step_number` was a different question, and
deferring the first because of the second is how a two-line job survives a migration.

Worse, both copies were **buggy**: they passed `display_name`, which returns the literal
`"Name Not Provided"`, so a nameless user's avatar read **"NN"** — 9 such users in the development
database. The partner bar looked like it guarded against that with
`display_name.presence || email`, but `display_name` is never blank, so the fallback was dead code
and it showed "NN" too. The trigger's `aria-label` had the same fault, so two different users
announced as *"Account menu for Name Not Provided"* — the fault this project already found and
fixed once in `users/_organization_user`.

`essentials_step_number` stays separate, and that half of the reasoning holds: one is a person, the
other a position in a list.

## Skills: not yet available outside this repo

**Standing item, asked for three times.** The five skills in `.claude/skills/` — **18 files, 1,599
lines**, re-measured 2026-09-08 — are only active when working *in this repository*. Claude reads
skills from the current repo and from `~/.claude/skills/`, and **nothing has ever been written to
the second**: that directory still does not exist on this machine (re-checked 2026-09-08). The
earlier figures here said 17 files and 1,383 lines, which was true on 2026-09-04 and drifted as the
audit and evidence skills were extended.

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

**Verified 2026-09-08, and it was the one thing worth checking before relying on it.** The premise
had never been tested here — the directory has never existed on this machine, so "Claude also reads
`~/.claude/skills/`" was an assumption the whole plan rested on. It holds, and **symlinks are
followed**, which was the second half and the half that could have failed silently.

How it was checked, because a self-report from a model is weak evidence on its own. A canary skill
was written to `/tmp/canary-skill/SKILL.md` carrying **two different random tokens** — one in the
frontmatter `description`, one in the body — and installed the way the plan proposes, as a symlink:
`~/.claude/skills/canary-probe -> /tmp/canary-skill`. Then `claude -p` was run from `/tmp`, a
directory with no `.claude/skills` of its own, asking for both tokens. Both came back. Two tokens
rather than one because they answer different questions: the description token proves the skill was
*registered*, the body token proves the file was actually *read*.

**The negative control is what makes it evidence.** The symlink was removed while
`/tmp/canary-skill/SKILL.md` was left on disk inside the working directory, and the same prompt
returned `NO-CANARY-SKILL`. So discovery came through `~/.claude/skills/` and not from the file
happening to sit near the session's cwd — which is exactly the confound a positive result alone
would not have excluded.

Corroborating, though not sufficient by itself: the client binary
(`~/.local/share/claude/versions/2.1.250`) contains 14 references to `~/.claude/skills/`, including
operational ones like a `synced` subdirectory named in help text about a skills-sync setting. String
evidence shows the path is *known*; only the canary shows it is *loaded*.

Both test artefacts were removed afterwards and `~/.claude/skills/` was left absent, so this entry
still describes the machine as it stands. **The remaining tradeoff is unchanged** and is the only
open question: a symlink points at a path, so if this repo moves or is deleted the skills stop
working silently.

## `responsive-audit` flicker: closed, and it was hiding two real defects

Fixed on 2026-09-08 at the fifth attempt. Recorded in full because four attempts failed for the
same reason and the shape is worth recognising.

**What it was.** Findings alternated 8/9, always `/items/inventory`. The audit reported "50
target(s) under 24px" on that page at six or seven widths, and whether 320 was among them varied
per run.

**The cause.** `clipped_text_controller` gives a truncated `<td>` `tabindex="0"` so a keyboard user
can reach its tooltip, which makes the cell match the audit's target selector. On that page the
marked cell is the 40×28 one **wrapping** each row's disclosure button, and WCAG 2.5.8's spacing
exception asks whether a 24px circle on the target reaches *another* target's hit area. A container
that encloses the target always intersects that circle, so the exception was unpassable and all
fifty buttons were reported. Whether the cell was marked depended on how the page had been reached,
which is where the run-to-run variation came from.

**A target's own ancestor is not a neighbour.** One predicate — `!a.contains(b) && !b.contains(a)`
— and three runs of the full audit now produce byte-identical output. Verified the honest way: the
underlying population still swings (`allTargets` 133 or 183 between runs) and the reported result no
longer moves with it, which is better than suppressing the swing, because the audit no longer
depends on it.

**Why four attempts missed it.** They compared counts, then positions. The number that moved was
neither the sizes (`undersized` sat at 52 throughout) nor the geometry, but the count of *other*
elements considered — and nothing printed that. The `DUMP` flag added at the fourth attempt is what
finally answered it, in one run.

**Two real defects found underneath, both fixed the same day:**

- The disclosure button was **20×28**, from a hand-written near-copy of `ROW_ICON_CLASSES` that
  dropped `size-7`, against design.md's rule that every control in an actions column is 28×28. The
  audit had been reporting it at every width and it read as noise. **A permanently noisy check is
  a check whose true findings get filed as noise.**
- `clipped_text_controller` measured `textContent`, which counts `sr-only` text, so a cell whose
  only text is a screen-reader label counted as clipped: **55 cells marked at 320px, 50 of them
  holding nothing but "Show storage locations for …"**, each a tab stop raising a bubble that
  repeated a deliberately hidden string. After: 5 marked, 0 unreadable. Both pinned by
  `item_system_spec.rb`, each watched failing first.

**Still open, and deliberately left**: `allTargets` on that page is 133 on a fresh wide load and 183
on a fresh narrow one, and a resize between them does not converge. That is the clipped-cell scan
reacting to `resize` while stacking labels arrive on a `matchMedia` change, and it no longer affects
any audit result. It is worth a look if a *user-facing* symptom ever points at it.

## The short-viewport chrome check: live input, no live positive

`responsive-audit` reports when fixed or sticky chrome covers more than half of a 740x360 window.
Until 2026-09-08 it fired on `/admin/base_items` and `/admin/partners` at "186px of a 360px
viewport", and that was a false positive: it counted the frozen actions column, `position: sticky;
right: 0` on every cell, whose vertical band scrolls away with the content and occludes no fixed
strip at all. Sticky elements with `top` and `bottom` both `auto` are pinned sideways and are
excluded now.

The run now prints how many pinned elements it considered, so "no page crosses the threshold" can
be told apart from "nothing was measured" — and that line immediately corrected me. Having removed
the column from the count, a four-page spot check found nothing pinned and I wrote down that the
check had gone inert on this app. **It has not.** A full run considers **30 elements across 146
page visits**, identical on three consecutive runs, and every one of them is `.table-rail` — the
fixed 24px horizontal scroll rail on a wide table, at 24px of a 360px viewport, about 7%. Genuine
vertical chrome, correctly counted, comfortably under the threshold.

So the *measurement* has live input. What has no live positive is the **reporting path** above 50%:
no screen in this app reaches it, because the topbar is `position: relative` and so scrolls, and
the nav drawer below `lg` is `fixed inset-y-0` translated off-canvas. Nothing here would notice if
the threshold arm broke.

**What is left.** Five controls were run against the filter by hand on 2026-09-08 and all five were
right — a right-pinned column over eight rows scores 0; a sticky topbar scores 64; a fixed bottom
bar 56; both together 120, unioned not summed; a topbar plus a pinned column scores only the
topbar's 64. Those controls live nowhere. `audit-selftest` is the place for them, and it cannot
hold them yet because this check is inline in `responsive-audit.js`'s main loop rather than an
exported function, and requiring that file runs the whole audit.

The work is: extract the measurement as `shortViewportChrome(page)`, guard the script entry with
`require.main === module`, and add a positive and a negative control alongside the existing 11.
Nothing depends on it today, which is exactly why it will rot quietly if it is not written down.

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

