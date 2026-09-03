# The control harness

Two controls per check, run as their own suite. This is the thing that catches a check reporting
something that is not there.

## Shape

Each control names the check it exercises, what to do to the system, and whether the check should
report afterwards.

```js
{
  check:    "focus not obscured",
  kind:     "negative",
  what:     "the page as it ships, with its sticky bar and frozen columns",
  mutate:   async (subject) => { /* nothing, or something benign */ },
  run:      (subject) => theCheck(subject),
  expect:   "silence"          // positive controls expect a finding
}
```

The harness applies the mutation, runs **that check alone**, and compares what it reported against
what was expected. A check that reports on a negative control is as broken as one that stays silent
on a positive.

## Mutate the running system, not the source

Inject the defect into the live thing — a stylesheet, a DOM node, a fixture row, a stubbed response.
Not by editing files.

Three reasons, all learned by doing it the other way: it is reversible, it is fast enough to run on
every commit, and **it cannot be left behind in a working tree.** Editing source to plant a defect
means one interrupted run leaves a sabotaged repository.

## Making the checks callable

Checks usually live inside a script that runs everything and prints a report. To drive one in
isolation you need two small changes:

- **A swappable sink.** Instead of pushing findings to a module-level array, push them through a
  function the harness can replace, so it sees exactly what one check reported.
- **A main guard.** `if (require.main === module)` or equivalent, so importing the file does not run
  the whole audit.

Both are a few lines and both make the checks easier to test by hand as well.

## Writing a good negative control

The positive control is obvious: break the thing. The negative control needs imagination, because
you are looking for **the benign case that resembles a violation**.

Sources of good ones, from real false positives:

- **A degenerate geometry.** The scrollbar thumb that fills its whole track. The element with a
  zero-size box because an accordion is collapsed.
- **State left by an earlier step.** A region another check already scrolled. A session another role
  left signed in.
- **A legitimate technique that looks like the defect.** Visually-hidden text is clipped *on
  purpose*; a check for clipping must not flag it.
- **Timing.** Something that transitions in rather than appearing instantly.
- **Scale.** The same structure on a page five times longer.

If you cannot think of a benign case that resembles the violation, that is worth a minute's thought:
either the rule is very crisp, or you have not yet found how the check will be wrong.

## Your controls will be wrong too

Expect this. Building the harness in the source project immediately produced three failures that
were in the **controls**, not the checks:

- An overlay built as a CSS pseudo-element, which `elementFromPoint` never returns — so the check
  saw the page body and the control tested nothing.
- A "barely overflows" control that resized a container so far that the thing being clicked went off
  screen. The control was testing the viewport.
- A box sized from a block element's scroll width, which is the *container's* width, not the text's,
  so nothing ever clipped.

Same taxonomy as the checks, one level up: fixture assumption, fixture assumption, wrong metric.

The mitigation is structural: **a positive control that passes is evidence the mutation worked.** If
a positive control ever goes quiet, suspect the control before the check.

## In CI

Run the harness on every change; run the audits deliberately.

The harness is fast — the source project's was 11 seconds for 11 controls — and deterministic. The
audits are slow and read real data.

Two things that will bite in CI:

- **Fixtures.** The harness must build the conditions it needs rather than hoping the environment
  has them. The source project's controls were written against a development database with a
  session's worth of data; on a freshly seeded one, half the structures were absent and the controls
  threw. **A self-test that depends on how much data happens to exist is not a test.**
- **Environment.** Prefer the environment the checks are designed against. Seeding under a test
  environment there made real HTTP calls to a geocoder — 46 seconds and a network dependency —
  where the development environment skipped them entirely at 25.
