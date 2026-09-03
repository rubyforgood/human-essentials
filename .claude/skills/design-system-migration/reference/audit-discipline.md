# Audit discipline

The most expensive lessons in the source project, and the least app-specific. An audit is a rule you
can run. It is also a claim about what it looked at, and that claim is the one nobody checks.

## An audit's scope is a claim

**A clean report says nothing about what was never visited.** When an audit reports zero, the
question to ask is what it looked at.

Three times in one project:

- A tooltip audit reported **"301 controls, 0 defects"** while reading only `.cell-actions` on 25
  hardcoded pages. Widened to every control on every screen: **14 defects**.
- A route sweep skipped one directory of routes, so two pages serving **200 OK with no layout at
  all** — no stylesheet, Times New Roman — were never visited by anything.
- A manual-criteria audit sampled **8 pages** while axe covered 155. Widened: **14 pages** failing a
  Level A criterion, none of them in the sample.

Two rules follow:

**Enumerate, never hardcode.** Ask the router for the list. A hardcoded list goes stale silently and
its staleness is invisible in a passing run.

**Count what you examined, and print it.** A check that examined nothing reports no failures, which
is indistinguishable from a check that examined everything. In the source project a criterion was
named in an audit's header and printed in its pass line **with no implementation behind it at all**.
Make a zero a finding:

```
examined: 2.4.11×150  2.5.7×20  3.2.6×143  3.3.7×1  3.3.8×3
```

## A green test proves nothing until you have watched it go red

Revert the fix. Run the test. If it still passes, the test is decorative.

This found four vacuous assertions in one project — a matcher looking for a button when the element
was an anchor, an `or` clause satisfied by a page that had neither branch, a live region matched
while empty. Each had been written by someone who believed the fix worked, and it did; the tests did
not.

**Three specific traps:**

- **A synchronous read after an async event.** Reading computed style in the same tick as `focus()`
  catches the style mid-recalc. Prefer a matcher that retries; if you must read directly, wait for a
  condition, never a fixed pause.
- **An assertion satisfied by the wrong arithmetic.** "One stranded rail plus no live one" equals
  "one live rail". Assert the *invariant* — one per region — not the total.
- **Testing through a path where the bug cannot occur.** A full page reload cannot strand state that
  only a partial swap strands.

## Planting a defect cannot catch a false positive

This is the one that is genuinely counter-intuitive.

**Positive control** — break the page in the way the criterion is about; the check must report.
That is the test everybody writes. It proves a check *can* fire.

**Negative control** — change the page in a way that is *not* a violation; the check must stay
silent. **This is the one that matters**, and almost nobody writes it.

In the source project, five checks reported failures the app did not have over two days. Every one
had passed its positive control, because **a check that fires when it should not still fires when it
should**. All five would have been caught by a negative control:

| Check | The benign case it wrongly flagged |
| --- | --- |
| Dragging alternatives | a scrollbar thumb filling 95% of its track |
| Dragging alternatives | a region an earlier check had already scrolled to its limit |
| Consistent help | the same navigation on a page with five times the content |
| Text spacing | a label hidden with the `sr-only` technique, clipped by design |
| Focus visible | a focus ring that transitions in rather than appearing instantly |

Run both controls for every check, in a harness, injecting the mutation into a live page rather than
editing source — reversible, fast, and impossible to leave behind in a working tree.

**Put the harness in CI, not the audits.** The harness is fast and deterministic; the audits read
seeded data and answer "is the app good today" rather than "is this change sound". Different
question, asked deliberately.

## Six ways a check lies

Named, because they recur. The first three produce false negatives, the last three false positives.

| | What it looks like |
| --- | --- |
| **Vacuous pass** | reports nothing because it examined nothing |
| **Scope claim** | examined a fraction and reported as though it were the whole |
| **Silent skip** | a page that 500s is skipped, so breaking a page hides it |
| **No baseline** | measures an absolute state, not the change the criterion is about |
| **Read before settle** | reads computed state in the same tick as the event that changes it |
| **Order dependence** | an earlier check left the page in a state this one depends on |
| **Fixture assumption** | a geometry or data shape true only of the page it was written against |
| **Wrong metric** | measures a real quantity that is not the one the rule is about |

The last is the hardest: a check can pass both controls and still measure the wrong thing. The
defence is to state the criterion in words first, then ask whether the number answers it. "Help
appears in the same relative order" is a *position*, not a fraction of the page.

## Measure before you optimise, and measure the baseline

An audit was widened from 9 screens to 150 and stopped completing. Four rounds of optimisation
followed — cheap discovery, an instance cap, hoisting a 500KB script injection out of a loop, a time
budget. None helped.

**The nine-page version took 525 seconds too.** It had always been slow at 58 seconds a page, and
nobody had ever timed it. Four fixes for a widening that was never the problem.

Time the thing before you change it. Then time each phase — the answer was one screen costing 31
seconds while the rest cost 800ms, which no amount of reasoning would have produced.

## When you cannot finish

Say so, in the file, with what you measured. A known gap that is written down costs the next person
nothing. The same gap undiscovered costs them the whole investigation again.

Do not quietly narrow the scope to make a run pass. If an audit is bounded, the bound goes in the
output where somebody will see it.
