# Onboarding

For anyone new to Human Essentials — using it, maintaining it, or contributing a first patch.

If you only want to build a screen, [design.md](../design.md) has a playbook. If you are
looking at markup that predates the design system, [migration-map.md](migration-map.md) says
what replaced it.

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

The associations that matter, read off the models rather than from memory.

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

## Getting help

- `docs/` for the rest of the developer documentation
- Ruby for Good Slack, `#human-essentials`
- The user guide: https://rubyforgood.github.io/human-essentials/
