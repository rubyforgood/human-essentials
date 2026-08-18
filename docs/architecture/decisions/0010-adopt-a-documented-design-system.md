# 10. Adopt a documented design system

Date: 2026-08-17

## Status

Accepted, and amended by [11. Adopt the Ruby for Good design system (Tailwind v4)](0011-adopt-the-ruby-for-good-design-system.md)

The decision below — that `design.md` is normative, is kept current in the same pull request as
the change it describes, and carries its own backlog — still stands. What changed is the system
`design.md` specifies: ADR 0011 supersedes ADR 0009 and moves the target from Bootstrap +
AdminLTE to the Ruby for Good Tailwind system, so the "no second CSS framework" clause in point 2
no longer applies as written. See ADR 0011.

Amplifies [9. Sticking with AdminLTE for design needs.](0009-stick-with-adminlte-for-app-design.md)

## Context

[ADR 0009](0009-stick-with-adminlte-for-app-design.md) settled the *framework* question in 2022:
Bootstrap plus AdminLTE, not TailwindCSS. It did not settle the *system* question — which button
means "delete", how a page header is built, which utility dialect to write, what "done" means for
accessibility. That knowledge has lived in reviewers' heads and in whichever page a contributor
happened to copy from.

Human Essentials is largely volunteer-built, with contributors arriving for a weekend and leaving
again, across 400+ views. Undocumented convention does not survive that. The cost is visible in the
codebase today:

* The app is Bootstrap 4 in CSS (AdminLTE 3.2 vendors Bootstrap 4.6.1 and is imported after the
  Bootstrap 5.2 gem, so it wins) but Bootstrap 5 in JavaScript. Nothing said so, so both dialects
  appear in views.
* Roughly 170 class usages across the app are simply undefined and render as nothing: Bootstrap 3
  leftovers (`pull-right`, `hidden-xs`), AdminLTE 2 leftovers (`box`, `box-body`, `box-header`), and
  81 TailwindCSS classes across 28 files that ADR 0009 said would be removed and never were. One of
  them is in `UiHelper#submit_button`'s default, so every default Save button in the app is silently
  not aligned the way its own code says it is.
* There is no automated accessibility check, and the app-wide baseline has drifted: no `lang`
  attribute, `user-scalable=no` in the viewport meta, no skip link, and zero `<caption>` elements
  across 142 tables.

None of this is a framework problem. It is the absence of a written, agreed reference — the same
gap a documented design system closes.

## Decision

1. Adopt [`design.md`](../../../design.md) at the repository root as the approved design system for
   Human Essentials, and treat it as normative for UI work: the component patterns, the Bootstrap 4
   CSS / Bootstrap 5 JS dialect split, the Title Case copy convention, the semantic colour mapping,
   the `UiHelper` button rules, and WCAG 2.1 AA as the accessibility bar for new work.
2. Reaffirm ADR 0009. Bootstrap plus AdminLTE remains the framework. No second CSS framework is to
   be introduced, and the leftover TailwindCSS classes are to be removed rather than revived.
3. Keep the document living. A contributor who introduces a UI pattern updates `design.md` in the
   same pull request; a contributor who finds a documented pattern to be wrong corrects it there.
4. Record the known debt in `design.md`'s backlog rather than in tribal memory, so it is visible,
   attributable and claimable by new contributors.

## Consequences

Reviewers gain something to point at, and contributors gain something to read before their first UI
pull request instead of after it. New screens should converge rather than diverge, and the
recurring "which of these two class names do I use" question has a documented answer.

The cost is upkeep: a design document that is not maintained becomes actively misleading, worse than
none at all. Keeping it accurate is now part of the cost of changing shared UI, and the requirement
in point 3 makes that explicit.

Adopting the document does not fix the existing debt — it names it. Expect a period where the
codebase and the document disagree on the pages nobody has touched yet; the document describes what
new and edited code should look like, and its backlog tracks the gap. Nothing in this ADR requires a
sweeping migration, and no such migration should be undertaken as one change.
