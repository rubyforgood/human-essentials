# Merging upstream into a long-lived migration branch

A design-system migration takes weeks, and the app it is migrating does not stop. Eventually the
branch has to take upstream's work, and by then most of the views have been rewritten — so almost
every conflict has migrated markup on one side and the old markup *with a new feature embedded in
it* on the other.

Measured on one such merge: **151 upstream commits over 12 days, 180 files, 88 of them also changed
on the branch, 33 of those views rewritten from scratch. 45 conflicts.**

## The rule

**The branch owns the markup. Upstream owns the behaviour.**

For each conflicted view: take the branch's file, then find what upstream *actually changed against
the merge base* and re-apply that change in design-system terms.

```
git merge origin/main --no-commit --no-ff
BASE=$(git merge-base HEAD origin/main)
git diff -w $BASE origin/main -- <file>
```

**Use `-w`.** Removing a feature flag reindents everything inside it, and a reindentation presented
as a conflict looks exactly like a feature. On that merge one file looked like a 19-line conflict
and was pure whitespace; another looked the same and carried a whole feature.

**Stage each file the moment you resolve it.** `git checkout --ours` on a path that is still
unmerged silently discards edits already made to it. That happened twice on one merge, to two files
already correctly resolved half an hour earlier.

## Where upstream wins outright

Not every conflict is markup-versus-markup, and the newer side is not automatically right.

- **A model rename propagates.** An enum value renamed upstream means every view calling the old
  predicate raises — and the *guidance text naming the button* has to follow the button, not just
  the code.
- **A dependency bump of a gem the branch deleted stays deleted.** Two arrived for gems an ADR had
  removed; re-adding them would have undone a documented decision through a lockfile.
- **When both sides fixed the same bug**, keep both layers and *re-read the argument the branch
  wrote against upstream's approach*. On that merge the branch's code carried a comment explaining
  why the check did not belong at the service level — because it would break four examples that
  passed no reason. Upstream had fixed those four examples. The objection was answered, so both
  layers were kept and **the comment was rewritten to say it had been wrong**, rather than left
  looking considered.

## Upstream's specs assert upstream's markup

They will fail, and almost none of those failures mean the behaviour is wrong. On one merge every
spec failure was one of: a Font Awesome class name, a framework data attribute, a Title Case label,
or a column header looked up by text.

- **Update the assertion to what ships; keep the behaviour it pins.**
- **Port their regression tests rather than dropping them.** The bug is usually still real even
  though the markup moved. Two were ported this way, each with a comment naming the upstream issue
  and what changed about the assertion.
- **Delete one only when it duplicates a spec on the branch with the *older* expectations** — two
  request specs asserting opposite things about one endpoint is worse than either. Say where the
  coverage went.
- **When their mechanism differs from yours, port the intent.** One upstream test asserted the
  *browser* refused a submission; on the branch the field carries `aria-required` and no HTML
  `required`, deliberately, so the server re-renders with an error summary. The ported test asserts
  the summary. Check which mechanism the branch chose before assuming the test is wrong.

## Two failures that will look like merge damage and are not

Both cost roughly an hour on one merge. Rule out both before investigating a merge conflict.

**A stale server.** After a `bundle install` that changes the gem set, a long-running dev server is
not to be trusted. Three pages reported HTTP 500 from a route sweep and rendered 200 when visited by
hand. Restart, then re-run.

**Debris that shadows a route.** Static-file directories are served before the router. An untracked
file left behind by an earlier rollback answered a CSV route, returning unfiltered rows with the
wrong headers — while the controller, view model, concern, model, factory and spec were all
byte-identical to before the merge. Have a check for this; it is two dozen lines.

## The order that finds things

1. Syntax-check every file touched. A conflict region rarely aligns with a block boundary, and a
   leftover `end` reads as a merge that went fine.
2. Regenerate the lockfile rather than hand-merging it — then **check its platform list**. Taking
   upstream's lockfile dropped the build machine's platform, the CSS compiler lost its executable,
   and nothing noticed because a stale stylesheet was still on disk.
3. Run migrations and let the framework rewrite the schema. Both sides add migrations; the schema is
   generated. Prepare the *test* database too, or every spec touching a new column raises.
4. Rebuild the stylesheet **before** any class audit. Otherwise it reads a stale one and reports a
   class as dead when the real fault is step 2.
5. Restart the server.
6. Run the class audit — including its script arm, which catches a controller toggling a class the
   stylesheet no longer defines. Upstream has no idea the class is gone; on this project it arrived
   five separate times.
7. Run the shadow check.
8. Full test suite, then ask the audit selector what else to run against the merge base.

## What to write down

The merge is the single largest opportunity for a silent regression in the whole migration, and the
interesting part is not the conflict count. Record: **which of upstream's features were re-applied
and where**, the defects the merge introduced (with the mechanism, so the next merge recognises
them), and the failures that *were not* the merge — because the next person will hit the same two
traps and the hour is only spent once if it is written down.
