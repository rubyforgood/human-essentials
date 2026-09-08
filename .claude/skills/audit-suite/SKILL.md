---
name: audit-suite
description: >
  Write, run and trust automated checks that assert a rule against a real system — design audits,
  accessibility sweeps, performance budgets, data-quality checks, custom lint. Use when building a
  check, when an audit reports zero and you want to know whether to believe it, when a check reports
  something that turns out not to be a defect, or when asked why a problem got past existing checks.
---

# Writing checks you can trust

An audit is a rule you can run. It is also **a claim about what it looked at**, and that is the
claim nobody checks.

This is extracted from a project that built 33 audits over twelve days. Three of them reported zero
while missing real defects, five reported defects that did not exist, and one had no implementation
behind it at all. Everything here is what those cost.

Nothing in this skill is specific to design, or to a browser, or to a language.

## The two questions

Before trusting any check, ask both:

1. **What did it look at?** Not what it checks — what it *visited*. A clean report over a fraction
   of the system is a clean report about a fraction of the system.
2. **Have I watched it fail?** A check that has never reported anything might be correct, or might
   be inert. There is no way to tell by reading it.

## Scope is the claim nobody checks

**Enumerate; never hardcode a list of things to check.** Ask the system for its own inventory —
routes from the router, tables from the schema, endpoints from the spec. A hardcoded list goes stale
silently, and its staleness is invisible in a passing run.

Three failures from one project, all the same shape:

- A check read one CSS class of control on 25 named pages and reported **"301 controls, 0 defects"**.
  Widened to every control on every screen: **14 defects**.
- A route sweep skipped one directory of routes, so two pages serving **200 OK with no layout at
  all** were never visited by anything.
- A check sampled **8 pages** while another covered 155. Widened: **14 failures**, none in the
  sample.

**The enumerator is itself a place to be blind.** In that project the route lister skipped actions by
bare name, so a filter meant for one controller's internal endpoint also hid a real screen on
another — and *every* audit built on it inherited the gap. Filter by fully qualified identifier,
never by a name fragment.

**Widening what a check reads can require widening what it discounts.** An audit that finds dead
CSS classes read the templates and not the helpers, and reported zero for an entire migration while
a live page rendered three classes the stylesheet did not define. Adding the helpers to its file
list changed the result by nothing — because the same audit decides whether a class is *deliberate*
by grepping for it outside the class attribute, that grep names its file types, and the type it had
always excluded was the templates', for exactly the right reason: a view writing `class="foo"` is
not evidence that `foo` means anything. Helpers write class attributes in a file type the grep does
read, so every helper-only class became its own justification and was filed as intentional.

The shape to watch for: a check with an **inclusion** rule and a **suppression** rule that overlap.
Widen the first and the second silently eats the new findings. The intermediate run is the dangerous
artefact — it reports clean, it is the number you were hoping for, and it reads as confirmation that
there was nothing there. **After widening a scope, plant a defect in the newly covered region.** Not
in the region that already worked; that control passes either way and tells you nothing about the
change you just made.

Fix it by restoring the suppression rule's *intent* rather than special-casing the new input. Here
that meant subtracting the files the audit extracts from — "something other than a class attribute
*we read* refers to it" — which keeps working when the next input type is added. Excluding the
helper directory by name would have passed the same control and lied the first time a helper
legitimately referenced a class.

**Count what you examined and print it.** A check that examined nothing reports no failures, which
is indistinguishable from a check that examined everything and found nothing:

```
examined: 2.4.11×150  2.5.7×20  3.2.6×143  3.3.7×1  3.3.8×3
```

Printing that number is also how you catch *your own* wrong conclusion. After removing a false
positive from one check, a **four-page spot check** showed it now considered nothing, and I wrote
down that it had gone inert on that codebase. The very next full run printed "30 pinned element(s)
considered across 146 page(s)" — all of them one component I had not happened to sample. The
measurement was live; only the threshold was never crossed. **A spot check is evidence about the
pages you sampled and nothing else**, and the distinction between "nothing to measure" and "nothing
over the line" is the difference between a dead check and a healthy one reporting good news.

