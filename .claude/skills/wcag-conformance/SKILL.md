---
name: wcag-conformance
description: >
  Audit a web application against WCAG 2.2 Level A and AA, covering the criteria automated tools
  cannot see and the six that WCAG 2.2 added. Use when asked about accessibility conformance, when
  running or interpreting an axe report, when a suite reports zero accessibility violations, or when
  deciding what still needs checking by hand.
---

# WCAG 2.2 A and AA

**WCAG 2.2 has been a W3C Recommendation since 5 October 2023.** Most tooling and most audit suites
still target 2.1. A suite reporting zero against a superseded version of the standard is the most
comfortable kind of wrong.

In one project, axe reported **0 violations across 155 screens** — accurately, against 2.1. Checking
the six criteria 2.2 added found a Level AA failure on five of them.

## What automation covers

axe-core and equivalents find roughly a third to a half of WCAG issues: the machine-checkable ones.
They do not judge whether alt text is *good*, whether a heading describes its section, or whether a
keyboard order makes sense.

**Run axe first — it is cheap and it is the floor, not the ceiling.** Then work the list below.

## The six criteria WCAG 2.2 added

These are the ones nothing in a 2.1-configured suite checks.

| Criterion | Level | What it asks |
| --- | --- | --- |
| **2.4.11 Focus Not Obscured (Minimum)** | AA | A focused control is not *entirely* hidden by author content |
| **2.5.7 Dragging Movements** | AA | Anything draggable also works with a single pointer, without dragging |
| **2.5.8 Target Size (Minimum)** | AA | Interactive targets are at least 24×24px, or adequately spaced |
| **3.2.6 Consistent Help** | A | A help mechanism on several pages is in the same relative order on each |
| **3.3.7 Redundant Entry** | A | Information already given in a process is auto-filled or selectable |
| **3.3.8 Accessible Authentication (Minimum)** | AA | No cognitive function test without an alternative |

**4.1.1 Parsing was removed in 2.2.** Do not check it.

### 2.4.11 is the one most apps fail

Anything `position: fixed` at an edge — a sticky footer, a cookie bar, a floating scrollbar, a chat
launcher — will cover a focused element, because **the browser scrolls a newly focused element only
far enough to touch the edge of the viewport, which is exactly where the fixed thing is.**

Measured in one project: a focused link at y=876, height 24, in a 900px viewport, with a fixed rail
at y=876. Entirely covered. Five screens.

The remedy is `scroll-padding` on the scroll container, sized to the obstruction — which is what the
criterion's own understanding document recommends. Take the value from the same place the
obstruction's size comes from, so the two cannot drift.

Note it is *entirely* hidden that fails at AA. Partial obscuring is 2.4.12, which is AAA.

### 3.3.8 in practice

The one that bites real applications is a **password field that blocks paste**, which breaks every
password manager and forces the user to transcribe. Check for cancelled paste events, not just the
absence of an `onpaste` attribute — and check the field carries an `autocomplete` token a manager
can fill from.

## Criteria automation cannot reach

Beyond the 2.2 additions, these need a browser driven deliberately:

| | How to check it |
| --- | --- |
| **1.4.4 Resize text** | Render at 200%; nothing lost or clipped |
| **1.4.10 Reflow** | 320px wide; no two-dimensional scrolling except where content needs it |
| **1.4.12 Text spacing** | Apply the required spacing and compare **before and after** — only what becomes clipped counts |
| **1.4.13 Content on hover or focus** | Hoverable, dismissible, persistent |
| **2.1.1 / 2.1.2** | Tab through everything; nothing unreachable, nothing trapped |
| **2.4.1 Bypass blocks** | A skip link that takes focus and moves it to the main content |
| **2.4.2 Page titled** | Every page titled, **and titles distinct from each other** |
| **2.4.7 Focus visible** | Focus, wait for the style to settle, then measure |
| **1.3.5 Identify input purpose** | Every field collecting the user's own data has the right `autocomplete` token |

### `role="alert"` on a page that has just loaded may announce nothing

Worth its own entry, because it is the most common way a form is *believed* to be accessible while
failing 3.3.1 in practice — and an automated checker finds nothing wrong, because the markup is
correct.

**A live region is defined in terms of a subtree changing.** The assistive technology watches a node
and speaks what appears inside it. When a failed submit re-renders the whole page, the error summary
is already in the markup as the accessibility tree is first built. Nothing changed, so support for
announcing it varies between screen readers. The region only reliably does its job for content
inserted into a page that is already live.

Check what actually happens to **focus** after a failed submit. In one app it stayed on `<body>` on
every form, leaving a keyboard user at the top of a page that looked like the one they had just
sent. The fix is `tabindex="-1"` on the summary and focusing it on load, with the live region moved
*inside* the focused element — see `design-system-migration/reference/error-and-failure-states.md`
for the full pattern and its two traps.

**Be honest about what you verified.** Without a real screen reader you can measure the mechanics —
focus lands, the page scrolls to it, the roles are where you put them — and you are following a
published pattern for the announcement. Say that, rather than reporting the announcement as tested.

## Two measurement traps

Both produced false failures in the source project, and both are easy to repeat.

**Measure the change, not the state.** 1.4.12 asks that applying the spacing causes no loss. A
one-shot check flags visually-hidden labels, which are clipped by design and clipped equally before
and after. Measure twice; report the difference.

**Wait for the style to settle.** Reading computed style in the same tick as `focus()` catches it
mid-recalc — a focus ring that transitions in measures as absent. That produced a reported 2.4.7
failure on a page that passed, and the "fix" for it was unnecessary: with no author rule at all, the
browser still paints its own ring.

## Sampling

The expensive checks — reflow, zoom, text spacing, a full tab traverse — resize the viewport several
times per page. It is tempting to sample them.

**Sampling is least defensible for exactly those checks**, because reflow and spacing failures come
from *one page's content* — a wide table, a long unbroken string. Widening the cheap checks in one
project took 2.4.2 from "0 failures on 8 pages" to **14 on 92**.

If you must sample, derive the sample and offer a full pass behind a flag. Never hardcode a page
list; see the `audit-suite` skill.

## Write the coverage down

**Produce a table of all 55 A/AA criteria and what verifies each**, including the ones that do not
apply — checked, not assumed. "No media elements" is a claim; `grep -c '<video'` is a measurement.

The useful question about a suite reporting zero is not what it found. It is what it looked at.

Two sibling skills apply directly: `audit-suite` for building the checks and proving they fire, and
`evidence-discipline` for keeping the coverage table's numbers true.
