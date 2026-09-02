# Turning this project into a reusable skill — proposal, not a build

Read `docs/prompt-history.md` first. This is the answer to the second half of that request: what a
"migration and enhancement skill" should contain, and what it should refuse to contain.

**Nothing has been built.** This is for a decision.

> **Superseded in part by [skill-proposal-v2.md](skill-proposal-v2.md).** The four open questions at
> the foot of this document have been answered, and the coupling figures in "What to leave out" were
> wrong — I measured mentions of app vocabulary and read them as coupling, when almost all of them
> are hardcoded page lists. The corrected measurement, and the revised scope that follows from it,
> are in v2. The analysis of *what transferred* still stands.

## What the evidence says transferred

The 199 prompts are the demand side. What satisfied them was not a design system — it was an
operating loop. Reading the categories back, the same five demands appear in almost every
substantive prompt, and they *are* the method:

1. **What does the design system say?** — there is one normative document, and it is checked first.
2. **What does the industry do?** — named products, not "best practice".
3. **Show me a preview before you build.** — a real rendered page, not a description.
4. **Apply it everywhere.** — the fix is the sweep, not the page.
5. **Write the decision down.** — in the same commit, in a named document.

Everything durable this project produced is downstream of those five. The 33 audit scripts exist
because of (4): a sweep that is not enforced comes undone. The decision log exists because of (5).

**The counter-evidence is just as useful.** Three prompts asked why the process had failed —
"Why did this get missed by previous audits?", "How can this be prevented in future?", "How can this
be caught earlier?" — and each exposed a gap that the loop above does not close on its own:

- An audit's **scope is a claim**, and it is the claim least likely to be checked. Three audits here
  reported zero while looking at a fraction of the app.
- A **green spec proves nothing until you have watched it go red.** Four vacuous assertions were
  found by reverting the fix.
- A **check that fires on a planted defect can still be wrong.** Five false positives in two days,
  all of which had passed that test.

Those three lessons cost the most to learn and are the most portable. They belong at the front of
any skill, not in an appendix.

## What I recommend building

### Shape: one small entry point, several reference files loaded on demand

A skill that is a single long document will not be followed — the same reason `design.md` is 4,782
lines but the *rules* that get obeyed are the short imperative ones. So:

```
design-system-migration/
  SKILL.md                    ~120 lines. The loop, the triggers, when to stop and ask.
  reference/
    operating-rules.md        The five demands, stated as rules with their failure modes.
    audit-discipline.md       Scope-is-a-claim, revert-testing, positive+negative controls.
    documenting-decisions.md  The six-document model and what triggers each.
    preview-protocol.md       How to show a design choice before building it.
  templates/
    design-system.md          Skeleton with headings and no content.
    decision-log.md           Entry format: what was chosen, what was rejected, why.
    changelog.md              One row per commit.
  audits/
    audit-selftest.js         The positive/negative control harness.
    page-audit-template.rb    One static audit, heavily commented as a worked example.
    route-targets.rb          Enumerate every screen — the anti-hardcoded-list device.
```

Roughly 900 lines total, against the 16,377 lines of documentation and 33 scripts this project
produced. That ratio is the point.

### What to include, and why

| Include | Because |
| --- | --- |
| The five-demand loop | It is what the 199 prompts actually asked for, over and over |
| The audit-discipline lessons | Highest cost to learn, entirely app-independent |
| `route-targets.rb` and the rule it embodies | Every scope failure here came from a hardcoded page list |
| The self-test harness | The only thing that catches a wrong check; ~250 lines and generic |
| Document *templates*, empty | The structure transferred; the content did not |
| The preview protocol | The single highest-leverage habit, and the one most often skipped |

### What to leave out, deliberately

| Exclude | Because |
| --- | --- |
| `design.md`'s content | 4,782 lines of decisions about *this* app. 28px row icons and ZIP-as-text are not universal law |
| 22 of the 33 audits | They encode Rails, Propshaft, Tailwind v4, Cuprite and this app's models |
| The migration map | A translation table from Bootstrap/AdminLTE to this system, specific to both ends |
| Anything about diaper banks | Obviously |

The temptation is to ship the audits, because they look like the valuable artefact. They are not.
**Eleven of the 33 reference this app's models or vocabulary directly**, and most of the rest assume
a Rails/Propshaft/Tailwind stack. What transfers is the *shape* of an audit — enumerate every
screen, assert one rule, prove it fires and prove it stays quiet — and one worked example teaches
that better than twenty-two that need porting.

## Three options for scope

**Option A — the operating manual.** `SKILL.md` plus `reference/`. No code, no templates. ~350
lines. Fastest to write, honest about what is portable, and gives up the thing that made this
project's rules stick: enforcement.

**Option B — manual plus harness (recommended).** Everything in the tree above. The reference
material, the empty templates, and three pieces of working code: the self-test harness, one worked
audit, and the route enumerator. ~900 lines. Someone can start on a new app the same day and has a
real example to copy for their second audit.

**Option C — the full port.** B plus generic versions of the WCAG audits, contrast checking, the
keyboard audit and the responsive sweep. ~3,000 lines. The most useful *if* the next app is also
Rails and Tailwind, and largely wasted if it is not. I would rather add these once a second app has
shown which assumptions are actually shared.

**I recommend B**, and specifically that C is deferred until there is a second app to generalise
*from*. Generalising from one system is the exact failure this project has already made once —
prompt `[158 · 30 Aug]`, "audit the app for other places where I generalised from one system", was
about precisely that, and it found 28 unevidenced claims.

## What I would want to get right

**The skill must say when to stop and ask.** The single most valuable rule in this project's
`CLAUDE.md` is that a design decision needs a preview and the user's choice before it is built. A
skill that encourages autonomous building would produce the opposite of what worked here — 56 of the
199 prompts are the user choosing between options, and that is where the quality came from.

**It must be honest that the audits need infrastructure.** A browser, a running app, seeded data,
and a way to serve a mock-up over HTTP. That is a real prerequisite and skipping it is why an audit
suite gets written and then never run.

**It should carry the failure taxonomy, not just the successes.** Vacuous pass, no baseline, read
before settle, order dependence, fixture assumption, wrong metric. Six named ways a check lies. That
list took two days of false positives to produce and is a page long.

## Open questions — I would want answers before building

1. **What is the next app's stack?** If it is Rails and Tailwind, option C becomes much more
   attractive and several audits port with light edits. If it is not, B is clearly right.
2. **Is this a personal skill or a repository one?** `~/.claude/skills/` follows you between
   projects; `.claude/skills/` is committed and shared with a team. Neither directory exists yet in
   this environment, so this would be the first.
3. **Should it assume a migration, or also greenfield?** Everything here is migration-shaped
   ("replace this legacy pattern everywhere"). The enhancement loop works on a new app too, but the
   migration-map document and the "leftover" tracking would not.
4. **How prescriptive should the design rules be?** I can ship the *reasoning* behind this project's
   rules — why 24px targets, why sentence case, why a chart's series count is a constant — as
   worked examples, or leave them out entirely and ship only the method. Examples make it concrete
   and risk being cargo-culted onto an app where they are wrong.

## What I would do first, if you say go

Build `SKILL.md` and `reference/audit-discipline.md` only — perhaps 200 lines — and try them against
one real task on another app before writing the rest. The lesson from `[158]` applies to the skill
itself: **do not generalise from one system.** A skill written entirely from this project, never
exercised elsewhere, would be a very confident document about a sample size of one.
