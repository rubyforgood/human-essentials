---
name: design-system-migration
description: >
  Migrate an application onto a design system, or enhance one that already has one, by working from
  a normative spec, researching what the industry does, previewing before building, applying every
  fix app-wide, and enforcing each rule with an executable audit. Use when asked to make a UI
  consistent, retire a legacy UI framework, build or extend a design system, or when a user reports
  visual defects page by page and wants them fixed everywhere.
---

# Design system migration and enhancement

A way of working, extracted from a migration that took ~200 instructions over twelve days and
produced a 4,700-line normative spec, 33 executable audits and a documented decision log.

**The method is the deliverable, not this project's rules.** Every rule below is tagged:

- **Portable** — holds on any app. Usually a WCAG criterion or a semantics rule.
- **Local** — you must decide it and write it down. The *rule* transfers; the *value* does not.

When in doubt it is Local. An under-claimed rule costs a decision. An over-claimed one costs a wrong
implementation that looks authorised.

## The loop

Every substantive request in the source project resolved to these five, in order. Skipping any one
of them is what produced rework.

1. **Read the spec first.** One document is normative. If it does not answer the question, that is
   the finding — the spec gains a rule before the code gains a change.
2. **Find what the industry does.** Name products, not "best practice": *Carbon ships an
   `OverflowMenu` documented for table rows; Salesforce calls it row-level actions.* If you cannot
   name three, you are guessing.
3. **Preview before building.** A rendered page the user can look at, served over HTTP. Not a
   description, not a diff. Then **stop and let them choose.**
4. **Apply it everywhere.** The fix is the sweep, not the page. A one-page fix is a future
   inconsistency.
5. **Write the decision down, in the same commit.** What was chosen, what was rejected, why.

### When to stop and ask

Stop for a **design decision** — anything where two defensible answers exist and the user's taste or
domain knowledge decides. Show the preview, give a recommendation with reasoning, wait.

Do not stop for conformance. Following the spec is not a decision.

**This is the highest-value rule here.** In the source project, 56 of ~200 instructions were the
user choosing between presented options. That is where the quality came from. An agent that builds
autonomously produces the opposite.

## How the work actually arrives

Almost none of it comes from a backlog. It comes from somebody **opening a page and finding
something wrong**, and it arrives in a characteristic shape:

> *"On the purchases page, the comments column increases the height of the row exponentially, making
> it very difficult to parse the information. What is industry standard for handling long free-text
> fields in a table? Show me a design preview with your recommendation. Then update all tables with
> open text fields to follow the convention, and update the design system file."*

One report, and it carries four demands: what is standard, show me first, apply it everywhere, write
it down. **Expect them compounded like this, and answer all of them** — a reply that fixes the
column and ignores the other three produces the same instruction again next week.

Some further properties of the real thing, all worth planning for:

- **A single message often reports four unrelated faults** on one screen. Padding, a truncated word,
  a control that does nothing, a component that does not match. Work them all; do not pick the
  interesting one.
- **The report usually contains a guess at the cause**, and it is often right. Check it, but check it
  rather than adopting it.
- **Frustration is a signal about the process, not the person.** *"Why do I need to point out
  elements individually on the same page?"* means the sweep was too narrow. *"I have had to prompt
  multiple times to fix this"* means a rule was applied without being written down, so it did not
  hold. Both are feedback about method.
- **The answer is usually a letter and a rider.** *"Go with B, but make sure it matches the
  destructive styling, and then check every empty state."* **The riders are where the rules come
  from.** Write them into the spec, not just into the code.
- **The work moves outward.** Components, then whole screens, then reports, then — if it is going
  well — the tools themselves. The last stretch of the source project contained no screens at all:
  it was about whether the checks could be trusted.

## Reference

Load these when the work reaches them, not before.

| File | Read it when |
| --- | --- |
| **the `audit-suite` skill** | Writing or changing any check. It owns that entirely — scope, controls, the six ways a check lies. Not repeated here, because two copies drift |
| `reference/documenting-decisions.md` | Setting up the documents, or wondering which one a change belongs in |
| `reference/preview-protocol.md` | About to build a screen |
| `reference/writing-rules.md` | Adding to the spec; Portable vs Local |
| `reference/copy-and-language.md` | Writing or auditing any user-facing words |
| `reference/error-and-failure-states.md` | Touching what a screen does when something goes wrong: where a failed submit lands, error summaries and focus, required markers, shared error components |
| `reference/keeping-work-reviewable.md` | Setting up, or when somebody cannot see the app |
| `reference/retiring-a-legacy-system.md` | **Only if** there is an old UI framework to remove |
| `templates/` | Starting a new app: empty skeletons for the spec, decision log and change log |
| `templates/adapter-rails.md` | Wiring the audits to a Rails/Devise/Tailwind app — one worked example of `adapter.md`, with the faults each line was written to fix |

Three sibling skills carry parts of this that are not about design, and are not repeated here:

| Skill | What it owns |
| --- | --- |
| `audit-suite` | Writing checks you can trust — scope, controls, the ways a check lies |
| `evidence-discipline` | Measuring before asserting, provenance, correcting a claim |
| `wcag-conformance` | WCAG 2.2 A/AA, and what automation cannot see |

## Setting up on a new app

**Ask first: is there a legacy system being retired?** If not, skip
`reference/retiring-a-legacy-system.md` and the migration map entirely — everything else applies to
greenfield unchanged.

Then, in order:

1. **Create the documents** from `templates/`. Empty is fine; they fill as decisions are made.
2. **Establish the adapter** — the one file that knows what framework this is. It needs:
   - a command that prints every screen as JSON: `[{path, controller, action}]`
   - how to sign in: base URL, sign-in path, two field selectors, a credential
   That is the entire coupling for a browser-driven audit. See "The adapter" below.
3. **Get one audit running end to end** before writing a second. An audit suite nobody can run is
   worth less than one check that runs on every commit.
4. **Put the audits' control harness in CI**, not the audits. See the `audit-suite` skill.

## The adapter

Everything above this line is about design. Everything below it is about a framework.

```
adapter/
  sign-in.json        base URL, sign-in path, field selectors, credential
  enumerate-routes    a command printing [{path, controller, action}]
```

Rails: `rails runner route-targets.rb`. Django: read `urls.py`. Laravel:
`artisan route:list --json`. Next.js: walk the app directory. **The contract is the JSON shape, not
the language.**

Two things about the route list, both learned the hard way:

- **Never hardcode a list of pages.** Every scope failure in the source project came from one: an
  audit reporting 0 defects while there were 14, two pages serving 200 OK with no layout that no
  audit ever visited, a check sampling 8 pages while another covered 155.
- **The enumerator is itself a place to be blind.** In the source project it skipped actions by bare
  name, so a filter meant for one controller's partial also hid a real screen on another — and
  *every* audit inherited that. Skip by `controller#action`, never by action alone.

## Anti-patterns

Each of these happened, and each cost a day or more.

- **Fixing the page instead of the pattern.** The user reports one button; the answer is the rule
  plus the sweep plus the audit.
- **Asserting a number instead of measuring it.** Every figure in the spec was measured in the
  session it was written. Recalled numbers were wrong twice.
- **Trusting a green test you have not watched go red.** See the `audit-suite` skill.
- **Proposing your own prerequisite and then doing it.** If the work you are about to start is not
  what was asked for, say so and get agreement first — even when it is genuinely worth doing.
- **Grepping for one spelling and reading absence as fact.** Twice in one analysis in the source
  project: a count of "audits with hardcoded lists" was wrong at 17, then 14; the answer was 7.
