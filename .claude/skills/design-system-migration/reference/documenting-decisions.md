# Documenting decisions

Six documents, each with one job and a trigger that says when it changes. **Update them in the same
commit as the work.** A stale document is worse than none, because the next person trusts it.

| Document | Job | Update it when |
| --- | --- | --- |
| The **spec** (`design.md`) | Normative. What the UI *must* do | A component, token, layout or convention changes |
| The **change log** | What happened and when. One row per commit | Always |
| The **decision log** | Why this and not the obvious alternative | A judgement call worth explaining |
| The **domain model** | Models, associations, enums, roles | The data shape changes |
| The **migration map** | Old pattern → new, and what is *not* migrated | Something is migrated or retired |
| **Onboarding** | Setup, conventions, and a user-facing half | Anything a *user* sees changes |

## Which document

The distinction that saves the most time:

- **A code comment** explains the line.
- **The decision log** explains the choice — including what was rejected.
- **The change log** says when it landed.

Use all three when the choice was not obvious. The comment answers "why is this like this" for
someone reading the code; the decision log answers "why not the other way" for someone proposing to
change it.

## The rules that make them worth keeping

**Measure before you write a number.** Every figure should be measured in the session it is written.
In the source project, recalled numbers were wrong twice — including a claim about the design system
that had never been checked and turned out to be false.

**Name what you chose not to do.** A known leftover that is written down costs nothing. The same
leftover undocumented costs the next person an afternoon deciding whether it matters.

**Record the alternatives you rejected, and why.** This is what makes a decision log more useful
than a component catalogue. "We chose B" is not a decision; "we chose B because C would have broken
every saved import file" is.

**Append; do not rewrite history.** A decision log entry that turns out wrong gets an annotation,
not an edit. Architecture decision records are historical — supersede, never revise.

**The user-facing half goes stale quietly**, because contributors do not read it. Check it every
time, not only when it seems relevant.

## Cadence

**Work, document, commit, push — at every checkpoint.** Not batched at the end.

A checkpoint that is not pushed is a checkpoint that can be lost. In the source project the working
tree was rolled back six times without `HEAD` ever moving, and twice it arrived disguised as a bug
report about a fix that had already been made. Committing is the only protection.
