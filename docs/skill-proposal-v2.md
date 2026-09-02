# The skill, revised after your answers

Supersedes the open-questions section of [skill-proposal.md](skill-proposal.md). Still a proposal —
nothing built.

**A correction first.** The previous version said *"22 of the 33 audits encode Rails, Propshaft,
Tailwind and Cuprite"* and *"eleven reference this app's models by name"*. I measured that with a
crude grep and read the result as coupling. It is not. Almost every hit is a **hardcoded page list**
or a seed email:

```
wcag-audit.js:32   ["donations", "/donations"],
button-audit.js:22 "/", "/partners", "/items", "/item_categories", …
```

That is surface coupling, and the project already knows the fix. The measured position:

| | Count | Coupling |
| --- | ---: | --- |
| Browser-driven (JS) | **23** | Needs a URL list and a way to sign in. Nothing else. |
| Source-reading (Ruby) | 8 | Genuinely stack-bound — parses ERB, asks Rails for routes |
| Source-reading (Python) | 2 | Scans the built stylesheet |

So the answer to your first question is better than the one I gave.

---

## 1. Can it be stack-agnostic? Yes — and mostly for free

**A browser audit needs exactly five things from the application:**

```
BASE_URL          where it is running
/users/sign_in    the path to the sign-in form
#user_email       a selector for the identifier field
#user_password    a selector for the secret field
password!         a credential
```

Plus a list of URLs to visit. That is the entire adapter surface for **23 of the 33 audits**. None of
their logic knows what a diaper bank is; they assert design-system rules — is this control named, is
this focus ring visible, does this table have one scrollbar — against a rendered page.

The URL list is the interesting part, because it is where this project has already been burned three
times. **Only 6 of the 23 currently enumerate routes from the router**; the other 17 carry a
hardcoded list. Every scope failure in the record came from exactly that: the tooltip audit reported
0 defects while there were 14, the route sweep never visited two pages serving 200 OK with no layout
at all, and `wcag-manual` sampled 8 pages while axe covered 155.

So the adapter has **two** responsibilities, not one:

```
adapter/
  sign-in.json       the five values above
  enumerate-routes   a command printing every screen as JSON: [{path, controller, action}]
```

For Rails that command is `rails runner route-targets.rb`. For Django it reads `urls.py`, for Next.js
it walks the app directory, for Laravel it is `artisan route:list --json`. **The contract is the JSON
shape, not the language.**

The 10 source-reading audits are honestly stack-bound and belong in the adapter itself — they parse
templates and ask the framework about dead routes. That is fine: they are the minority, and they are
the ones a same-stack app gets for free anyway.

### Not a different doc — a layer

Two documents drift. This project proved it and then guarded against it: the address audit carries a
copy of the field table in JavaScript, and there is a spec whose only job is to fail when the Ruby
and JavaScript copies disagree. A separate "stack-agnostic guide" and "Rails guide" would reproduce
that problem with no spec to catch it.

One skill. Agnostic core, named adapter, and the adapter small enough to read in a sitting.

**There is a prerequisite, and it is work this app needs regardless.** Making the core agnostic means
migrating those 17 audits off their hardcoded lists onto route enumeration. That is a day's work, it
is the highest-value change left in the audit suite, and it closes a class of blindness that has
already produced three incidents here. I would do it *before* extracting the skill, not as part of
it.

---

## 2. Personal vs repository skill — what the difference actually is

| | `~/.claude/skills/` | `.claude/skills/` |
| --- | --- | --- |
| Lives in | your home directory | this repository |
| Available in | every project you open | only this project |
| In version control | no | yes |
| Shared with others | no | anyone who clones |
| Reviewed in pull requests | no | yes |
| Survives a new machine | only if you copy it | yes |

Neither directory exists in this environment yet, so this would be the first either way.

The tension: you need it **portable**, because the whole point is the next app, and **versioned**,
because it is substantial, it will be wrong in places, and you will want to see what changed and why.
This project kept a decision log for exactly that reason.

### Recommendation: develop it here, symlink it into place

```bash
# Versioned, reviewable, alongside the project that produced it:
.claude/skills/design-system-migration/

# Available in every other project, one source of truth:
ln -s "$PWD/.claude/skills/design-system-migration" ~/.claude/skills/design-system-migration
```

One copy, in git, usable everywhere. When a second app has actually exercised it, extract it to its
own repository — by then you will know which parts are general, which is precisely what you do not
know yet.

The alternative, writing straight into `~/.claude/skills/`, loses history on the artefact that most
needs it. This working tree has been rolled back six times.

