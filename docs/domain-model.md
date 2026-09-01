# Domain model

The relationships that matter, read off the models rather than described from memory. If you
are new, read [onboarding.md](onboarding.md) first — this is the reference you come back to.

## The shape of the business

A **bank** (an `Organization`) takes goods in, holds them, and sends them out to **partner
agencies** who serve families.

```
   IN                          HELD                        OUT
   ──                          ────                        ───
   Donation ────┐                                    ┌──── Request      partner asks
   Purchase ────┼──►  StorageLocation ───────────────┼──► Distribution  bank sends
   ProductDrive ┘      (inventory, derived)          └──── Transfer     between locations
                              ▲  │
                              │  └──────────────────────►  Adjustment   manual correction
                              └─────────────────────────   Audit        count the shelves
```

Every one of those movements writes an `Event`. Nothing decrements a column.

## Organization is the tenant boundary

22 models `belong_to :organization`. A user works inside exactly one bank at a time, and the
current organization comes from their role rather than from a parameter — so a missing scope is
a data leak between banks, not just a wrong list.

```
Organization
├── users                 through roles
├── partners ─────────────── partner_groups ──── item_categories
├── storage_locations ────── inventory_items
├── items ────────────────── item_categories, base_item, barcode_items, request_units
├── kits ─────────────────── (a Kit *is* an Item — STI)
├── donations ────────────── donation_site, product_drive, product_drive_participant, manufacturer
├── purchases ────────────── vendor
├── distributions ────────── partner, storage_location, request
├── transfers ────────────── from / to storage_location
├── adjustments, audits ──── storage_location, user
├── requests ─────────────── partner, partner_user, distribution
├── product_drives ───────── product_drive_participants
├── vendors, manufacturers, donation_sites
├── item_categories, barcode_items, tags
└── annual_reports, broadcast_announcements
```

## Items: three layers, easily confused

| Model | Scope | What it is |
| --- | --- | --- |
| `BaseItem` | global | The catalogue entry every bank shares — "Diapers, size 1". Maintained by super admins. |
| `Item` | one organization | That bank's version: its own name, value, category, visibility to partners. Tied to its base item by `partner_key`. |
| `Kit` | one organization | A bundle distributed as one unit. **`Kit < Item`, single-table inheritance on `items.type`** — a kit *is* an item rather than owning one. |

**`Kit` was two classes until August 2026**, a `Kit` record owning a `KitItem`, and the rename is
the thing to know when reading anything older. `KitItem` no longer exists; verified against the
running app, `Kit.superclass` is `Item` and `Kit.table_name` is `items`. **The old schema is still
there and is now vestigial**: the `kits` table and `items.kit_id` both remain, deliberately, so the
two data migrations that moved the rows are reversible. Nothing reads them.

So `@kit.kit_item.line_items` is now `@kit.line_items`, `item.kit_id` is `item.is_a?(Kit)`, and a
kit form builds its line items on the kit's own form builder rather than opening a `fields_for` on
a nested record.

`ItemCategory` groups a bank's items, and a `PartnerGroup` uses those categories to decide what
its partners may request. So *what a partner can ask for* is:

```
Partner → PartnerGroup → ItemCategory → Item      (Partner#requestable_items)
```

A partner with no group can request everything; that is why the UI says "All items
requestable" rather than listing them.

## LineItem is polymorphic, and that is the core join

One join table carries the contents of every kind of movement. `LineItem` `belongs_to
:itemizable, polymorphic: true`, and these nine models carry them:

```
Adjustment   Audit   ConcreteItem   Distribution   Donation
Item         Kit     Purchase       Transfer
```

Practical consequence: a query that walks `line_items` must say which itemizable it means, and
a change to `LineItem` touches every movement in the app.

## Inventory is a replayed ledger

There is no quantity column to read.

```
Event (STI, JSONB payload, belongs_to :eventable polymorphic)
├── DonationEvent            DonationDestroyEvent
├── PurchaseEvent            PurchaseDestroyEvent
├── DistributionEvent        DistributionDestroyEvent
├── TransferEvent            TransferDestroyEvent
├── AdjustmentEvent
├── AuditEvent
├── KitAllocateEvent         KitDeallocateEvent
├── UpdateExistingEvent
└── SnapshotEvent            ← replay starts here
```

To read inventory:

```ruby
InventoryAggregate.inventory_for(organization_id)
```

It finds the most recent `SnapshotEvent` and replays everything after it. `Event` also
re-validates by replaying on write, so corruption tends to surface at the point it is caused.

**Do not add a query that sums quantities.** If you find something that looks like one, it is a
cache (`InventoryItem`) and not the source of truth.

## Users, roles and the two portals

