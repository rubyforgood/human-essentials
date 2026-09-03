# Copy and language

Nine of roughly two hundred instructions in the source project were about words, and they produced
some of the most-repeated rules. Copy is part of the design system, not a separate concern.

## Sentence case for everything

Headings, buttons, labels, table column headers, menu items. Not Title Case.

The exception is a proper noun and an acronym: *ZIP code*, not *Zip code* — ZIP is Zone Improvement
Plan. Keep an acronym list in the copy check, or it will flag every legitimate one.

## Helper text is a sentence, and it says something the title cannot

The commonest defect: helper text that restates the heading.

> **Requests** — *"Essentials requested by partner agencies."*

That says nothing the word "Requests" did not. A subtitle earns its place by answering the reader's
question, not the writer's: what this page is *for*, what the ordering is, what the scope is.

Two tests, both from real rewrites:

- **Would the page be worse without it?** If not, delete it. A deleted subtitle is better than a
  redundant one.
- **Does it repeat something already on screen?** The pagination line already says "Showing 1–15 of
  119 requests". A subtitle saying "119 requests" is duplication.

Where the noun is jargon — *kit*, *product drive*, *inventory audit* — the sentence carries the
gloss **and** the action. That is when a subtitle is genuinely load-bearing.

## Write to the reader, in the second person

*"Say how many of each item you need"*, not *"Users should specify quantities"*. And not the first
person plural: **"we" has no referent** in an app used by two hundred organisations. Sweep for it.

## Inclusive, and check rather than assume

- **No gendered defaults.** They/them for a person whose pronouns you do not know.
- **No ableist idiom.** *insane*, *crazy*, *blind to*, *cripple*, *dumb*, *sanity check*, *lame*.
- **No sensory-only instruction** — WCAG 1.3.3. *"The button on the right"* fails for a screen
  reader and after a reflow; name the control.
- **No "please".** Politeness filler in UI copy is noise, and it reads as apologetic in an error.
- **No shouting.** Capitalised runs that are not acronyms.

**Make it a check, not a review.** These are all greppable, and a list in a script catches the
eleventh instance a human reviewer would miss. Plant a violation and confirm the check reports it —
in the source project the copy audit was verified by planting *"Please"*, *"below"* and *"insane"*
and confirming all three were caught.

## Button labels: two or three words, and the page supplies the rest

*"Invite user to this organization"* in a card titled **Users**, on a page whose heading is the
organization's name, repeats the context twice. **"Invite user"** — verb plus object.

WCAG 2.4.4 is Link Purpose *In Context*, and the heading and card **are** that context. The rule is
not brevity for its own sake; it is not restating what the screen already says.

## Error messages say what to do next

A log line is not an error message.

> *"Cannot deactivate item - it is in a storage location or kit!"*

versus

> *"Adult Briefs still has stock in a storage location, or belongs to a kit. Move or distribute the
> remaining stock and remove it from any kits, then deactivate it."*

Name the record, the reason, and the next step. If a reason is worth showing at all, it is worth
being able to act on.

## When you change wording, change it everywhere

A rewritten phrase in one place is a new inconsistency. Sweep, and expect specs to be asserting the
old string — those are expectations about a design that was deliberately replaced, so rewrite them
rather than bending the code to keep them green.
