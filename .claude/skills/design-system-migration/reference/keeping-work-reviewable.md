# Keeping the work reviewable

Eleven instructions in the source project were about setup, and every one of them blocked everything
else until it was resolved. *"I can no longer access localhost."* *"Can't you leave the server
running? It keeps going away."* *"I am not able to see the design preview."*

**If the person you are working with cannot look at the app, the loop stops.** Treat their ability
to see the work as a precondition, not a convenience.

## Keep the server up

Start it so it survives your next command, and check it is still up before asking anyone to look at
something. A server that dies whenever a tool call ends produces a stream of "it's gone again" that
costs more than getting it right once.

If the app is behind a proxy or a tunnel, find out what that needs — in the source project, forms
silently failed CSRF and reported it as *"your session expired"* until an environment variable was
set.

## Seed enough data to see the thing

A page with no rows shows an empty state, not the design. If someone is reviewing a calendar, a
report or a table, the data has to exist first.

Two rules learned the hard way:

- **Make seeding repeatable.** Ad-hoc records created in a console are gone next time and nobody
  knows what they were. Put it in the project's seed task.
- **Do not design from what the seed happens to contain.** A chart was sized around seeded data that
  turned out to be a placeholder; the real range was completely different. Ask what the data *can*
  be — *"this could be fifty items"* — before designing for what you can see.

## Serve previews over HTTP, and print a URL

Never a file path. The reviewer cannot click it, and half the time it will not render.

Put the mock-up where the app already serves static files, keep the tracked copy in the repository,
gitignore the served copy, and print the address. In the source project *"I am not able to see the
design preview"* appeared three times before this was fixed properly.

## Say how to test it

When you finish something, say what to click. Not "the form now validates" — *go to this page, leave
this field blank, press Save, you should see this*.

Twice in the source project the request was explicit: *"tell me how to test that in the app"*, and
*"show me how to test it, I cannot follow what you are saying."* A change nobody can check is a
change nobody can trust.

## Confirm before anything destructive

*"Are you recommending something destructive that will remove things from my database?"* is a
question you want asked **before** you run it, not after.

Deleting rows, dropping columns, rewriting history, force-pushing: say what will be lost and get
agreement. If a thing is reversible, say so and how. If it is not, say that louder.

`session-durability` covers the other half of this — committing often enough that a lost session
costs minutes.
