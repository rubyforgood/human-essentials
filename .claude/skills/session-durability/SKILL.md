---
name: session-durability
description: >
  Keep long agent sessions from losing work — commit and push at every checkpoint, and detect a
  working tree that has been reverted underneath you. Use during multi-hour or multi-day work, when
  a fix that was verified appears to have come undone, when files seem to have reverted, or when
  deciding how often to commit.
---

# Not losing the work

From a project where the working tree was silently reverted **nine times** over three weeks, without
`HEAD` ever moving. Twice it arrived as a bug report about a fix that had already been made.

## Commit and push at every checkpoint

**Work, document, commit, push.** Not batched at the end.

A checkpoint that is not pushed is a checkpoint that can be lost. Committing locally is most of the
protection; pushing is the rest, and it costs seconds.

What counts as a checkpoint: one coherent change with its documentation. Not "the whole task" — a
four-hour task should produce several. If you are wondering whether it is time, it is.

The documentation goes in **the same commit** as the change it describes. A commit that says what
changed and a document updated three commits later are two facts that will disagree eventually.

## A reverted tree does not look like a bug

This is the part that costs the time. When files revert underneath you:

- `git status` may look clean, or show a plausible set of modifications.
- `HEAD` has not moved, so `git log` looks right.
- The symptom is a fix you remember making, absent from the code.
- **It renders exactly like a regression**, so the reflex is to debug the fix rather than the tree.

The tell is scale: a large number of files modified at once, including files unrelated to anything
you touched, and deletions of files you created.

## Check the tree before believing a report

**Before debugging a fix that has apparently come undone, compare the tree to `HEAD`.**

```bash
git status --porcelain | awk '{print $1}' | sort | uniq -c
```

A handful of modifications is work in progress. Hundreds of modifications plus deletions of files
you created is a revert.

Worth building, once, in any project where this happens:

- **A check** that reports clean / uncommitted work / reverted, and names the commit the tree
  resembles.
- **A restore** that snapshots the current disk state somewhere recoverable, resets to `HEAD`, and
  removes files the revert resurrected.
- **A hook** that runs the check when the working tree changes unexpectedly.

Snapshot before restoring, always. The revert may have taken something real with it, and a stash is
cheap.

## The resurrection scan must not respect `.gitignore`

A revert restores an old tree wholesale. It does not consult the ignore rules of the tree it is
overwriting. So a path `HEAD` has *started* ignoring since lands on disk and **never appears in
`git status`** — the check reports clean and the restore leaves it there.

In the source project this happened to the same file twice.
`public/product_drive_participants.csv` came back and shadowed a route both times, because Rails
serves `public/` before routing; the second time it failed a spec while the tooling said the tree
matched `HEAD`. The change log had recorded that as a file the restore "deliberately leaves alone",
which was a policy explanation for what was really a blind spot.

So scan `git status --porcelain -uall --ignored=matching` as well. Expand the directories it
collapses to `dir/` — build output like `public/assets/` is exactly where this bites — but bound the
expansion, because `tmp/` held 36,127 files and not one of them changes what renders. **Print which
directories you skipped.** A silently unscanned directory is the same blind spot again.

## "The path has history" is the wrong test

The tempting predicate for *resurrected* is "this path has history, so some commit deleted it".
Two separate things go wrong, and both were measured rather than reasoned about:

- `git log -- <path>` applies history simplification and can report **no history at all** for a file
  whose blob is plainly in an ancestor commit. Use `--full-history`.
- `--diff-filter=D` — "paths some commit deleted", which sounds like the definition itself —
  **misses everything a merge removed**, because a log without `-m` shows no diff for merge commits.
  Run against three genuinely resurrected files it found *none* of them, and returned only the one
  false positive. That is the result exactly inverted.

The predicate that holds: the file on disk is **byte-for-byte a version git once held at that
path**. It is exact; it separates a reverted file from a runtime artifact that happens to occupy a
deleted path (`spec/example_failures.txt` has history *and* a deleting commit, and rspec rewrites it
every run); and matching bytes is also the licence to delete, because git can give the file back.

Make it cheap with one filter before any per-path work: a single
`git log --full-history --name-only --format=` lists every path git ever touched, which cut 212
candidates on disk down to 4 and the scan from 157 seconds to 6.

## Assume tooling can be removed too

In the source project, the sixth revert deleted the drift-detection tooling itself and reset the
git hooks path. Nothing inside a repository can protect that repository from something outside it
rewriting the files.

So: **make it visible rather than trying to prevent it.** The check is cheap to re-run and the
restore is scripted. Recovery in a minute beats prevention that does not work.

## Two habits that pay for themselves

**Verify after restoring, not before.** Run the suite once the tree is back; a partial revert leaves
a state neither you nor the tests have seen.

**Keep the change log honest about it.** When work is lost and redone, the record should say so.
Otherwise the second implementation looks like churn, and the next person wonders why one commit
does the same thing as an earlier one.
