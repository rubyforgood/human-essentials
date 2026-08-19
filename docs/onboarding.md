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

If system specs fail with `Failed to resolve module specifier`, `public/assets` is stale:
`bin/rails assets:clobber assets:precompile`.

## The design system

[design.md](../design.md) is normative. In short: Tailwind v4, Figtree, indigo on slate,
sentence case, components as partials in `app/views/shared/essentials/` and helpers in
`EssentialsUiHelper`. Build a page from the partials rather than from utility strings, give the
page exactly one `<h1>`, name every control, and never let colour be the only signal.

```bash
ruby bin/design/status.rb   # which controllers are on a design system layout
pw bin/design/sweep.js      # 56 pages audited in a real browser
```

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

### Picking a date range

Every page that filters by date uses the same control: a menu of ranges — *Today*, *Last 7
days*, *Last 30 days*, *This month*, *This year*, *All time* and so on — with **Custom** at the
bottom. Choosing Custom reveals **From** and **To** boxes that open your device's own date
picker. Set the range, then press **Filter**.

A page you have not filtered opens on *Default (recent and upcoming)*, which runs from two
months back to one month ahead — far enough forward to include distributions that are scheduled
but have not happened yet.

The whole filter lives in the address bar, so a filtered view can be bookmarked or sent to
someone and it will show them the same thing.

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
