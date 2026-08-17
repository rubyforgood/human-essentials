# 11. Adopt the Ruby for Good design system (Tailwind v4)

Date: 2026-08-17

## Status

Accepted

Supersedes [9. Sticking with AdminLTE for design needs.](0009-stick-with-adminlte-for-app-design.md)

Amends [10. Adopt a documented design system](0010-adopt-a-documented-design-system.md)

## Context

[ADR 0009](0009-stick-with-adminlte-for-app-design.md) (Oct 2022) removed a partial TailwindCSS
migration and committed Human Essentials to Bootstrap + AdminLTE. The reasoning was sound at the
time and local to this repository: the migration was half-finished, the benefit was framework
ergonomics, and the cost was rewriting 400 views with volunteer labour. Nothing about that
trade-off was wrong.

What has changed is that the decision is no longer local. Ruby for Good is standardising its
applications on a single design system — the one built for
[CASA](https://github.com/rubyforgood/casa/blob/main/design.md) — so that contributors moving
between RFG projects meet the same components, tokens and conventions, and so that accessibility
and design work done once benefits every app. Under that constraint, "Bootstrap because it is
what we already have" stops being the cheaper option: it makes Human Essentials the one app a
contributor has to learn separately, and it forks every future shared improvement.

The state of the codebase also argues against holding the line. ADR 0009's own stated
consequence — "Any work that used TailwindCSS would need to be updated to use Bootstrap 4
instead" — was never carried out: 81 Tailwind class usages across 28 files are still in the
views, rendering as nothing. The app is simultaneously running Bootstrap 4 CSS (vendored inside
AdminLTE 3.2) and Bootstrap 5 CSS and JS, with ~170 class usages that are defined by none of
them. The status quo is not a coherent system being defended; it is three systems layered by
accident.

## Decision

1. **Adopt the Ruby for Good design system — Tailwind v4, Figtree, indigo brand on slate
   neutrals — as the target UI for Human Essentials.** ADR 0009 is superseded.
2. **Migrate page by page, not in a big bang.** Tailwind runs alongside the legacy Bootstrap UI.
   A migrated action renders on a Tailwind-only layout; untouched actions keep the Bootstrap
   `application` layout. **The two CSS resets are never loaded in the same document.** This is
   the mechanism that makes a 393-view migration survivable by volunteers, and it is how CASA
   did it.
3. **Build with the `tailwindcss-rails` gem, not `cssbundling-rails` + npm.** CASA uses npm
   because CASA already had Node. Human Essentials has no `package.json` and no Node in its
   deploy path, and `docs/code_standards.md` is explicit that new dependencies need strong
   justification. The standalone Tailwind CLI produces the same v4 output with no new runtime.
   This is a deliberate divergence from CASA in **tooling**, not in the design system itself.
4. **Self-host the typeface and icons** under `public/vendor/` rather than loading them from a
   CDN, matching CASA and removing three CDN dependencies from every page render.
5. **`design.md` is rewritten to specify the Tailwind system** and remains normative, as ADR 0010
   established. ADR 0010's rule "no second CSS framework is to be introduced" is amended: for the
   duration of the migration there are deliberately two, and the rule becomes "no *third*, and
   the Bootstrap half only shrinks."

## Consequences

Contributors gain a system shared with the rest of Ruby for Good, and a design document that
describes one coherent target instead of documenting an accident. Accessibility is specified as
part of the system rather than retrofitted; the Tailwind shells ship with the skip link, landmark
structure and focus treatment that the Bootstrap shells only got last week.

The cost is a long migration carried out under a temporarily worse condition: two design systems
in one app, which is strictly more confusing than one, for as long as it takes. That is the price
of not doing a big-bang rewrite, and it is only acceptable if the Bootstrap side genuinely
shrinks — a page migrated is a page that never goes back. **A migration that stalls half-done is
the worst outcome of all, and is exactly what ADR 0009 was reacting to.** The mitigations are
that `design.md` tracks migration status per area, that every migrated page is a complete page
rather than a hybrid, and that the legacy layout is deleted the moment nothing renders on it.

Risks accepted:

- **Bundle duplication during the migration.** Both stylesheets exist in the repo; no single
  page loads both.
- **Specs coupled to Bootstrap markup.** Migrating a page breaks any spec asserting on `.card`,
  `.btn-primary` and similar. Those assertions move to semantic hooks as each page is migrated,
  which is an improvement to the specs regardless.
- **Divergence from CASA in build tooling** means the two apps' asset pipelines are not
  copy-pasteable, only their design tokens and components are. Judged the right trade, since
  adding Node to this deploy path is a larger and more permanent cost.
