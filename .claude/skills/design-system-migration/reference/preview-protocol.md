# Preview before you build

The habit that produced the most value, and the one most often skipped.

## The rule

**Before building a screen, show what it will look like and let the user choose.**

Not a description. Not a diff. A rendered page they can open in a browser and look at, with two to
four real options and a recommendation.

In the source project a user said, after being shown a text description: *"I want to see it as HTML
like it would look like in the app so I can make a good decision."* That is the bar.

## What a preview contains

- **Two to four options**, each a real rendering — not a wireframe, not a sketch.
- **What each costs.** Not just how it looks: what it breaks, what it needs, what it rules out.
- **A recommendation with reasoning**, so the user can disagree with the reasoning rather than the
  conclusion.
- **What the industry does**, with products named.
- **The current state alongside**, so the comparison is visible rather than remembered.

## How to serve it

Write the mock-up as standalone HTML, copy it where the app serves static files, and **print a URL**
— never a file path. A file path is not a preview; the user cannot click it and half the time it
will not render.

Keep the tracked copy in the repository and gitignore the served copy.

## What to expect back

Usually a letter and a rider: *"go with B, but make sure it matches the destructive ghost styling,
and then check every empty state."* **The riders are where most of the rules come from.** They are
the part to write into the spec.

Sometimes the answer is "leave it as it is today", and that is a result — it is now a decision
rather than an accident, and it goes in the decision log.

## When a preview is wrong

Two failure modes, both from the source project:

- **Sizing a design from seed data.** A chart was designed around what the seeded database happened
  to contain; the real range was different. Ask what the data can actually be — *"the categories for
  this report could be 50 items"* — before designing for what you can see.
- **Previewing the look and not the interaction.** A design that looked right made the user lose
  their scroll position on every selection. Walk the interaction, not just the render.