Roles are Rolify, **scoped to a resource** — never just "admin", always "admin of this
organization".

```
User ──has_many──► Role ──scoped to──► Organization   (org_user, org_admin)
                        └──scoped to──► Partner        (partner)
                        └──global─────► —              (super_admin)
```

`User` has convenience associations that resolve the current context: `organization`,
`organization_role`, `partner`, `partner_role`, `last_role`. A user may hold several and switch
between them, which is why nearly every controller runs `authorize_user`.

| Portal | Routes | Shell | Who |
| --- | --- | --- | --- |
| Bank | top level | `layouts/essentials_app` | `org_user`, `org_admin` |
| Partner | `/partners/*` | `layouts/essentials_partner` | `partner` |
| Admin | `/admin/*` | `layouts/essentials_app` + admin rail | `super_admin` |

## Partner: status drives everything

```
uninvited → invited → awaiting_review → approved
                                   ↘ recertification_required
                                   ↘ deactivated
```

A `Partner` has one `Partners::Profile` (the agency detail the bank collects), and its own
family-side records used to build requests:

```
Partner
├── profile                    Partners::Profile ── served_areas ── counties
├── families                   Partners::Family
│     ├── children             Partners::Child
│     └── authorized_family_members
├── requests ───────────────── item_requests ── child_item_requests
├── users                      through roles
└── partner_group ──────────── item_categories (what it may request)
```

### Where an address is stored

Verified with `rails runner`. **Every model stores an address as parts** — the four that kept a
single freeform string were split on 2026-09-01.

| Model | Columns | Composed by |
| --- | --- | --- |
| `Organization` | `street`, `city`, `state`, `zipcode` | its own `#address` |
| `Vendor`, `DonationSite`, `ProductDriveParticipant`, `StorageLocation` | `street`, `city`, `state`, `zipcode` | `StructuredAddress#address` |
| `Partners::Profile` | `address1`, `address2`, `city`, `state`, `zip_code` — and the same five again prefixed `program_` | not composed; rendered field by field |
| `Partners::Family` | `guardian_zip_code`, `guardian_county` | a ZIP and a county, not an address |

`StructuredAddress` is `Organization`'s pattern extracted: `#address` composes
`"street, city, ST zip"`, `#address_changed?` answers `Geocodable`'s `after_validation` hook, and
`#address=` parses a whole address into the four parts — which is what lets the CSV importers keep
taking a single `address` column. `Organization` still has its own copies of the first two methods
rather than including the concern, because it is not `Geocodable` in quite the same way and has no
`#address=`.

**The `address` column still exists on those four tables and is in `ignored_columns`.** Nothing
reads or writes it; a later release drops it. Do not add code that uses it.

**All ZIP columns are strings.** `partner_profiles.program_zip_code` was an `integer` until
`20260901180000`, which silently dropped the leading zero from every ZIP in MA, RI, NH, ME, VT, CT,
NJ and Puerto Rico and could not hold ZIP+4 at all; two of the five values in the seed database had
been corrupted that way and the migration padded them back. A ZIP is an identifier, not a quantity.

## The request → distribution path

The workflow the app exists for.

```
1. Partner submits a Request        request_type: quantity | individual | child
2. Bank opens it, starts a Distribution   pre-filled from the request
3. DistributionCreateService        writes DistributionEvent, marks the request fulfilled,
                                    links Request ↔ Distribution
4. Partner sees the Distribution in their portal
```

`Request belongs_to :distribution` and `Distribution has_one :request` — the link is set at
fulfilment, and `validate_request_not_yet_processed!` is what stops a request being fulfilled
twice.

**Three things can seed a distribution**, and each has its own copier on `Distribution`:

| Seed | Method | What it copies |
| --- | --- | --- |
| `Request` | `copy_from_request` | the requested items and their quantities |
| `Donation` | `copy_from_donation` | the donation's line items and storage location |
| `Purchase` | `copy_from_purchase` | the purchase's line items and storage location |

All three go through `copy_line_items(itemizable_id, itemizable_type)`. That second argument used
to be hardcoded to `"Donation"`, which is the whole reason a purchase could not seed one — line
items are polymorphic and only the query was not. `DistributionsController#new` branches on
`request_id`, `purchase_id` and `donation_id` in that order.

## Where the code for each of these lives

| Concern | Where |
| --- | --- |
| Domain and associations | `app/models` (67) |
| Business logic | `app/services` (67), `{Model}{Action}Service` |
| The inventory ledger | `app/events` (17 + 7 value types) |
| Complex reads | `app/queries` (7) |
| Request handling | `app/controllers` (72), thin |
| UI | `app/views` (421); design system in `shared/essentials` |
| Behaviour | `app/javascript/controllers` (28), Stimulus |
