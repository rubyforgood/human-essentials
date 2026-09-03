# Retiring a legacy system

**Load this only if there is an old UI framework being removed.** Everything else in this skill
applies to greenfield unchanged.

## The migration map

One document, two tables that must both stay true:

- **Translation.** Old pattern → new. `card-body` → `shared/essentials/card`. This is what someone
  reaches for when they meet an old class.
- **Not migrated.** What is deliberately left, and why. Every entry needs a reason, or it reads as
  an oversight and gets "fixed" wrongly.

## Dead classes render as nothing

The nastiest property of a CSS-framework migration: once the old stylesheet is gone, a leftover
class is not an error. It is silence. `btn`, `card-body`, `form-group`, `col-md-*` all render as
nothing at all, and nothing raises.

**So the check is a static one:** grep the templates for classes the stylesheet does not define. It
is cheap, it is exhaustive, and it catches what a browser test never will — because the page looks
plausible.

## Order of work

1. **Shell first.** Layout, navigation, page header. Everything else sits inside it, and a page
   migrated before the shell gets migrated twice.
2. **Components before screens.** A screen built from utility strings is a screen that will drift.
3. **Screens, in the order the user meets them.**
4. **Retire the old stylesheet** — and only then does the dead-class check become meaningful.

## Merging from the mainline

A long-lived migration branch takes updates from a mainline that is still writing the old patterns.
State the policy explicitly and check it after each merge: *keep the functionality, bring in the
updates, and anything brought in comes up to the new system.* Then run the dead-class check, because
a merge is exactly how `btn-primary` reappears.

## The leftover list is a feature

Finishing means the "not migrated" table is true, not empty. A documented leftover is a decision. An
undocumented one is a bug someone will find in a year.
