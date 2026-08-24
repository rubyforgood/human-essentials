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
bin/setup     # gems, database, seeds. First time only.
bin/start     # web on :3000, job worker, Tailwind watcher
```

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

`dead-code.rb` is the mirror of `dead-routes.rb` and reports 118 findings today — six controllers
no route reaches, 24 helper methods nothing calls, 81 files in `public/` nothing links to. They
are documented rather than deleted; read [design-decisions.md](design-decisions.md) before acting
on any of them, and read the exemptions at the top of the script before adding a check. Every one
of them is a false positive that was believed once.

**Stop the dev server before running the full suite.** The box has 8GB; `bin/start` is five Puma
processes, a Delayed Job worker and a Tailwind watcher, and the system specs add a Chromium per
example. Running both put available memory under 600MB and the suite reported six failures, then
a hundred, in files that pass on their own — timeouts reported as assertion failures. With the
server stopped the same commit is 2,962 examples, 0 failures. If a system spec fails in a file
you have not touched, check `free -m` before you check the diff.

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