Make a zero a finding. In that project a criterion was named in an audit's header and printed in its
pass line **with no implementation behind it at all**, and a second silently tested nothing for two
of three user roles because its selector only matched the third.

**A thing that errors is a finding, not a skip.** An audit that skips anything returning 500 means
breaking something hides it from the audit. Ask that of your own code: what does this do with input
it cannot handle, and does the run get quieter or louder?

**When a count flickers, stop comparing counts.** Four attempts at one non-deterministic audit
failed while comparing "8 findings" against "9 findings". The fix was to make it print the *names*
of the things it counted — at which point the answer arrived in one run: the underlying set was
stable at 52, and the swing was entirely inside a downstream filter, bimodal at 0 or 50 rather than
marginal. A count is a hash of the thing you actually want to diff, and it discards exactly the
information that identifies the cause. Build the dump before the third guess, not after the fourth.

It took a fifth attempt, and the last mile is its own lesson. **Dump the inputs to the rule, not
just its output.** The names of the flagged elements were identical every run; what moved was the
*population the rule compared them against* — a set of 50 elements that appeared and vanished — and
nothing printed that. The rule was "is another target within 24px", and one of the others was the
flagged element's own **ancestor**, which by definition overlaps it, so the exception it was
testing could never be met. When a predicate takes a neighbourhood, the neighbourhood is a term in
the comparison and has to be dumped like any other.

## After a change, do not choose the audits from memory

The suite grows past the point where you can hold it in your head, and then the question "which of
these does my change affect?" gets answered by recall. Recall omits.

A change removed **fifty keyboard tab stops** and altered two control sizes. The audits re-run
afterwards were the ones that came to mind — and `keyboard-audit`, `wcag22-audit`,
`row-actions-audit`, `tooltip-audit`, the axe run, `icon-audit` and `table-audit` were all skipped.
Every one of them measures exactly what had just changed. Nothing failed; nobody was careless; the
selection was simply made by the same faculty that had already mislaid a 20×28 button for weeks.

**A checklist does not fix this**, and it is worth being clear why, because a checklist is the
obvious answer. A checklist is memory written down: correct on the day it is written, silently
wrong the day an audit is added, and it fails in the direction that produces silence.

What fixes it is making omission impossible *by construction*:

1. **Enumerate the audits from the filesystem**, never from a list inside the tool. A tool holding
   its own list of audits has the same staleness problem one level up.
2. **Make every audit declare what it reads**, in the audit file itself so the declaration cannot
   drift from the code — `# AUDIT-READS: RENDER` or `// AUDIT-READS: VIEWS, DOCS`. Use a few named
   bundles rather than per-audit path lists, so no audit restates the render path and gets it
   subtly different.
3. **Fail the run when a file is neither declared nor explicitly excused**, with the excuse
   carrying a reason. This is the whole mechanism: a newly added audit cannot be quietly left out
   of every future selection, because it cannot be silent about itself. Non-audits — the seam, the
   generators, a one-off inspector — are named with a sentence each, because an unexplained absence
   reads identically to an oversight.
4. **Print what was considered and not selected.** "Three audits to run" and "three audits, having
   considered thirty" are different claims, and only the second one is evidence.

Prove it in three directions, because the failure it prevents is silence:

| Control | Must |
| --- | --- |
| A change to a view or a script | select the audits that render pages |
| A change to documentation only | select the doc readers and **no browser audits** — otherwise it is not selecting, it is saying "everything" |
| A new file in the audit directory with no declaration | **fail**, naming the file |

**Expect the honest answer to be "most of them" for anything on the render path**, and do not treat
that as the tool being useless. A browser audit drives real pages, so a changed view or Stimulus
controller genuinely can move any of them. The value is not precision; it is that the number stops
coming from intuition. Asked by hand about a change to one view and one controller I picked six; the
truthful answer was twenty-eight. Print a single pasteable command that runs the selected set, too —
"it was too much effort to run them all" ends in the same place as "I forgot".

