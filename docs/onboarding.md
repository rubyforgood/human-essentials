# Onboarding

For anyone new to Human Essentials. Two halves, depending on why you are here.

- **[Part 1 — Maintaining the app](#part-1--maintaining-the-app)**: the domain, the code, how to
  run it and test it. For contributors and maintainers.
- **[Part 2 — Using the app](#part-2--using-the-app)**: what the app does and the words it uses.
  For bank staff, partner agencies and the people supporting them. No Ruby required.

If you only want to build a screen, [design.md](../design.md) has a playbook.
[domain-model.md](domain-model.md) is the reference for how records relate, and
[migration-map.md](migration-map.md) says what replaced the markup that predates the design
system.

---

# Part 1 — Maintaining the app

## What the app is for

Human Essentials is inventory management for **diaper banks** and **essentials banks**:
non-profits that collect nappies, period supplies and other essentials, and pass them to local
agencies who hand them to families. It is a Ruby for Good project, in production for 200+
organizations.

The shape of the work it supports:

```
  goods in                    the bank                       goods out
  ────────                    ────────                       ─────────
  Donation      ─┐                                    ┌─  Request      (a partner asks)
  Purchase      ─┼──►  StorageLocation  ──────────────┼─►  Distribution (the bank sends)
  ProductDrive  ─┘        (inventory)                 └─  Transfer     (between locations)
                                │                          Adjustment   (corrections)
                                └──────────────────────►   Audit        (counting the shelves)
```

## The two audiences

One application, two front doors, and they use different words for the same things.

| | Bank staff | Partner agencies |
| --- | --- | --- |
| Routes | `/` and most top-level paths | `/partners/*` |
| Shell | `layouts/essentials_app` | `layouts/essentials_partner` |
| Who they are | staff and volunteers at the bank | the agencies that receive goods |
| They say | "requests", "distributions" | "essentials requests", "my profile" |
| Navigation | 36 destinations in four collapsible groups | six, flat |

Keeping the vocabularies apart is deliberate. If you are editing partner-facing copy, use the
partner's words.

## Roles

Defined in `app/models/role.rb`, assigned with Rolify, and **scoped to a resource** — a role is
always "admin *of this organization*" or "partner *for this agency*".

| Role | Scope | Can |
| --- | --- | --- |
| `org_user` | an Organization | day-to-day work: record donations, build distributions |
| `org_admin` | an Organization | that, plus settings, users, audits, partner approval |
| `partner` | a Partner | the partner portal only |
| `super_admin` | global | `/admin/*`: organizations, users, base items, account requests |

A user can hold several roles and switch between them (the account menu in the top bar). What
they see is a function of the role they are currently in, which is why almost every controller
runs through `authorize_user` in `ApplicationController`.

## The domain model

A tour of the parts you meet first. [domain-model.md](domain-model.md) is the full reference —
polymorphic joins, the event catalogue, the partner state machine — for when you need it.

### Organization is the tenant boundary

22 models `belong_to :organization`. Almost every query is scoped to one, and the current
organization comes from the user's role, not from a parameter. When you add a model that holds
bank data, it almost certainly needs `belongs_to :organization` and a scope to match.

```
Organization
  ├── users (through roles)          ├── items ──────── item_categories
  ├── partners ── partner_groups     ├── kits
  ├── storage_locations              ├── barcode_items
  ├── donations, purchases           ├── vendors, manufacturers, donation_sites
  ├── distributions, transfers       ├── product_drives ── product_drive_participants
  ├── adjustments, audits            └── requests
```

### Items, and what an Item actually is

- **`BaseItem`** is the system-wide template — "Diapers, size 1". Shared by every organization,
  maintained by super admins.
- **`Item`** is one organization's version of a base item, with its own name, value, category
  and visibility to partners. Linked to its base item by `partner_key`.
- **`ItemCategory`** groups items, and is how a `PartnerGroup` decides what its partners may
  request.
- **`Kit`** is a bundle of items that can be allocated and deallocated as a unit.
- **`LineItem`** is polymorphic (`itemizable`): the same join carries the contents of a
  donation, a purchase, a distribution, a transfer, an adjustment and an audit.

### Inventory is a ledger, not a column

This is the thing most likely to surprise you.

There is no `quantity` column to read. Every action that moves stock writes an **`Event`**
(single-table inheritance, JSONB payload): `DonationEvent`, `PurchaseEvent`,
`DistributionEvent`, `TransferEvent`, `AdjustmentEvent`, `AuditEvent`, `KitAllocateEvent`,
their `*DestroyEvent` counterparts, and `SnapshotEvent`.

To read inventory, replay them:

```ruby
InventoryAggregate.inventory_for(organization_id)
```

It starts from the most recent `SnapshotEvent` and replays everything after it. `Event` also
validates consistency by replaying on write, so a bug that corrupts inventory tends to surface
immediately rather than silently.

Do not add a query that sums a quantity column. There isn't one, and if you find something that
looks like one it is a cache.

### Requests become distributions

The central workflow, and the one worth tracing end to end on your first day:

1. A partner submits a **`Request`** — by quantity, by individual, or by child
   (`request_type`), depending on what the bank has enabled for them.
2. Bank staff open it and start a **`Distribution`**, which pre-fills from the request.
3. Saving runs `DistributionCreateService`, which writes a `DistributionEvent`, marks the
   request fulfilled and links the two.
4. The partner sees the distribution in their portal.

`Partner` has a `status` (`uninvited`, `invited`, `awaiting_review`, `approved`,
`recertification_required`, `deactivated`) that gates most of this, and a `Partners::Profile`
holding the agency detail the bank collects.

## How the code is organised

| Where | What | Count |
| --- | --- | --- |
| `app/models` | domain and associations | 67 |
| `app/controllers` | thin; they delegate | 72 |
| `app/services` | business logic, `{Model}{Action}Service` | 67 |
| `app/events` | the inventory ledger and its aggregate | 17, plus 7 value types |
| `app/queries` | complex reads extracted from controllers | 7 |
| `app/views` | ERB; the design system lives in `shared/essentials` | 421 |
| `app/javascript/controllers` | Stimulus | 28 |

Conventions worth knowing before your first PR:

- **Business logic goes in a service**, not a controller and not a callback. Follow
  `DonationCreateService` for the shape.
- **Records are usually deactivated, not deleted.** Most models carry an active/deactivated
  status or a `deleted_at`; `Request`, `User` and `StorageLocation` use `Discard` proper. Check
  before you reach for `destroy`.
- **Changes are audited.** `has_paper_trail` records versions on 32 models.
- **Filtering** goes through the `Filterable` concern and `class_filter`.
- **Exports** go through `app/services/exports/*`.

## Getting it running

```bash
bin/setup     # gems, database, seeds
bin/start     # web on :3000, job worker, Tailwind watcher
```

`bin/rails db:seed` is safe to run again on an already-seeded database. It was not until
2026-09-03: `Seeds.seed_base_items` passed `created_at`/`updated_at` to `find_or_create_by!`,
which puts them in the lookup, so the find could never match an existing row and the create it
fell through to failed on `BaseItem`'s unique name — `Validation failed: Name has already been
taken`, on the second seed of any database.

Seed logins — every password is `password!`:

| Role | Email |
| --- | --- |
| Bank admin | `org_admin1@example.com` |
| Bank user | `user_1@example.com` |
| Super admin | `superadmin@example.com` |
| Partner | `verified@example.com` |

The seeds create three organizations, seven partners and a few hundred records, including
partners in the awkward states (invited but not accepted, awaiting approval, recertification
required) that are worth testing against.

### Behind a proxy or tunnel

If you reach the app through a port forward or a TLS-terminating tunnel, Rails cannot always
work out the scheme the browser used, and CSRF rejects every form — which surfaces as *"Your
session expired"*, pointing nowhere near the cause. Start it with `TUNNEL=1`, which relaxes the
origin check (not the token) in development only:

```bash
TUNNEL=1 RAILS_DEVELOPMENT_HOSTS=".example.com" bin/rails server -b 0.0.0.0
```

## Testing

```bash
bundle exec rspec                          # everything
bundle exec rspec spec/models/item_spec.rb # one file
bundle exec rspec spec/system              # the browser suite
```

CI splits it: `rspec` for unit and request specs, `rspec-system` for system and request specs
across six parallel nodes. System specs drive real Chromium through Cuprite; failure
screenshots land in `tmp/screenshots` and `tmp/capybara`.

A third workflow, **`audit-selftest`**, runs on every push and pull request. It does not audit the
app — it tests the *audits*, by breaking a page on purpose and by leaving it alone on purpose. It is
the only workflow that boots a real server and drives it with Playwright, which is why it is its own
job rather than a step in `rspec-system`: that suite already runs a browser, in-process, a different
way. About two minutes, most of it downloading Chromium.

If you change anything in `bin/design/`, that is the job that will tell you about it. Run it
yourself first — `pw bin/design/audit-selftest.js` — it takes eleven seconds.

Two things that will save you an afternoon:

- **Set up inventory with the helper**, not by writing quantity columns:
  ```ruby
  TestInventory.create_inventory(organization, { storage_location.id => { item.id => 50 } })
  ```
- **Run the system specs for anything you touch in a view.** Request specs do not load
  JavaScript. During the design system migration three classes of defect were invisible to
  everything except the browser suite: markup a browser reparses into a different shape,
  Stimulus controllers toggling classes that no longer exist, and forms whose fields had ended
  up outside the form.

**Do not run `assets:precompile` locally.** The pipeline is Propshaft (ADR 0012), which serves
assets straight from the load path in development and test — precompiling *freezes* them behind
`public/assets/.manifest.json` until you delete that file. If a stylesheet or a module looks
stale, that file is usually why.

`assets:clobber` also deletes the compiled Tailwind stylesheet, because `tailwindcss-rails`
enhances the task. Follow it with `bin/rails tailwindcss:build` or every page will 500 on a
missing `tailwind.css`.

**Development shows the same page size as production.** Kaminari used to default to 5 rows in
development and staging and 50 everywhere else, so a page under review never looked like the
page a bank sees — you got a pager under a five-row table and never saw the long one. It is 25
everywhere now, and each index names its band (`Pagination::TALL`, `MEDIUM` or `COMPACT`). If a
table you are working on looks suspiciously short or long, check the band before the data.

## The design system

[design.md](../design.md) is normative. In short: Tailwind v4, Figtree, indigo on slate,
sentence case, components as partials in `app/views/shared/essentials/` and helpers in
`EssentialsUiHelper`. Build a page from the partials rather than from utility strings, give the
page exactly one `<h1>`, name every control, and never let colour be the only signal.

```bash
ruby bin/design/status.rb            # which controllers are on a design system layout
ruby bin/design/page-audit.rb        # defects and debt, per view
ruby bin/design/shell-first-audit.rb # a migrated shell around an unmigrated body
pw bin/design/wayfinding-audit.js    # screens that can be reached but not left
bin/design/serve-mockup <name>       # serve a design preview and print its URL
python3 bin/design/undefined-classes.py   # classes that render as nothing
pw bin/design/route-sweep.js         # every screen the router knows, in a real browser
pw bin/design/responsive-audit.js    # the same screens at 320 to 1440
pw bin/design/form-validation-audit.js    # required marking and error handling
pw bin/design/keyboard-audit.js       # tab order, and again with WIDTH=375
bin/rails runner bin/design/dead-routes.rb   # routes whose request would raise
bin/rails runner bin/design/dead-code.rb     # code no route, render or caller reaches
```

`route-sweep.js` asks Rails for the page list rather than carrying one. That matters: the
version with a hardcoded list of 56 paths missed three pages that were in the sidebar the whole
time and had no `<h1>`.

`shell-first-audit.rb` is the one to run when a page "looks unmigrated" but every other check says
it is fine. All the others ask whether anything from the old system is still present; this one asks
whether the page is built the way the new system builds things. A page can have a proper header, a
proper card, no Bootstrap class and no console error, and still hold a body nobody converted. Read
the narrowings in [bin/design/README.md](../bin/design/README.md) before adding a check to it --
four of its eight were false-positive factories first, and the reasons are the useful part.

**Two dev-only overlays will fool a DOM-reading audit.** rack-mini-profiler and the `bullet` gem
both inject markup into every development page -- tables, `<br>`, a floating panel. A probe written
during this work reported 19 non-`.data-table` tables on a page with one table, and all 19 were the
profiler's. Exclude `.profiler-results, .profiler-result` and bullet's notice before believing a
count.

**One page gutter per page**, with the page header inside it, is the layout rule most often got
wrong -- 31 templates closed the wrapper after the header and opened a second one for the content,
which stacks two paddings and puts 48 or 72px under the heading where the design system's number is
24. `shell-first-audit.rb` checks for it now.

**Match the gutter, not the whole class string.** The first version of that check looked for two
occurrences of `px-4 py-6 sm:px-6 lg:px-8` and missed 17 of the 31, because they open the header
wrapper with `pt-6`. The stable part is `px-4 sm:px-6 lg:px-8`.

**A field rendered inside `f.input ... do` has none of the design system's behaviour.** The block
*replaces* the wrapper's input, so it skips the whole `:essentials` pipeline: no classes, no width,
no `aria-required`, no `aria-invalid`, no inline error. That is how a 44px number field ended up
with a 92px placeholder cut off mid-word, and how three partner profile fields lost their error
handling earlier. Check every one of them.

**Never put a border on a `<fieldset>` that has a `<legend>`.** The legend is rendered *in* the top
border and the browser cuts a gap for it, so the rule starts where the legend text ends. Use
`shared/essentials/form_section`, which bands a long form the way a long record is banded.

`dead-code.rb` is the mirror of `dead-routes.rb` and reports 118 findings today — six controllers
no route reaches, 24 helper methods nothing calls, 81 files in `public/` nothing links to. They
are documented rather than deleted; read [design-decisions.md](design-decisions.md) before acting
on any of them, and read the exemptions at the top of the script before adding a check. Every one
of them is a false positive that was believed once.

**You do not have to stop the dev server to run the full suite — but do stop it *properly* when
you stop it at all.** This note used to say the opposite, and the advice was treating a symptom.

The box has 8GB and the system specs add a Chromium per example, so memory does matter. Two things
were eating it, neither of them inherent:

- **`workers 2` in `config/puma.rb`.** A two-worker cluster is ~1.4GB for a server one person is
  looking at. `WEB_CONCURRENCY=0` runs Puma in single mode: **301MB**.
- **Orphaned `rails jobs:work` processes.** Killing foreman with `pkill -f foreman` does not reap
  its children. Every restart left the Delayed Job worker and the Tailwind watcher behind, and
  after six restarts in one session there were **seven job workers holding 2,260MB** — which is
  the memory pressure that made the suite look flaky in the first place. Foreman shuts them down
  cleanly on Ctrl-C in a real terminal; a backgrounded one needs the children killed by name.

Started lean the whole stack is **930MB**, and the full suite runs **2,962 examples, 0 failures**
with the server up and still serving afterwards. Check `ps -eo rss,cmd | grep jobs:work` if memory
looks wrong — more than one of them means an earlier restart leaked.

If a system spec fails in a file you have not touched, still check `free -m` before you check the
diff. The failure mode is real; it is just not caused by the server existing.

**Copy is audited too.** `ruby bin/design/copy-audit.rb` reads the app's words -- link text that
says nothing out of context, instructions that depend on position, gendered or ableist wording,
"please", and shouting. It reads *copy*, not source, so it will not flag an identifier that
happens to contain a pattern. `design.md` has the rules under **Copy**; the audit checks the
mechanical half of them.

**Two things about running the browser audits.** They default to `BASE_URL=http://127.0.0.1:3000`,
so point them somewhere else with that variable rather than assuming they follow whatever server
you started last. And `config/application.rb` is not reloaded in development — restart the server
after changing it, or you will spend an afternoon watching an audit report a defect you fixed.

`dead-routes.rb` is the one that does not need a browser. It asks, of every route, whether the
request would raise — 28 did before it existed, nearly all of them actions `resources :x`
generates and the controller never implemented. Run it after touching `config/routes.rb`; it
exits non-zero when anything is dead.

## Where decisions live

| Document | What it is |
| --- | --- |
| `docs/architecture/decisions/` | ADRs. Why a structural decision was made, at the time. Not edited afterwards. |
| `docs/design-decisions.md` | Running log of UI judgement calls, with the reasoning. |
| `design.md` | The design system as it stands now. |
| `docs/migration-map.md` | What replaced what, and how to verify. |

**Keep them current.** If you make a decision worth explaining, add it to the design decision
log in the same PR. If you change how a page is built, update `design.md`. If you finish
migrating something, update the migration map. A stale document is worse than none, because
someone will trust it.

## Getting help as a contributor

- `docs/` for the rest of the developer documentation
- Ruby for Good Slack, `#human-essentials`
- The user guide: https://rubyforgood.github.io/human-essentials/

---

# Part 2 — Using the app

For bank staff, partner agencies and the people supporting them. No Ruby required. This
explains what the app does and, more usefully, the words it uses — most confusion here is
vocabulary rather than buttons.

## If you work at a bank

You sign in and land on a **dashboard**: what is running low, which requests are outstanding,
which partners are waiting on you.

### Getting stock in

Two kinds of record, because they answer different questions later:

| | Use when |
| --- | --- |
| **Donation** | Goods given to you. You pick a source: a **product drive**, a **manufacturer**, a **donation site**, or **misc. donation** for anything else. |
| **Purchase** | Goods you bought, recorded against a vendor with what you spent. |

A **product drive** is a collection event. It is not a third kind of intake — donations recorded
against it roll up into its totals, which is how you find out whether a drive was worth running.

Everything arrives into a **storage location**: a warehouse, a room, a set of shelves. Inventory
is counted per location, which is why moving goods between your own locations is a record rather
than a note to yourself.

**Five lists can be filled from a spreadsheet** rather than typed in one at a time: partners,
storage locations, donation sites, vendors and product drive participants. Each has an **Import
CSV** button on its page that offers a template to start from. Manufacturers is not one of them
— it had a button until August 2026, but nothing behind it, so pressing it only produced an
error page.

**Entering the items themselves is scan-first.** Every form that takes a list of items — donation,
purchase, distribution, transfer, adjustment, audit and kit — has **one barcode field at the top
of the items card**. Scan into it and a row appears below with the item and the quantity that
barcode stands for. Scan the same barcode again and it adds to the row that is already there
rather than starting a second one; scan it a third time and it asks how many packages you have in
total, so a pallet is one question instead of forty scans. The field empties and keeps the cursor
after each scan, so a handheld reader can run straight down a delivery without anyone touching the
keyboard. If a barcode is not known yet, a dialog offers to record it, and the scan then completes
by itself.

Nothing forces you to scan: the **Item** dropdown on each row is searchable and always available,
and **Add another item** adds an empty row. The foot of the card keeps a running count — *"3 items
· 412 units"* — which is the quickest way to check a long delivery before saving. Until August
2026 every row carried its own barcode field, so a ten-line donation showed ten of them.

### Getting stock out

A partner submits a **request**; you turn it into a **distribution**. Two records, deliberately:
the request is what was asked for, the distribution is what actually moved. Keeping both is what
lets you see whether you met the need rather than only what you sent.

### Keeping the numbers honest

- **Transfer** — stock moved between your own storage locations.
- **Adjustment** — a correction, for when the shelf and the system disagree and you know why.
- **Audit** — a formal count of a location. If it finds a discrepancy it produces an adjustment,
  so the correction is on the record with its reason. Admin only.

### Partners

Partners are **invited**, complete a profile, and are **approved**. Along the way their status
moves through: uninvited → invited → awaiting review → approved. Later it may become
*recertification required*, or *deactivated*.

A **partner group** decides which item categories its members may request — a group is how you
say "shelters can request cots, schools cannot". A partner in no group can request anything, and
the app says so on the partner's page: **All items requestable**.

### Reports

**Reports** in the sidebar opens a hub: eleven reports in six groups — Distributions, Donations,
Purchases, Requests, Compliance and Activity. Most take a date range and export to CSV.
**Annual survey**, under Compliance, collects the yearly figures many banks have to file.

There is no separate *summary* report for distributions, donations, purchases or product drives
any more. Those totals sit at the top of the matching index page, which has the full table and
all of its filters as well.

They appear as a row of figures in a single card above the table, with the period they cover
named just above it — so *Over the last 30 days* over *Donations 13 · Items received 106,644 ·
Money raised $1,250.00 · In-kind value $11,312.00*. **The figures describe whatever the filters
are currently showing, not the whole database.** Change the date range and they change with the
table.

### Picking a date range

Every page that filters by date uses the same control: a button showing the range you are looking
at, opening a panel of the usual ones — *Today*, *Last 7 days*, *Last 30 days*, *This month*,
*This year*, *All time* — beside **From** and **To** boxes for any other range.

**There is nothing to press.** Choose a preset and the panel closes and the table updates. Type
or pick your own From and To and it updates as you go, with the panel staying open so you can
nudge either date. If you put the dates the wrong way round, they swap themselves — you will not
be told off for it.

The button shows the range in the usual American form, **6/19/2026 – 9/19/2026**, so it fits and
you can read it at a glance.

**Filters apply as you choose them.** There is no Filter button: pick a value and the table and
its totals update underneath, without the page reloading and without losing your place. Typing
in a filter waits until you stop.

Filters live behind a **Filters** button on every page, so the data starts at the top. Whatever
you have set is listed beside that button as a row of chips, with a count on the button itself, so
nothing is ever narrowing your results without saying so. Click the **×** on a chip to drop that
one filter, or **Clear all** to drop the lot.

**Date range** is one of those filters, and it opens a small panel: the common ranges down one
side, and **From** and **To** boxes down the other for anything else. Set both and press **Apply**.

A storage location has a filter of its own on its **Inventory** tab: **Show inventory at date**,
which asks what was on those shelves on a given day rather than narrowing a list to a window.
It sits behind the same Filters button, chips the same way, and changing it leaves you on the
Inventory tab — you do not have to find your way back to it.

A page you have not filtered opens on *Last 2 months and next month*. It reaches into the future
on purpose: a distribution can be scheduled before it happens, and a range ending today would
hide everything already booked in.

### How many rows am I looking at?

**If the dev server keeps dying, it is the CSS watcher finishing, not the server crashing.**
`bin/start` runs three processes under foreman, and foreman kills the whole group when *any* of
them exits. The Tailwind CLI's `-w` needs a TTY; without one — under foreman, in a container, over
ssh — it decides there is nothing to attach to, prints `Done in 1s` and exits **0**. Foreman then
SIGTERMs the web server and the worker. Nothing in the log looks like an error, which is why this
was mistaken for a memory problem more than once.

`Procfile.dev` passes `[always]` now, which keeps the watcher attached without a TTY. It also binds
the server to `0.0.0.0`: the Rails default is localhost only, which is unreachable through a port
forward, and this app is normally viewed through one. If you are behind a forward or a
TLS-terminating tunnel, still start with `TUNNEL=1` or CSRF rejects every form and calls it
"Your session expired".

**The calendar asks two questions separately: how long, and how it looks.** *Month* or *Week* for
how much time, *Grid* or *List* for how to draw it — so you can have a week as a grid, a month as a
plain list, or any of the four. Week as a grid is the useful one when a day is busy, because the
month grid hides everything past the first event behind "+5 more". A month as a list is the one to
reach for when you want every distribution in the month on one page.

Both choices go in the address bar, so you can send someone a link to exactly what you are looking
at, and Back returns to where you were. On a phone it opens on a week, as a list.

**A list tells you what it covers** — "Monday, September 7 – Sunday, September 13 · 1 of 7 days has
a distribution" — because a list only draws the days that have something on them, and one row for a
whole week otherwise looks like one row for all time.

There is deliberately no Day view: across a year, a day held **1.9 distributions on average**, and
just one on 13 days out of 22.

**If you found the Week button did nothing, that was a real bug and it is fixed.** In a window
narrower than about 992 pixels — a laptop at 150% scaling, or any window that is not maximised — the
page already opened in what it called "Week", so pressing Week changed nothing. Duration and layout
are separate controls now, and each one does exactly what it says.

**Today is marked in the List view now.** It never was — on a phone, where the List is what opens,
nothing on the page said which day was today. Now that you can always see which day is today, the
Today button doing nothing while you are looking at today is harmless: it is there for when you have
moved away.

**The three "Reset search" buttons in the partner portal** — on children, families and family
requests — are greyed out until you have actually searched for something. Those are greyed rather
than left live because pressing one with nothing to reset reloads the whole page for no change,
which the Today button does not.

**To reach a month in another year, use the month and year dropdowns** beside the view buttons,
rather than clicking Next twelve times. The year list covers the years your bank actually has
distributions in, and grows if you step past either end with Prev or Next. The dropdowns also follow
the calendar, so they always say what is on screen.

**A wide table has one scrollbar now, not two.** There used to be a second, fainter bar just above
the real one that seemed to appear and vanish as you scrolled — that was a custom scrollbar and the
browser's own, both switched on. The custom one does the work and the browser's is hidden.

**It is also quieter and easier to see.** The grey strip and its border are gone; what is left is a
thin track and a rounded handle. The handle is darker than the original one on purpose — that one
did not have enough contrast against its track to meet the accessibility standard for a control —
but it is lighter than the version that shipped briefly on 28 August, which overshot the standard
and read as heavy.

**The handle was also meant to be rounded from the start and never was**, because of a mistake in the
stylesheet. If you remember it as a hard-edged rectangle, that is why.

**While you are still scrolling down a long table, the bar floats at the bottom of the window** so
you can always reach it, and it sits on a pale band there so it does not lie directly on the row
behind it. Once you reach the end of the table it settles underneath and drops the band.

**Where it settles, the line that used to sit above the page controls is gone**, because the bar is
now that line. Two rules for one boundary is what made the bar look stuck to the pager. A table
narrow enough not to scroll has no bar, and keeps its line.

**The page controls sit evenly between the bar and the foot of the card** — 13px above, 12px below.
That spacing was reported wrong three times before it landed, in both directions, so if it looks off
to you it is worth saying: it is measured from the bar to the buttons, not from anything you can see
the edges of.

**Save and Cancel now sit below the card, not inside it.** On New item, New kit, New vendor and the
rest, the buttons used to sit inside the white card under a short grey line. The line is gone and
the buttons have moved just below the card. Nothing about saving has changed — the buttons do the
same thing in the same order, `Save` then `Cancel`.

The reason for the move, if you are curious: the buttons submit the whole form, and on longer forms
like New donation the form covers several cards, so the buttons never belonged to any one of them.
Those longer forms already worked this way; the shorter ones now match.

**Buttons that act on one card stay in that card.** *Add another item* on a donation, *View all
users* on the admin dashboard, and the page controls under a table are all still where they were —
they change what is in the card, so they belong to it. The rule is what pressing it affects: if it
would be the last thing you do on the page, it is at the bottom.

### Your organization page, and the gap under every heading

**The gap between a page's heading and the first white card was too big on fourteen pages**, and is
now the same everywhere: your organization page, Users, the admin lists, the annual survey and the
partner request pages all had roughly three lines of empty space under the title and now have one.
Nothing moved except the spacing.

**Your organization page has a Users list again, in a real table.** It was a plain unstyled grid
before — no shading on the header row, no line between rows, the *Invite user* button floated off to
the right of a strip of its own. It is the same table as everywhere else in the app now, and the
invite button sits at the foot of the card with the other footer buttons.

**Edit has moved from the "Organization info" card up to the page heading.** It always saved every
field on the page, not just the six in that card, and sitting in the card's header it looked like it
edited only those. It does exactly what it did before.

**On the partner profile pages, "Area served" is a proper table**, and two labels there are now in
sentence case — *% of clients in county*, and *No county specified* where a partner has no county
recorded. Same information, same rows.

**The yellow notice on the account request form is now a blue one**, in the same shape as every other
notice in the app, and the two sentences in it are two paragraphs rather than one paragraph split by
blank lines.

**A partner profile's sections are spaced consistently.** The gaps between *Agency information*,
*Media information*, *Contacts* and the rest were uneven, because they were made of blank lines
rather than spacing. *Primary Contact Person* is now a real sub-heading under *Contacts*, so a screen
reader can jump to it.

### The warning on New kit is where you can see it

**"The items in a kit are fixed once you save" now appears at the top of the page**, under the
heading, instead of below both cards where you had to scroll to find it — which was after you had
already chosen the contents it was warning you about.

It also says where to go afterwards: the name, value and partner visibility can still be edited from
**Items & inventory**, and the callout links there. It used to say "via the kit's item", which is
true internally but not something the screen explains.

### "Add other users at your bank" works now

**That link on your dashboard used to lead nowhere useful.** The form asked for a name, an email and
a password, and submitting it simply returned you to the dashboard without adding anybody.

It is an invitation now, the same one the *Invite user* button on your organization page sends: you
give a name and an email, they get an email, and they choose their own password. There is no
password box, because you do not set it for them.

### No more field flashing on load

**On New distribution, a Shipping cost box used to appear for a moment on every refresh** and then
vanish. It only applies when the delivery method is *Shipped*, but the page drew it first and
removed it a fraction of a second later. It now starts hidden and appears when you choose *Shipped*.

The reminder day fields on **Organization settings** did the same thing and no longer do.

### Tables on a phone stop flashing before they settle

**On a narrow window a table redraws itself as a list of cards.** It used to do that *after* the page
had already appeared, so you saw a squashed table for a moment and then everything jumped as it
rebuilt. It now arrives as cards, in one go.

Each field's label sits **beside** its value rather than above it, which is how a record's details
page already reads, and it is also what stops the cards resizing as the labels load.

### Two more things that used to jump about

**The three trend reports** — Donations, Purchases and Distributions under Reports — drew their
buttons and their table first and then dropped the chart in on top, shoving everything about 850px
down the page just as you started reading. The chart's space is held from the start now.

**The New donation form** used to show all four "where from" boxes — donation site, product drive,
participant, manufacturer — and then hide the three that do not apply, pulling the rest of the form
up by about 100px. It now shows only the one that matches the source you picked, from the first
moment.

### Filters that fit on a line no longer hide behind a button

**Ten of the eighteen filtered pages have only one or two filters**, and you used to have to open a
*Filters* panel to reach them — on Vendors and Donation sites, to reach a single tick box; on Item
list, to reach one category menu and an *include inactive* toggle. Those filters are simply on the
page now. Pages with three or more keep the button, and Donations still folds its nine away.

**And on Items & inventory the "Also include inactive items" tick box was sitting about 35px higher
than the menu next to it**, which made the row look crooked and the space under it look like a
mistake. It is on the same line now.

### For maintainers: when the working tree goes backwards

This repo's working tree has been **rolled back to the commit that was HEAD at the start of the
session, five times**, without `HEAD` ever moving. `git` itself is untouched, `/tmp` survives, and
every commit is still there — only the tracked files on disk revert. Nothing in the repo does it:
there are no other hooks, `postCreateCommand` runs no git, and the shape of the damage matches an
external `git checkout <commit> -- .`.

**It cannot be prevented from in here.** Git has no `pre-checkout` hook, and a process outside the
session writing to the disk is outside the session. What can be done is make it obvious, because
twice it arrived as a bug report about a fix that had already been made — a rolled-back file renders
exactly like a regression.

```bash
bin/workspace-check              # 0 clean, 1 uncommitted work, 2 a rollback
bin/workspace-check --identify   # name the commit it went back to (~30s)
bin/workspace-restore --yes      # snapshot the disk, put HEAD back, delete resurrected files
```

`bin/start` runs the check and shouts only on a rollback, so ordinary uncommitted work is silent.
`.githooks/post-checkout` records every path-limited checkout that leaves more than ten files
differing from HEAD, with the process tree that ran it, in `.git/workspace-resets.log` — which is
the evidence needed to stop it at the source. Point git at the hooks once per clone:

```bash
git config core.hooksPath .githooks
```

**Commit early. It is the only thing that protects work in progress.** The snapshot
`bin/workspace-restore` takes is of the disk *after* the rollback, so it holds the damage, not what
was lost — verified the hard way while building it, on three uncommitted files.

Two symptoms worth recognising:

- **A file a commit deleted is back on disk.** `git checkout .` will not remove it, so the app goes
  on rendering it. `bin/workspace-check` lists these separately, and tells them apart from your own
  new files by whether the path has any history.
- **The fix you just made is "not working".** Check the file on disk before reading the code.

### Manufacturer donations is a table now

**It used to be a list of names with a number in brackets** — and that number was *items*, not
donations, with nothing on the page saying so.

It is a table like the rest of the reports: the manufacturer, how many items they donated, their
**share** of the total as a small bar, and **when they last donated** — a date the page always had
and never showed. Biggest first, with a total at the foot.

If you have more manufacturers than fit, the page now tells you: *"The 10 largest of 14 manufacturers
who donated."* And **New donation** has moved up to the top of the page, where every other page's
main button is.

### Reports: consistent titles, and the activity graph has its figures written out

**Four report pages were titled in Title Case** — *Monthly Distributions*, *Activity Graph* and so
on — while the Reports page that links to them was not. They match now: *Monthly distributions*,
*Activity graph*.

**The Activity graph now has a small table under it** with the same three figures, so they can be
read, copied and printed without squinting at a bar.

### The monthly trend table fits on the screen again

**The by-item table no longer scrolls sideways on a normal desktop.** Three changes got it there:
the month headings are now `Sep 25` rather than `Sep 2025`, the cells are a little tighter, and the
trend column is narrower.

It fits at **1366px wide and above**. At 1280 it still scrolls a little — twelve months of figures
plus a name, a trend and a total is fifteen columns, and they do not fit in a smaller window. The
table scrolls inside its own box rather than pushing the page sideways.

### One control for what the trend report is about

**There is a single "Compare" control beside "Date range".** Open it, type a few letters, and tick
what you want — **your categories and your items are in the same list**, so you do not have to know
which one a name belongs to before you look for it.

What you tick is what the page is about: the chart draws a line for each, and the table narrows to
match. Tick nothing and you get everything.

**The control shows how many you have chosen; the names appear as chips on the line below it**,
after the word *Comparing:*. Remove one with the × beside it, or use **Clear comparison** to remove
them all — neither needs the control opened. Each chip shows its line's dash pattern, so you can
read the chart without matching colours.

**Up to four at a time.** Beyond four the lines stop being tellable apart, so the rest are greyed out
and the panel says *"4 of 4 chosen. Clear one to add another."*

**Your choices apply when you close the control**, so picking four things is one page load rather
than four.

**The figures are current.** These pages used to say they might be up to 24 hours behind; they are
recomputed every few minutes now, so what you recorded this morning is there.

### The monthly trend reports break down by category, and can compare periods

**The chart now shows your item categories as stacked bands** rather than one anonymous total, so
you can see what is driving a month. There is a **Category** filter beside the months to narrow to
one — including **Uncategorised**, for items you have not filed anywhere. If your bank does not use
categories, the chart looks exactly as it did.

**"Compare with the previous period"** sits on the chart itself. It draws the window before this one
as a dashed grey line behind your figures, adds a row of those figures to the table, and says the
change in words — *"Total 167,278, up 241% on the previous period."*

The previous period is **your window shifted back by its own length**: ask for six months and it
compares with the six before, not with the same six last year.

### You can change the window on the monthly trend reports

**The three trend reports were stuck on the last twelve months.** There is a **Months** control on
them now, with presets — last 6, 12 or 24 months, this year to date, last calendar year — and two
month boxes for anything else. The window is in the address bar, so you can bookmark or share one.

**Months, not days, on purpose.** These charts count by month, so a range like *12 March to 20
August* would give you two stub columns at the ends that look like a fall but are just a part-month.
You can only pick whole months, so that cannot happen.

**The current month is included, and labelled.** It says *"so far"* on the column and on the table
heading, and the card says *"…is still running"* — so you can see how the month is going without
mistaking a part-month for a bad one.

**Scheduled distributions are not counted.** If you have distributions dated in the future, the page
tells you how many line items they cover and links you to the distributions list. A trend is what
happened, not what is booked.

### The monthly trend reports draw something now

**Monthly Distributions, Donations and Purchases used to open with an empty chart.** A tall grey box,
a list of 47 item names down the side, and no bars — you had to press **Select all** before anything
appeared, and what appeared then was 47 items crammed into each month at about two pixels each, in
ten colours shared between them.

**The chart now shows one column per month: the total, with the figure printed on it.** It is
shorter, so the table of figures is visible without scrolling.

**And every row of that table has its own small trend line** covering the same twelve months, so you
can see at a glance which items are rising or falling without reading across fourteen columns. A
screen reader is told where each one peaks — *"Peaks at 3,042 in Aug 2026"*.

The **Select all** and **Deselect all** buttons are gone. They existed only because the chart started
empty.

### Reports: the item column has its padding back, and a hidden warning is visible

**On the three monthly trend reports the item name sat flush against the edge of the card** — no
padding on either side, unlike every other table in the app. Fixed for all three.

**Pagination has not been applied to the reports, and will not be.** Every report is one row per
item, so its length is set by how many items your bank has — dozens — not by how many transactions
you recorded. Reports are meant to be read, exported and printed whole, and a pager breaks all
three.

**On Itemized distributions and Itemized requests, "below the on-hand minimum" was invisible.** The
cell was meant to turn red and had been doing nothing at all since the design system landed. It now
shows the number in red *and* the words **Below minimum**, the same as the dashboard's low inventory
table.

### Delete asks in the app's own words again, not the browser's

**If Delete — on a product drive, a vendor, an item, anywhere — put up a grey browser box with your
server's hostname above the message, reload.** The app has its own confirmation dialog: it names the
action on the button (*Delete*, not *OK*) and reddens it when the action destroys something. A
working-tree rollback had removed the whole mechanism, so every confirmation in the app fell through
to the browser's for the length of that window.

There is now a check that presses **all 59 confirmations in the app** and fails if any of them is
the browser's:

```bash
pw bin/design/confirm-audit.js      # never accepts -- nothing gets deleted
bundle exec rspec spec/system/confirm_dialog_system_spec.rb
```

It also turned up something separate, on **Your organization**: four users with no name filled in
all had a row menu called *"More actions for Name Not Provided"*, which a screen reader user cannot
tell apart. Those menus are named by email address now where there is no name. The table still shows
"Name Not Provided" in the name column.

### The warning on New kit is above the form again

**If you saw "You will not be able to change the composition of the kit once it is saved" at the
*bottom* of `/kits/new`, reload.** That is the old wording and the old position; a working-tree
rollback briefly put it back. The warning belongs directly under the heading, before the form it
warns about — a warning that arrives after the decision is not a warning — and there is now a check
that fails if it ever drifts below the first card or below the fold.

### Import and Export had their arrows the wrong way round

**On any page with both — donation sites, vendors, partners, storage locations, participants —
Import wore an arrow pointing out of a tray and Export wore one pointing into it.** Both were
backwards. Import now shows an arrow going **into** a box and Export one coming **out** of it.

Two ways of thinking about direction had collided. *Upload* and *download* are measured from the
server: up to it, down to you. *Import* and *export* are measured from the app: in to it, out of it.
The buttons used the second vocabulary and the icons the first, so half the row read backwards
whichever way you took it. The **Download example CSV** button in the import dialog keeps its
download arrow, because that button really does download a file — and it is on the same page as an
export, which is why the two could not share.

Some smaller things went with it:

- **"Save" no longer carries a floppy-disk icon** on the twelve forms that had one. The other
  twenty-nine never did, and a floppy disk names a thing most people have never handled.
- **The partner group form's button says "Save"**, like every other form in the app. It said *Add
  partner group* and *Update partner group*.
- **On Requests, the row action called "Cancel" now says "Cancel request".** *Cancel* is the word
  this app uses on every form to mean "abandon what I was doing"; here it cancelled the request,
  which is not the same thing at all.
- **"Invite user" wore three different icons on three pages.** It is one now.

### For maintainers: the app's explanatory prose

`bin/design/copy-audit.rb` reads what the app *says*, not what it is built from. It now also checks
that a **hint ends in a full stop** — a hint is a sentence, and 21 of the app's 24 already did.

The prose worth reviewing together is the three kinds the design system has: **card subtitles,
page-header subtitles and filter hints**. Two rules came out of auditing them:

- **A subtitle answers the reader's question, not the writer's.** *"Narrowed to what you are
  comparing"* names what the code did; *"27 of 47 items"* says what is left. Prefer a figure.
- **One spelling per thing.** *Zip code* had four spellings across seven places.

### For maintainers: which icon means what

`design.md` now carries a lexicon — **"One glyph, one meaning"** — and the machine-readable copy of
it is `bin/design/icon-lexicon.json`, which both the audit and the spec read:

```bash
pw bin/design/icon-audit.js          # walks 124 pages as three roles
bundle exec rspec spec/system/button_icons_system_spec.rb
```

The audit fails on a glyph it does not find in the lexicon, so adding one to the app means adding it
to the table first. That is the point: *Invite user* reached three pages with three glyphs because
nothing said which was right.

### "Make a correction" is now "Edit", and Delete has moved

**On a donation, purchase, distribution or product drive, the button that opens the record for
changes now says "Edit".** It said *Make a correction*, which is the wording the old app used — and
it implied the record was wrong, when you may just be adding a tag or fixing a date. Everywhere else
in the app already said Edit.

**Delete has moved into the ⋮ menu** beside it, with Edit. It used to sit at the far right of the
page header, which is where a page's main action goes — so the most destructive thing on the page
was in the most prominent slot. On donations, purchases and distributions these two also used to be
at the very *bottom* of the page; they are with the other actions at the top now.

Where a record cannot be changed because some of its items are inactive, the explanation now says
"cannot be edited or deleted", matching the buttons.

### Admin: an organization's intake location was the wrong one

**On the admin page for an organization, "Default intake storage location" showed an arbitrary
storage location** rather than the one actually set — whichever the database returned first. If an
organization had more than one storage location, the odds of it being right were roughly one in
however many it had. Fixed.

### Pick ups & deliveries: a day with a pick-up on it no longer errors

**`/distributions/pickup_day` raised an error whenever there was actually a pick-up scheduled for
the day you were looking at.** An empty day loaded fine, which is why it went unnoticed. Fixed, and
there is now a check that compiles every page template so a typo like it cannot reach a page again.

### For maintainers: citing another design system

`design.md` argues many decisions partly from what Carbon, GOV.UK, Linear and others do. There is now
a written standard for that — **"Citing another system"** in `design.md` — and a check behind it:

```bash
python3 bin/design/citation-audit.py --check
```

It fails when the number of claims asserting agreement across four or more systems, with no
component named, goes up. Name the artefact where one is published, say **observed** where it is
not, and keep numbers attributed to whoever measured them.

### Six tables now reach the edge of their card

**On Partner announcements the table was inset about 20px from the card on both sides**, which you
could see whenever a row highlighted on hover and in the rule under the column headings, which stopped
short of the edge. The same was true on five admin screens: Announcements, Base items, Organizations,
Partners and Users. All six now meet the card's edges like every other table, sit in a scrollable
region, and say what they list for a screen reader.

**New announcement** has also moved out of the table and up into the page header on both announcement
screens, which is where a page's main action goes everywhere else.

### Tabs stay put, and the sidebar stops collapsing

**Switching between Partners and Groups used to shift the whole card up or down by about 50px**,
because the filter row sat above it and Groups has no filters. The filters now sit *inside* the card,
just under the tabs, so **the tabs are in the same place on every tab** and only the table below them
changes. The same was true across the item catalogue, where Item categories is the one tab without
filters.

Groups and Item categories still have no filter row, deliberately — they are short lists, and a
filter over three rows is clutter. If either grows, one can be added without anything moving.

**And opening Groups no longer collapses the sidebar.** The rail was only treating the first tab as
"you are here", so landing on Groups or Item categories shut the whole section. Now the section stays
open with its entry highlighted, wherever you are inside it.

### Requests: pick several, print their picklists in one go

**Show product totals** has moved up onto the filter row, beside the Filters button — it always
reported on "every request matching the current filters", so that is where it belongs, and the table
now starts about 50px higher than it did.


**On the Requests page every row now has a checkbox.** Tick a few — or tick the box in the header to
take the whole page — and a dark bar appears at the bottom of the window saying how many you have
chosen, with **Print picklists**. That gives you one PDF for the lot, instead of opening each row's
menu in turn.

The bar floats over the page, so **the filters and Show product totals stay where they are and keep
working**, nothing moves when it appears, and it stays with you as you scroll down the list. Press
**Cancel**, or Escape, to clear the selection.

Three things that work the way you would expect from email or a file browser:

- **Shift-click** a second checkbox to take everything between it and the last one you clicked.
- The header checkbox shows a **dash** rather than a tick when only some rows are selected.
- **Escape** clears the selection, or use *Cancel* on the bar.

Only Requests has this so far, because it is the only list where doing something to several rows at
once is a real operation. Most row actions — View, Edit, Deactivate — happen to one record.

### A row's actions no longer run away to the right

**On a wide table you had to scroll sideways to reach a row's actions, and after you used one the
page reloaded and threw you back to the left.** On Distributions at a common laptop width that was
402px of dragging per action -- about 6,000px to work through one page of fifteen rows. At 1024 it
was 818px each time.

**The Actions column now stays against the right edge**, the same way the first column already stays
against the left. Whatever you scroll to, the actions are where you left them. A thin line and a soft
shadow appear on its left while there are still columns hidden behind it, and go when there are not.
On a table that already fits, nothing has changed at all.

To make room for a column that is always on screen, **the buttons in it are now icons**. Hover one --
or reach it with the Tab key -- and it tells you what it is. It says the same word it always did; a
labelled pair took 168-273px and the icons take 94px.

If you are on a phone or a narrow window, the table becomes a list of cards as before, and there
**the actions get their words back**, because a tooltip is no use without a mouse.

One more change on **Kits**: its two buttons are now behind the same ⋮ menu the other tables use,
because which ones you get depends on whether the kit is active. And if a kit cannot be deactivated
because a storage location still holds it, the action is still offered -- clicking it now tells you
why and what to do about it, instead of being greyed out with no explanation.

### Fields that only apply to one answer now sit under that answer

**On New distribution, Shipping cost used to sit off to the right of the delivery method options**,
in a box half again as wide as every other field on the card, and *above* the *Shipped* option that
brings it up. It now appears directly underneath *Shipped*, indented, with a short grey rule down
its left side — the rule is there to say the field belongs to that one option and not to the other
two.

The same treatment is now on every question in the app that only appears once you have answered
something else:

| Where | What appears, and when |
| --- | --- |
| New / edit distribution | **Shipping cost**, when the delivery method is *Shipped* |
| Organization settings, Partner group | **Reminder day of month** or **day of the week**, under whichever you pick |
| New / edit partner group | The whole **reminder schedule**, when you tick *Yes, send reminders* |
| New / edit partner | A note about **where reminder settings come from**, when you tick the reminders box |
| Partner profile, Agency information | **Other agency type**, when the agency type is *Other* |
| Admin, New user | **Resource**, for every role type except *Super admin* |

Two of those never worked before. The note on the partner form **could not appear at all** — the
page had a wiring fault that stopped it, so ticking the box did nothing. *Other agency type* was
drawn and then removed on every load, so it flickered.

### A purchase can start a distribution, and can be printed

**Open any purchase and the header now has two buttons**, the same two a donation has always had.

*Start a distribution* opens a new distribution with that purchase's items, quantities and storage
location already filled in — so buying stock and sending it out is one step rather than re-typing
the list.

*Print* gives you a PDF of the purchase, laid out like the donation receipt: your logo and address,
who you bought from, the amount spent, the storage location, your comments and the items. If your
organization has *Hide value columns on receipts* switched on, the values are left out here too.

### You can scan a barcode when adding one

**If the camera cannot start, the app now tells you why** instead of looking like a broken button.
The commonest reason in day-to-day use is the address: browsers only allow camera access on
`https` or on `localhost`, so if you reach the app through a forwarded port or a tunnel on a plain
`http://` address, the camera is not offered at all. It says so, and you can still type the number.

**The scan button now looks and behaves exactly like the one on the inventory audit** — joined to
the right-hand end of the box rather than floating inside it, and the same size. It used to sit
slightly low and slightly outside the field, on the barcode pages and in the barcode pop-up on
donations and purchases.

**New barcode** and **Edit barcode** now have the scan icon at the right-hand end of the Barcode
box, the same one you already use on donations and purchases. Click it and the camera opens below
the field; hold the barcode up and it fills itself in. Click the icon again to close the camera.

If your browser will not give the page a camera — which is normal on an insecure connection — it
says so under the field instead of doing nothing, and you can still type the number.

### The separate Users page is gone

**Your organization page is the one place users are listed now.** There used to be a second page at
`/users` showing just names and email addresses; the table on your organization page shows the same
people with their role, last sign-in, status, whether they need re-inviting, and the actions you can
take. Nothing has been lost — it was the smaller of two lists of the same thing, and after the
account-menu tidy-up nothing linked to it.

*Add a user* still works and now returns you to the organization page.

### The account menu is shorter

**"Organization" is no longer in the avatar menu.** It is still pinned to the bottom of the left
sidebar, where it always was — it was simply in both places, linking to the same page for the same
people. The account menu is for you: your account settings, any roles you can switch to, and
signing out.

**"Co-workers" has gone from that menu too.** It never actually appeared for bank administrators —
it required a partner role that a bank admin does not have — and the page it pointed at showed only
names and email addresses. Your organization page already lists the same people with their role,
last sign-in, status and the actions you can take.

### Confirmations look like the app now

**"Are you sure?" is the app's own dialog**, not the grey browser box that used to say
*localhost:3000 says* above the question. The button says what it will do — *Delete*, *Deactivate* —
and turns red when the action destroys something.

**An action that cannot be done is no longer greyed out.** *Deactivate* on Items, on Storage
locations, and *Delete* on a partner group are all clickable, and if the action cannot be completed
the app says why and what to do about it:

> Adult Briefs still has stock in a storage location, or belongs to a kit. Move or distribute the
> remaining stock and remove it from any kits, then deactivate it.

**It does not ask you to confirm first, either.** Clicking *Deactivate* on something that cannot be
deactivated takes you straight to the explanation — it does not ask "are you sure?" about something
that was never going to happen. Where the action *can* be done, the confirmation still appears.

The one exception is your own row on the organization's Users table, which stays greyed out — there
is nothing to attempt there, so there is nothing to explain afterwards.

### Table actions look the same on every table now

**The items in the "..." menu line up now.** An action that submits a form — *Deactivate*,
*Delete*, *Reactivate* — was rendered half-width and pushed to the right edge of the menu, while
*Edit* beside it ran the full width. A layout bug, not a choice, and it affected every row menu.

**Tables have a visible "Actions" heading** over the last column. It used to be there only for
screen readers, which was fine when the column held buttons labelled *Edit* and *Delete* — now that
most of them hold a single "..." it is worth naming.

**An action you cannot use tells you why, on screen.** Under *Deactivate* on Items you will now read
"Still in inventory or used by a kit". That sentence existed before but only screen readers got it;
everyone else saw a greyed-out word with no explanation.

**Where a row had three or more things you could do, they moved into the "..." menu** at the end of
the row — barcode items, donation sites and storage locations. Nothing was removed; the actions are
one click further in, and the tables got a lot of width back.

**Where the available actions changed from row to row, they also moved into the menu.** On Partner
agencies the buttons used to change label, change width, and sometimes disappear as you read down —
because which action applies depends on the partner's status. Same on the Users table on your
organization page, where it depends on the person's role. Both now show one "..." on every row.

**An action you cannot use is now listed and greyed out with the reason**, instead of simply not
being there. So "why can I not delete this group?" has an answer on screen.

**Where a table has one or two actions that are always available, they stay as buttons** — nothing
moved behind a menu unnecessarily.

**The View button is gone from a few tables** where the row's first column was already a link to the
same page.

### Every page tells you where you are, and gets you back

**There is a breadcrumb above every page title now** — *Reports › Itemized donations*, *Items ›
Edit item*. It replaces the "Back to …" link that used to sit there: the first part of the trail
goes to the same place, and the trail also says where you are, which the old link did not.

**The reports had no way back at all.** None of the eleven reports is in the left menu — you reach
them from the Reports page, and until now nothing on a report linked back to it, so the only way out
was your browser's back button. That is fixed for all of them, including the trend charts and the
by-county report.

Also fixed the same way: **History**, **Help**, and the **Users** page you reach from *Co-workers*
in the account menu.

**The tables on the itemized reports scroll properly now.** They looked like the app's other tables
but were missing the part that makes them work — you can focus one and use the arrow keys, it shows
a shadow at the edge when there is more to see, and a wide one scrolls instead of overflowing.

### Custom request units is a proper tag box

**It used to look like a dropdown that would not open.** Clicking it did nothing, because it was a
list control with its list switched off — the only way to add a unit was to type and press comma,
which the screen never said.

**Now: type a unit and press Enter.** Comma and Tab still work if that is your habit. Each unit is a
chip with its own remove button, backspace on an empty box removes the last one, and typing a unit
that is already there — in any capitalisation — is refused rather than silently added twice. The
line under the label says all of this.

This field only appears when the **packs** feature flag is on.

### Organization settings looks different

**The text editor's buttons had no icons at all** for a few hours between two commits -- fourteen
empty squares above each email box. Fixed; they are the same icons as the rest of the app.

**The address is labelled again.** Street, City, State and Zip each have a visible label, like every
other address in the app. They used to show their name only as grey text inside the box, which
vanished as soon as you typed. State and Zip now share a line instead of each running the full width
of the card.

**The Yes/No options are a little tighter than they were yesterday.** They went from too close
together to too far apart in one step; they are now 8px apart, which is what Carbon, Ant Design,
Atlassian and Bootstrap all use for the same control.

**`%{partner_name}` and the other placeholders in the email hints are now grey chips**, so they read
as something you can type rather than as a bug.

**There is more room at the foot of every page**, between the last thing on it and the grey footer
bar.

**The sections are banded now.** Each heading -- *Basic information*, *Storage*, *Emails* and the
rest -- sits on a pale strip running the full width of the card, the same way the sections on your
organization page do. Before, each one had a grey line that started halfway across, level with the
end of the heading text. That was a browser quirk rather than a design, and it is gone.

**Yes/No options have room to breathe.** They were stacked flush against each other, 24px each with
nothing between. They are 32px now with 8px between, which makes them easier to hit and much easier
to hit correctly on a phone.

**"Deadline day" is readable again.** The box under *Deadline day in reminder email* was too narrow
for its own placeholder, so the words were cut off mid-way. Same for the reminder day box. Both are
wide enough now. The reminder options above them were also rebuilt: they are a proper labelled group
instead of a stack of loose labels and line breaks.

**The buttons above the email text boxes match the rest of the app.** The bold, italic, link, list
and other controls were the text editor's own styling -- smaller, squarer, with a pale blue
highlight this app uses nowhere else, and icons from a different icon set. They are now the same
size, shape and icons as every other button here, and the highlight is the app's indigo. On a phone
the row of them scrolls sideways rather than squeezing each button too small to press.

**The gap under the heading is smaller**, on this page and thirty others.

### Some buttons are shorter

**"Invite user to this organization" is now "Invite user."** It sits at the foot of a card headed
*Users*, on a page whose title is your organization's name, so three of its five words were saying
something the screen already said twice. It does exactly the same thing, and the window it opens
still says which organization you are inviting someone to. The same button on the super admin's user
list said "Invite a new user"; both say "Invite user" now.

**Four buttons lost their Capital Letters**: *New announcement*, *New donation*, and *New
organization* — which was "Add New Organization", and is now shaped like every other "New something"
button in the app.

### If you are a partner: your agency's status has moved

**Your status pill is gone from the top-right of your Dashboard and Distributions pages.** It sat
where page buttons go, which made it look like a button you could not press.

**On your Profile it is still there**, now beside your agency's name at the top — the same place your
bank sees it on their copy of your record.

**On your Dashboard you will now see a short message instead, and only when something needs saying.**
If your agency is waiting for approval, needs recertifying, or has been deactivated, the message says
so *and* says what it means — that you cannot make requests yet. That was the real gap: the request
options disappeared from the dashboard for anyone not approved, and the only clue was one word in the
corner. If your agency is approved, there is no message and no pill, because there is nothing to say.

### Super admins: the dashboard's "new users" count was wrong

**"Recently added users" reported the number of rows it could show, not the number of people who
signed up.** The card lists at most 20, and the badge counted the list — so it said *20 new users*
whether 20 or 200 had joined that week. It now reads **"The 20 most recent of 23 users added in the
last week"**, and plain **"Added in the last week"** when the list is the whole of it.

**The badges are gone from both cards' top-right**, where page actions live. The line under the card
title carries it instead, which is where the third card on that page already explained itself. The
period is new information: before, "in the last week" appeared *only* when there was nothing to show.

### History: the funnel on a row says what it does, and you can undo it

On **History**, each row has a funnel button in the *Actions* column at the right. It narrows the
page to everything that has happened to that one record — the donation, the adjustment, whichever
it is. Hover it and a label says so.

**It used to be a glyph in the middle of the row with no label**, and pressing it left you with no
way back except your browser's back button: nothing on the page said you had narrowed anything. Now
it behaves like every other filter — the Filters button shows a count, a chip appears saying
*Refers to: Adjustment 12*, and either the chip's ✕ or *Clear all* puts the full list back.

**The snapshot row's items were under the wrong heading.** History tints one row for each inventory
snapshot, and its list of locations and quantities was printed under *From location*, with *Items*
left empty. It is under *Items* now, and its date is written the same way as every other row's.

### Filtering a wide table no longer leaves a second scroll bar behind

On a table wide enough to scroll sideways, applying a filter used to leave the old scroll bar on
screen — so you would end up with two, one of which did nothing at all. Each filter you applied
added another. There is one again, and it belongs to the table you are looking at.

### Addresses are four boxes now, not one

Vendors, donation sites, storage locations and product drive participants used to have a single
**Address** box you typed everything into. They now ask for **Street address**, **City**, **State**
and **ZIP code** separately &mdash; the same four your organization's settings page has always used.

**Your existing addresses were split for you.** Where an address was written the usual way
&mdash; <i>1500 Remount Road, Front Royal, VA 22630</i> &mdash; all four boxes are filled in. Where
it was not, the whole thing was left in **Street address** and the other boxes are empty for you to
finish. <b>Nothing was deleted or changed</b>: every address still reads exactly as it did before.

**Nothing changed for you in this step, and that is the point.** The old single-address field was
removed from the database once every record had been split into four. Your addresses read exactly as
they did before, on every page and in every export and PDF.

**Your import files still work.** The CSV templates are unchanged &mdash; still one `address`
column &mdash; so a copy you downloaded last year imports exactly as it always did. The app splits
the address as it reads each row.

### Addresses: your browser can fill them in now

Every box that asks for an address &mdash; on your organization's settings, a partner's profile, a
vendor, a donation site, a storage location, a product drive participant &mdash; now tells your
browser what it is. If you have an address saved in Chrome, Safari or Firefox, it will offer to fill
the whole thing in, which it could not do before on any screen in this app.

**Partner profiles: state is a menu now.** It was a box you typed into, so "CA", "Calif." and
"California" could all end up in the same column. It is the same list of states the organization
settings page has always used.

**ZIP codes stopped losing their first digit.** The *program / delivery address* ZIP on a partner
profile was stored as a number, and a number cannot begin with a zero &mdash; so a partner in Boston
(02108) had it saved as 2108, and a ZIP+4 like 39428-1234 could not be entered at all. It is stored
as text now, and any ZIP that had already lost its leading zero has had it put back.

**One spelling.** "Zip code", "Zipcode" and "Zip Code" all appeared on different screens; it is
**ZIP code** everywhere. On the partner profile view, the two program address lines were both
labelled "Program Address" &mdash; they now say which line is which.

### Keyboard users: nothing hides under the scroll bar any more

If you move through a page with the Tab key, the thing you land on is now always visible. On pages
with a wide table there is a scroll bar fixed along the bottom of the window, and tabbing to a link
in the last row used to put it **exactly underneath that bar** &mdash; you could not see what you had
selected. The same happened at the right-hand edge, where the Actions column stays put. Both leave
room now.

### Some pages had no name of their own

Every page shows a name in your browser tab and in your history. Fourteen did not have one: the five
report pages, the account-request screens and a couple of others showed only your organization's
name, so a row of open tabs was indistinguishable. They are named now &mdash; "Itemized donations -
Reports - Pawnee Diaper Bank" and so on. This matters most if you use a screen reader, which reads
the page name on arrival.

### More pages have a name of their own

Following on from the last change: ten more pages were showing someone else's name in your browser
tab. A partner's **Help** page was titled after the diaper bank rather than the agency; opening one
family showed "Families", the same as the list; and several admin forms showed their index's title,
so *New broadcast announcement* and the list of them were indistinguishable in a row of tabs. All
named now.

### Brought over from the main branch

**Exporting distributions no longer freezes the page.** Press *Export* and you get a message saying
the download has started; the file arrives in the background. A large export used to leave the
browser sitting on a blank request.

**The donations table leads with the date**, which is also the column that stays put when you scroll
sideways. Source moved one place right.

**A donation's page names the drive participant**, under the donation site, when it came from a
product drive. Donations from anywhere else show a dash there, like every other blank field.

**Product drive participants can be filtered** by business name and contact name, from the Filters
button above the list.

**A product drive's page can export its participants**, from the button in the page header, once the
drive has donations.

**A finalized audit can no longer be edited**, and neither can a rejected or closed account request.

**Two CSV exports were returning the wrong file.** *Export* on product drive participants and on
vendors served the blank import template instead of your data — a sample file was sitting at the
same address as the export. Both now export what you asked for.

**The organization page has been rebuilt.** Same information, in the same order, grouped under
headings you can scan — Basic information, Storage, Partner approval process, and so on — with the
fields in two columns instead of one long list. The heavy black lines between sections are gone, and
empty fields show a dash rather than the words "Not defined".

**Scanning a barcode now tells you it worked.** The confirmation was being drawn at the very bottom
of the page with no styling, so in practice nobody saw it — the scan succeeded silently. It appears
as a normal message bar at the top of the page now, the same one you see after saving anything else.

**Short fields sit side by side on the longer forms now.** New item puts value beside quantity and
the two on-hand thresholds beside each other; product drives puts start date beside end date. The
forms are wider and shorter, and no box is stretched to a width its contents never needed. Forms with
nothing worth pairing — new kit has three fields — are unchanged.

**Forms stay left-aligned**, lined up with the page title, because that is where every other page in
the app puts its heading. Centring them would slide the title sideways as you moved between a list
and its form.

**Zipcodes are shown as five digits, in boxes, lowest to highest.** They used to be a run of numbers
separated by spaces, some with a `-1234` suffix and some without, which was hard to read and hard to
tell apart. The suffix identifies a city block rather than an area, so it is gone.

**That may change a partner's zipcode count**, and the new number is the right one: two families at
`45612-123` and `45612-126` live in the same zipcode and used to be counted as two.

**A partner's page now tells you where they serve, in a sentence.** The Service area card opens
with something like "They serve 4 counties. Their families live in 13 zipcodes" — then lists the
counties with the share of clients in each, and the zipcodes themselves. Comparing the two is the
useful part: an agency that says it covers two counties whose families come from thirteen zipcodes
is worth a conversation.

**A partner's page now says where they serve, in one place.** The counties they told you they cover
and the zipcodes their families actually live in used to be at opposite ends of the page — the
counties buried in the profile block, the zipcode count as a figure at the top. They sit side by
side in a **Service area** card now, because comparing them is the useful part: an agency that says
it covers two counties whose families come from thirteen zipcodes is worth a conversation.

**The status badge moved onto the partner's name.** It used to sit in the row of buttons, where it
looked like a button that had stopped working.

**Edit details and Manage users are in the "Partner details" heading** rather than stacked at the
bottom of the card.

**To search a date range** — "everything between March and August" — use the **Distributions** page
rather than the calendar: a calendar shows one month or one week at a time, and the list page has a
date range filter. The calendar's subtitle links straight to it.

**To try the calendar with something on it**, run `bin/rails db:seed:calendar`. The ordinary seeds
scatter twenty distributions over a couple of years, which leaves that page thin exactly where you
want to look at it: the month you land on is sparse, the next one is often empty, no day holds
enough to overflow, and nothing falls on today. The task fills those in — including a six-event day
so the "+N more" link appears, and four completed ones last month so the data is not all
"scheduled". Everything it makes is commented **Calendar test data**. Remove it again with
`bin/rails db:seed:calendar:clear`, which returns the stock to inventory —
`Distribution.destroy_all` does **not**, because nothing on the model publishes the compensating
event. `ORG="Second City Essentials Bank"` picks a different bank.

**The pick ups and deliveries calendar looks like the rest of the app now**, and on a phone it
shows a list of the week rather than a month grid you cannot read. That list view had been asked for
in the code all along and never worked — the option was spelled for an older version of the calendar
library, so it was quietly ignored.

**You can import a CSV at any time now, not only into an empty list.** On vendors, donation sites,
storage locations and product drive participants, the Import button used to disappear as soon as
there was a single row — it swapped places with Export. Both are there now, on all five pages that
take a CSV.

**The app says "you", not "my".** "Edit my profile" is **Edit profile**, "My account" is **Account**,
and the partner dashboard's "Our impact" is **Your impact**. Where a possessive told you nothing — you
have exactly one profile — it is simply gone. And **"Need help?" is now "Help"** on both the page and
the link, which is what the bank side always called it.

**The line under each page title tells you what to do, not what the word means.** It used to gloss
the heading — "Requests / Essentials requested by partner agencies" — which told you nothing you did
not have from the title. It now points at the job: "Review what partners have asked for. Fulfill a
request to turn it into a distribution." Where a term is genuinely ours rather than English — kit,
product drive, inventory audit — the line still explains it, and then says what to do with it.

**Getting requests out of the app is one button now.** The requests page used to carry four buttons
across the top; the CSV export and the unfulfilled picklists PDF are both behind a single **Export**
menu, and the totals summary moved down onto the table it summarises, where it is called **Show
product totals**. That panel now ends with a **Total** row — it used to list every item's quantity
and never add them up.

**On a narrow screen a table becomes a list of cards.** Below about 640px of card width — a phone,
a split window, a browser zoomed a long way in — the columns are dropped and each row becomes a card
with every value labelled: one column of them on a phone, two when there is a little more room. The
name that identifies the row is the card's heading and its action sits beside it. Nothing is hidden,
and the page gets much longer: it is a swap of scrolling down for scrolling sideways, because before
this you could see about a fifth of a table on a phone. Widen the window past that and the table
comes back.

Every table with anything in it carries a line along the bottom of its card saying **Showing
31–45 of 272 requests** — the rows in front of you, and how many your filters matched
altogether. That total is the answer to "did that filter do anything?", so it is worth a glance
after you change one. A table with nothing in it says so in the middle of the card instead.

Beside that line are the page controls. **Prev** and **Next** are always there, greyed out when
there is nowhere to go, so they stay in the same place instead of appearing and disappearing
under your cursor. **`« First`** and **`Last »`** show up once there is more than one page — on
the audit and event lists the oldest record is often the one you want, and `Last »` is the way
to it.

How many rows fit on a page depends on how tall the rows are, not on a setting: lists of short
entries show fifty at a time, lists whose rows carry several lines each show fifteen. There is
nothing to configure, and no page is more than about three screens long.

The whole filter lives in the address bar, so a filtered view can be bookmarked or sent to
someone and it will show them the same thing.

The same is true of tabs. **Items & inventory** is five of them — the item list, item
categories, items by quantity and location, item inventory, and kits — and each one is its own
address. Bookmark the view you check every morning, send someone a link to it, and use the back
button to get out of it. The button at the top right follows the tab you are on: it says *New
item* on the item list and *New item category* on the categories tab, so the thing you came to
create is always in the same corner of the screen.

## If you are a partner agency

You have your own portal. You see your own agency's data and nothing else.

1. **Complete your profile.** Your bank chooses which sections it needs, so this varies. It is
   long, and it saves section by section: **Save progress** keeps your work without claiming you
   are finished; **Save and review** moves you on.
2. **Submit for approval.** The bank reviews what you sent and approves you.
3. **Make requests.** Depending on what your bank has turned on, you request by:
   - **Quantity** — "200 size 2 nappies"
   - **Individuals** — how many people need each product
   - **Children** — against the specific families and children you have recorded
4. **Follow your distributions.** What the bank has sent, and when.

Periodically you will be asked to **recertify** — confirm your details are still current. Your
status changes to *recertification required* until you do.

## Things that surprise people

- **Quantities are worked out, not stored.** Every movement is recorded and the total is derived
  from the history. So when a number looks wrong, the records explaining it exist — nothing has
  been silently overwritten.
- **Deactivating is not deleting.** Deactivated partners, items and storage locations keep their
  history, which is why last year's totals do not change when you tidy up this year's list.
- **Items belong to your bank.** Your "Size 1 Nappies" is yours to name and manage; it is mapped
  behind the scenes to a shared catalogue entry so that reporting across banks still works.
- **Your bank's name is on every page.** People work with more than one bank, and a screen that
  does not say which one you are in is a screen you can act on by mistake.

## Getting help

- The user guide: https://rubyforgood.github.io/human-essentials/
- In the app: **Need help?** in the top bar
- Something broken, or an idea: https://github.com/rubyforgood/human-essentials/issues