---

## 3. Two skills for greenfield and brownfield? No

The overlap is most of it. Shared: the operating loop, audit discipline, the document model, the
preview protocol, component building, copy review, accessibility. Brownfield-only: the migration map,
the "not migrated" list, dead-class detection, and the procedure for retiring a legacy pattern.

That is **four files** of difference against a shared core. Two skills would duplicate the core, and
the duplicate would drift — the same argument as above, with the same evidence behind it.

One skill, migration module optional. It asks once: *is there a legacy system being retired?* If not,
three reference files and one audit never load.

Two reasons that matter more than the file count:

- **Greenfield becomes brownfield within months.** The first inconsistent button ships in week three.
  A greenfield-only skill would grow the migration half anyway, badly and late.
- **The expensive lessons are not migration-specific.** Scope-is-a-claim, revert-testing, positive and
  negative controls, measure-do-not-estimate — none of them care whether there is legacy code. They
  were learned during a migration; they are not about migration.

---

## 4. How prescriptive? Normative, with the evidence attached

You said it should read like the big open-source design systems. What those actually do:

| System | House style |
| --- | --- |
| **GOV.UK** | States the rule, then publishes the *evidence* — user research, and a design history recording what was tried and rejected |
| **Primer** | Rule first, accessibility rationale immediately after, component named |
| **Carbon** | Rule, rationale, do/don't pair, and the token that implements it |
| **Polaris** | Rule with a short *why*, then "consider" cases for the exceptions |
| **Material** | Rule stated flatly as law, rationale secondary |

GOV.UK is the closest fit, because it is the one that shows its working — and this project already
writes that way. `design.md` says *"at most 3 fills can be mutually 3:1 apart on white; 4 bands is
arithmetically impossible"*, and `design-decisions.md` records the alternatives rejected. That is a
design history, not a component catalogue.

### The recommendation: every rule tagged **Portable** or **Local**

A design system can say *"buttons are 40px tall"* flatly, because it is the law of one product. A
skill spanning apps cannot — and the failure mode if it pretends otherwise is this app's arbitrary
constants cargo-culted onto an app where they are wrong.

So state rules with the same force, and tag the scope:

> **Portable · Every interactive target is at least 24×24px.** WCAG 2.2 2.5.8. Not a preference.
>
> **Portable · An icon-only control is named by `aria-label` *and* a tooltip, never `title`.** The
> `title` attribute is silent on keyboard focus and fails WCAG 1.4.13 three ways. Carbon, Primer,
> MUI, Ant Design, Salesforce and Atlassian each ship a component for this; none uses `title`.
>
> **Local · Every control in an actions column is 28px.** Pick a size and enforce it — the value is
> yours. Ours is 28 because that is the kebab trigger's height, and a column mixing sizes stepped by
> 2px visibly. The *rule* is uniformity; the *number* is a local decision.

Roughly: WCAG criteria, naming, semantics and the audit discipline are Portable. Spacing scales,
colour ramps, pixel values and component inventories are Local. **When in doubt it is Local** — an
under-claimed rule costs a decision; an over-claimed one costs a wrong implementation that looks
authorised.

Measurements keep their provenance: *"measured on Human Essentials at 1440px"*, never *"tables are
1,225px wide"*. Evidence is what makes the rules credible, and unlabelled evidence is what makes them
wrong somewhere else.

---

## Revised scope

Since the next app is the same stack, the earlier Option B/C split is the wrong axis. The right one:

**Ship the agnostic core plus a complete Rails/Tailwind adapter.** The adapter carries all 33 audits,
because on a same-stack app they work as they are. The core carries the loop, the discipline, the
document model and the preview protocol, with no Rails in it.

Three things, in order:

1. **Migrate the 17 hardcoded-list audits onto route enumeration** — in this repo, for this app's
   benefit. It is the prerequisite for an agnostic core and it closes a live class of blindness.
2. **Extract the core**, roughly 500 lines, with the Portable/Local tagging throughout.
3. **Extract the Rails/Tailwind adapter**, which is mostly moving files, plus the five sign-in values
   and the route-enumeration command.

Still deferred: a *second* adapter. There is no evidence yet about which assumptions are shared
between stacks, and inventing one from a sample of one is the mistake at prompt `[158]`.

## What I would still do first

Build the core's two hardest files — `SKILL.md` and `reference/audit-discipline.md` — and use them on
one real task before writing the rest. Not because the plan is doubtful, but because every audit in
this project was wrong on its first run, and a skill is an audit of a process.