**A permanently noisy check is a check whose true findings get filed as noise.** That audit had
been reporting a real defect at every width — a control drawn at 20×28 against a documented 28×28
— for as long as it had been flickering, and it was read as more of the flicker. Fixing the noise
first, then re-reading what remained, is what surfaced it. This is the actual cost of tolerating a
red check: not the ignored run, but the true positive that arrives wearing its clothes.

**Read the DOM with the retrying finder, never with a snapshot.** A single
`Nokogiri.parse(page.body)` is a photograph of whatever existed at that instant, and every
conclusion drawn from it inherits that timing. One helper took a widget's starting id that way;
when the snapshot preceded the widget's initialisation the attribute was absent, `nil.to_i` gave
**0**, and the helper then waited ten seconds for an id of `1` that never arrives. It failed once
in fifteen suite runs and passed every time the file was run alone — the signature of a read taken
before the thing settled. Same rule as an assertion: if it can be early, it must retry.

**A lookup that fails is not a pass.** The same shape, one level down, and it bit the check written
to catch the previous paragraph. A documentation link checker resolved `../design.md#anchor` against
the *working directory* rather than the file holding the link, found no such file, and its guard
read `SLUGS[target] ? SLUGS[target].include?(frag) : !File.exist?(target)` — so "I cannot find the
file" evaluated to **true**, meaning fine. It passed a link whose anchor was being renamed out from
under it in the same commit. Wherever a check consults a map, ask what it does on a miss, and make
the miss loud.

**A skipped page and a clean page produce the same summary line.** This is the sharpest version of
the rule, and it cost a project an entire unmigrated screen. Its route enumerator substituted a
record id into every `:*_id` segment by looking up *the controller's own* model — so a nested route
`/parents/:parent_id/children` received a **child** id, pointed at a parent that did not exist, and
returned 404. Every audit logged it under "not reached" and moved on. That screen sat outside the
migration for its whole duration and kept three stacked buttons in two weights, a 264px actions
column against 76–198px elsewhere, and title-case headers — while the table audit reported the app
clean and was *telling the truth about every page it looked at*.

Two habits follow:

- **Read the skipped list every run, and treat a persistent entry as a bug in the enumerator**
  rather than a fact about the app. Better still, exit non-zero on unexpected skips.
- **Some resources are addressed by query parameter, not by path segment**, so no amount of id
  substitution reaches them. Keep a short explicit map for those. Resist a general guessing scheme:
  it will quietly produce plausible-looking URLs for screens it got wrong, which is the same failure
  with more confidence.

## Two audits disagreeing about one tree means one of them is caching

Generated inventories get cached — a routes list, a schema dump, a component index. **A cache may
not be older than anything that determines its contents**, and the file that generates it obviously
qualifies.

One suite invalidated its route cache against the *routes file* but not against the *generator that
reads it*. After fixing a bug in the generator, one audit reported the old list and a clean run
while another — which shelled out to the generator directly rather than using the cache — saw the
new screen immediately and found a real defect on it. Same tree, same commit, two answers.

The disagreement is the signal, and it is easy to miss because the cached run is the reassuring one.
When two checks that should agree do not, **suspect staleness before you suspect either check**, and
list every input in the freshness test rather than the obvious one.

## A green check proves nothing until you have watched it go red

Revert the fix. Run the check. If it still passes, it is decorative.

This found four vacuous assertions in one project — a matcher looking for a button when the element
was a link, an `or` clause satisfied by a page that had neither branch, a live region matched while
empty. Each was written by someone who believed the fix worked. It did. The tests did not.

Three specific traps:

- **A synchronous read after an async event.** Reading state in the same tick as the event that
  changes it catches it mid-flight. Wait for a *condition*, never a fixed pause.
- **An assertion satisfied by the wrong arithmetic.** "One stale item plus no live one" equals "one
  live item". Assert the invariant, not the total.
- **Exercising a path where the bug cannot occur.** A full reload cannot strand state that only a
  partial update strands.

## Planting a defect cannot catch a false positive

The counter-intuitive one, and the reason most check suites quietly lie.

**Positive control** — break the thing in the way the rule is about; the check must report. Everyone
writes this. It proves a check *can* fire.

