---
name: evidence-discipline
description: >
  Keep claims true over time — measure numbers before writing them down, keep provenance on every
  figure, correct a wrong claim by annotating rather than editing, and name what you chose not to
  do. Use when writing documentation, a decision record, a commit message or a report that states
  facts about a system; when quoting a count, size or timing; or when a previously written claim
  turns out to be wrong.
---

# Evidence discipline

Documentation rots in a specific way: not by going out of date all at once, but by accumulating
claims that were never true. Every one of them was written by someone confident.

From a project where recalled numbers were wrong three times, an estimate was wrong by an order of
magnitude, and one claim in the normative spec had never been checked and turned out to be false.

## Measure it in the session you write it

**If you state a number, produce it now.** Not from memory, not from an earlier message, not from a
plausible inference. Run the count.

Three failures worth the specificity:

- A migration document said *"333 of 366 views carry the new markup"*. Measured at that commit:
  **331**. Wrong by two when it was written.
- A runtime estimate of **40 minutes** for a full audit pass. Measured: **4.5 minutes**. Wrong by
  roughly an order of magnitude, and it had already shaped a plan.
- A claim that *"adjacent colour bands differ in lightness as well as hue"* was written into a
  normative spec as justification for a design decision. It was never measured. It was false.

The cost is not the wrong number. It is that somebody makes a decision on it.

## A grep is not a measurement

The most common way to be confidently wrong: search for one spelling of a thing and read absence as
fact.

In one project, a count of "audits carrying a hardcoded page list" was stated as 17, then corrected
to 14, then found to be **7** — because the search looked for one filename and missed every file
that reached the same data a different way. Same mistake twice in one analysis.

Before trusting a count from a search: **what would a matching case look like that this pattern
misses?** If you cannot answer, the number is a lower bound, and say so.

## Keep provenance

> *"Measured on this app at 1440px"* — not *"tables are 1,225px wide"*.

A figure without its conditions is a figure that will be wrong somewhere else, and nobody will know
why. Attach: what was measured, where, and under what conditions.

This matters most for numbers that look universal. `28px` reads like a standard. `28px, because that
is this app's menu trigger height` reads like a decision, which is what it is.

## Correct by annotating, never by editing

When a written claim turns out to be wrong, **say what was claimed, what was measured, and which is
right — in place.** Do not silently replace it.

Somebody made a decision on the strength of the old claim. They need to be able to find it and
re-examine what they concluded. A silent edit destroys exactly the evidence that makes the
correction useful.

The same rule applies to decision records and architecture decisions: supersede, annotate, append.
Never revise history.

## Name what you chose not to do

A known gap that is written down costs nothing. The same gap undiscovered costs the next person the
whole investigation.

Every piece of work has an edge. State it:

- What was left out, and why.
- What was measured and found not to matter.
- What could not be finished, with the evidence gathered so far so the next attempt does not start
  from scratch.

"Not done, deliberately, because X" is a complete and respectable outcome. "Done" when four of five
things are done is not.

## A recorded finding is a claim with a timestamp

Your own notes decay, and they decay in a specific place: **not in the measurement, in the scope
around it.**

One project re-measured every open item on its own to-do list. The pattern was clean:

| Kind of claim | Held up? |
| --- | --- |
| Counts of strings in files — dead links, label casing, call sites | **All correct**, weeks later |
| Claims about behaviour — what a form does, what an audit can see, what a test ordering produces | **Three in a row wrong** |

Nobody had been careless. Each was written immediately after measuring something true. What changed
was the world around the sentence: the audit gained a check, the test file set grew, the layout got
narrower — so a note saying "the audit cannot see this" became false without anyone touching the
note.

**Re-measure before acting on a recorded finding**, and put the date and the commit next to any
number you write down. It usually costs minutes. Acting on a stale one costs a day building
something that is already there — or, worse, produces a confident write-up of a fix for a problem
that no longer exists.

## A seed is not a reproduction

Randomised test orderings are seeded, and a seed is only a permutation **of the list of files that
happened to be loaded**. Record the seed and nothing else and you have recorded a permutation of a
list you did not record.

One project carried "`rspec --seed 43125` fails these seven examples" as a working reproduction. It
had stopped reproducing within about a day: **31 spec files were added and 1 removed**, so the same
seed selected an entirely different order. The note stayed on the list for two weeks looking
actionable.

The durable form of an order-dependent reproduction is a **minimal list of examples**, which most
runners can bisect for you from a currently-failing run. That does not rot when a file is added. If
all you have is a seed, record the file count with it, and expect it to expire.

**A corollary for flakes**: same seed, same tree, different outcomes means the failure is *timing*,
not ordering, and bisecting will not help. Establish which you have before spending a day on it —
and beware that running a second test process against the same database can manufacture failures
(deadlocks, in one case) that look exactly like a defect in the code.

## Reporting outcomes

- **If a check failed, say so, with the output.** Not "mostly passing".
- **If a step was skipped, say that.** Silence reads as completion.
- **If something is verified, state it plainly** — no hedging on work you have actually confirmed.
- **If you assumed something, name the assumption** where it is load-bearing.

The asymmetry to remember: an over-claimed result is trusted and acted on. An under-claimed one
costs a question.

## Watch for these phrasings

Each of these is usually a claim that has not been checked:

| Phrase | What it usually means |
| --- | --- |
| "should be" | has not been run |
| "roughly" / "about" on a countable thing | not counted |
| "all of" / "none of" | sampled |
| "still passes" | not re-run since the change |
| "no longer used" | grepped for one name |
