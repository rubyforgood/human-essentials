# Writing rules in the spec

The spec is normative: it says what the UI *must* do. Write it like the big open-source design
systems, with one addition they do not need.

## House style

GOV.UK is the model, because it is the one that shows its working: the rule, then the evidence, then
a design history of what was tried and rejected. Primer leads with accessibility rationale. Carbon
pairs each rule with a do/don't and the token that implements it. Material states the rule flatly as
law.

A rule reads:

> **Every visible control in an actions column is an icon at 28px.** A labelled small button is
> 30px, and a column mixing the two steps by 2px — visible on two screens. Carbon and Salesforce
> both ship uniform icon-only row actions, which is the part they evidence.

Imperative. Then why. Then who else does it, or what was measured.

## Portable or Local — tag every rule

A design system can say *"buttons are 40px"* flatly, because it is the law of one product. A rule
that will be read on another app cannot, and the failure mode is one app's arbitrary constants
cargo-culted somewhere they are wrong.

> **Portable · Every interactive target is at least 24×24px.** WCAG 2.2 2.5.8. Not a preference.
>
> **Local · Every control in an actions column is 28px.** Pick a size and enforce it — the value is
> yours. Ours is 28 because it matches the kebab trigger's height. The *rule* is uniformity; the
> *number* is a local decision.

Roughly: WCAG criteria, naming, semantics and audit discipline are **Portable**. Spacing scales,
colour ramps, pixel values and component inventories are **Local**.

**When in doubt it is Local.**

## Evidence keeps its provenance

*"Measured on this app at 1440px"*, never *"tables are 1,225px wide"*. Evidence is what makes a rule
credible; unlabelled evidence is what makes it wrong somewhere else.

## A rule with no audit is a suggestion

Every rule that can be checked should be. When you add a rule, add the check — or write down that
you did not and why. In the source project the rules that survived unchanged were the ones with an
audit behind them; the ones without drifted within a fortnight.

## Correcting a rule

If a claim in the spec turns out to be false, **annotate it in place** — say what was claimed, what
was measured, and which is right. Do not silently edit. Somebody made a decision on the strength of
the old claim and needs to be able to find it.