**Negative control** — change the thing in a way that is *not* a violation; the check must stay
silent. **Almost nobody writes this, and it is the one that matters.**

Five checks in one project reported failures that did not exist, over two days. Every one had passed
its positive control, because **a check that fires when it should not still fires when it should.**
All five would have been caught by a negative control:

| What it flagged wrongly |
| --- |
| A scrollbar thumb legitimately filling 95% of its track |
| A region an *earlier check in the same run* had already scrolled to its limit |
| The same navigation on a page with five times the content |
| A label hidden by the standard visually-hidden technique, clipped by design |
| An indicator that transitions in rather than appearing instantly |

**A control has to be sited where the check looks.** Both halves can be written correctly and prove
nothing, and this is easy to miss because the control *passes*. A negative control for a
short-viewport check injected a right-pinned sticky table and expected silence; it was silent, and
it was silent with the fix removed too, because `document.body.append` put the table below a page
far taller than the 360px window and every cell failed the check's own "is it on screen" test. The
control measured nothing and read as a pass. **Verify a control by removing the fix and watching it
go red** — the same discipline as an assertion, applied to the thing asserting. The identical
mistake, made twice in one day: an earlier "a target alone in open space" control was placed over a
dense table, so it was crowded by real page content and reported the opposite of what it claimed to
show.

**Then break the reporting arm and watch the positive go red as well.** Silencing the threshold —
`> vh * 0.5` to `> vh * 5` — must make the positive control fail. Otherwise a check that measures
perfectly and never reports still passes both controls.

**Reset shared state in the harness, not in each control.** One page object usually serves every
control, so a control that has to resize the viewport leaves the rest running at that size and
quietly changes what they measure. Put the reset in the per-control setup where a future control
cannot forget it — the alternative is the class of bug where an earlier check scrolls a region and
the next one reports it as already at its limit, which is on the list above.

See `reference/control-harness.md` for how to build this.

## Six ways a check lies

| | |
| --- | --- |
| **Vacuous pass** | reports nothing because it examined nothing |
| **Scope claim** | examined a fraction, reported as though it were the whole |
| **Silent skip** | errors are skipped, so breaking something hides it |
| **No baseline** | measures an absolute state, not the *change* the rule is about |
| **Read before settle** | reads state in the same tick as the event that changes it |
| **Order dependence** | an earlier check left state this one depends on |
| **Fixture assumption** | a shape true only of the case it was written against |
| **Wrong metric** | measures a real quantity that is not the one the rule is about |

**Wrong metric is the hardest**, because a check can pass both controls and still measure the wrong
thing. The defence: state the rule in words, then ask whether the number answers *that*. "Appears in
the same relative order" is a position, not a fraction of the page.

## Measure before you optimise — including the baseline

A check was widened from 9 items to 150 and stopped completing. Four rounds of optimisation
followed. None helped.

**The nine-item version took 525 seconds too.** It had always been slow, and nobody had timed it.
Four fixes for a problem that was never the widening.

Time it before you change it, then time each phase. The answer was one item costing 31 seconds while
the rest cost 800ms — which no amount of reasoning would have produced.

## Running them

- **Ask which ones, do not remember which ones.** A `which-audits` that reads the diff and each
  audit's own `AUDIT-READS` declaration, as above. Run it before committing, not after.
- **Put the control harness in CI, not the audits.** The harness is fast and deterministic. The
  audits read real data and answer "is the system good today" rather than "is this change sound".
  Different question, better asked deliberately. See `reference/control-harness.md`.
- **Two scopes, not two scripts.** Where a full run is expensive, take a `--all` flag rather than
  writing a second script — one definition of each check, scope as an argument. A copy drifts.
- **A bound goes in the output.** If a run is capped, say so where somebody will read it. A limit
  nobody knows about is the silent scope failure again.

## When you cannot finish

Say so, in the file, with what you measured. A known gap written down costs the next person nothing;
the same gap undiscovered costs them the whole investigation.

Do not narrow the scope quietly to make a run pass.

`evidence-discipline` covers the reporting side of this: measuring before asserting, keeping
provenance on a figure, and correcting a claim by annotating rather than editing.
