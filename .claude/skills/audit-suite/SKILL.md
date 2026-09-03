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

**Count what you examined and print it.** A check that examined nothing reports no failures, which
is indistinguishable from a check that examined everything and found nothing:

```
examined: 2.4.11×150  2.5.7×20  3.2.6×143  3.3.7×1  3.3.8×3
```

Make a zero a finding. In that project a criterion was named in an audit's header and printed in its
pass line **with no implementation behind it at all**, and a second silently tested nothing for two
of three user roles because its selector only matched the third.

**A thing that errors is a finding, not a skip.** An audit that skips anything returning 500 means
breaking something hides it from the audit. Ask that of your own code: what does this do with input
it cannot handle, and does the run get quieter or louder?

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
