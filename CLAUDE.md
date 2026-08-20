# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Human Essentials is a Ruby on Rails inventory management system for diaper banks and essentials banks. It's a Ruby for Good project serving 200+ non-profit organizations. The app manages donations, purchases, distributions, inventory, partners, and requests for essential items.

## Common Commands

### Development
```bash
bin/setup          # First-time setup (installs gems, creates DB, seeds)
bin/start          # Starts Rails server (port 3000) + Delayed Job worker
```

### Testing
```bash
bundle exec rspec                              # Run full test suite
bundle exec rspec spec/models/item_spec.rb     # Run a single test file
bundle exec rspec spec/models/item_spec.rb:42  # Run a single test at line
bundle exec rspec spec/models/                 # Run a directory of tests
```

CI splits tests into two workflows: `rspec` (unit tests, excludes system/request specs) and `rspec-system` (system and request specs only, 6 parallel nodes). System tests use Capybara with Cuprite (headless Chrome).

### Linting
```bash
bundle exec rubocop                  # Ruby linter (Standard-based config)
bundle exec erb_lint --lint-all      # ERB template linter
bundle exec brakeman                 # Security scanner
```

### Database
```bash
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec rake db:reset            # Drop + create + migrate + seed
```

## Architecture

### Multi-Tenancy
Nearly all data is scoped to an `Organization`. Most models `belong_to :organization` and queries should always scope by organization context. The current user's organization is the primary tenant boundary.

### Roles (Rolify)
Four roles defined in `Role`: `ORG_USER`, `ORG_ADMIN`, `SUPER_ADMIN`, `PARTNER`. Roles are polymorphic and scoped to a resource (usually an Organization). Authentication is via Devise.

### Event Sourcing for Inventory
Inventory is **not** tracked via simple column updates. Instead, it uses an event sourcing pattern:

- **`Event`** (STI base model) stores all inventory-affecting actions as JSONB events
- Subclasses: `DonationEvent`, `DistributionEvent`, `PurchaseEvent`, `TransferEvent`, `AdjustmentEvent`, `AuditEvent`, `KitAllocateEvent`, `SnapshotEvent`, etc.
- **`InventoryAggregate`** replays events to compute current inventory state. It finds the most recent `SnapshotEvent` and replays subsequent events
- **`EventTypes::Inventory`** is the in-memory inventory representation built from events
- When creating/updating donations, distributions, purchases, transfers, or adjustments, the corresponding service creates an Event, and `Event#validate_inventory` replays all events to verify consistency

This means: to check inventory levels, use `InventoryAggregate.inventory_for(organization_id)`, not direct DB queries on quantity columns.

### Service Objects
Business logic lives in service classes (`app/services/`), not controllers. Pattern: `{Model}{Action}Service` (e.g., `DistributionCreateService`, `DonationDestroyService`). Controllers are thin and delegate to services.

### Key Models
- **Item**: Individual item types (diapers, wipes, etc.) belonging to an Organization. Maps to a `BaseItem` (system-wide template) via `partner_key`.
- **Kit**: A bundle of items. Kits contain line items referencing Items.
- **StorageLocation**: Where inventory is physically stored. Inventory quantities are per storage location.
- **Distribution**: Items sent to a Partner. **Donation/Purchase**: Items coming in. **Transfer**: Items between storage locations. **Adjustment**: Manual inventory corrections.
- **Partner**: Organizations that receive distributions. Partners have their own portal (`/partners/*` routes) and users.
- **Request**: Partner requests for items, which can become Distributions.

### Routes Structure
- `/` - Bank user dashboard and resources (distributions, donations, etc.)
- `/partners/*` - Partner-facing portal (separate namespace)
- `/admin/*` - Super admin management
- `/reports/*` - Reporting endpoints

### Query Objects
Complex queries are extracted into `app/queries/` (e.g., `ItemsInQuery`, `LowInventoryQuery`).

### Frontend
Tailwind CSS v4 (via the `tailwindcss-rails` standalone CLI — no Node, no package.json), Turbo Rails, Stimulus.js, ImportMap (no Webpack/bundler). JavaScript controllers live in `app/javascript/controllers/`.

The asset pipeline is **Propshaft**, not Sprockets (ADR 0012). It does not compile anything: no
directives, no ERB assets, no Sass, no minification. It digests filenames and rewrites `url()`
in CSS. There is no precompile list — everything on the load path is served.

The UI follows a documented design system. **`design.md` is normative** — read it before building or changing a screen. Components are partials in `app/views/shared/essentials/` and helpers in `EssentialsUiHelper`; build from those rather than from utility strings.

Bootstrap and AdminLTE were removed (ADR 0011). A class like `btn`, `card-body`, `form-group`, `col-md-*` or `fa-*` is defined nowhere and renders as nothing — see `docs/migration-map.md` for what to write instead.

### Background Jobs
Delayed Job for async processing (emails, etc.). Clockwork (`clock.rb`) for scheduled tasks (caching historical data, reminder emails, DB backups).

### Feature Flags
Flipper is available for feature flags, accessible at `/flipper` (auth required).

## Testing Conventions

- RSpec with FactoryBot. Factories are in `spec/factories/`.
- **Setting up inventory in tests**: Use `TestInventory.create_inventory(organization, { storage_location_id => [[item_id, quantity], ...] })` from `spec/inventory.rb`. There's also a `setup_storage_location` helper in `spec/support/inventory_assistant.rb`.
- System tests use Capybara with Cuprite driver. Failed screenshots go to `tmp/screenshots/` and `tmp/capybara/`.
- Models use `has_paper_trail` for audit trails (32 of them). Deletion is usually deactivation:
  most models carry an active/deactivated status, and only `Request`, `User` and
  `StorageLocation` use `Discard` proper. Check before reaching for `destroy`.
- The `Filterable` concern provides `class_filter` for scope-based filtering on index actions.
- **Run the system specs for anything that touches a view.** Request specs do not load
  JavaScript. During the design system migration, three classes of defect were invisible to
  everything except the browser suite: markup a browser reparses into a different shape
  (fields ending up outside their `<form>`), Stimulus controllers toggling classes that no
  longer exist, and confirmation dialogs that never appeared.
- **Do not run `assets:precompile` in development or test.** The pipeline is Propshaft
  (ADR 0012), which serves from the load path in both, so precompiling *freezes* assets: Rails
  serves `public/assets/.manifest.json` until you delete it. If assets look stale, that file is
  usually why — `bin/rails assets:clobber`, then `bin/rails tailwindcss:build`.
- `assets:clobber` deletes the Tailwind build too (`tailwindcss-rails` enhances the task), so it
  always needs `tailwindcss:build` after it or every page 500s on a missing `tailwind.css`.
- Behind a port forward or TLS-terminating tunnel, start the server with `TUNNEL=1` or CSRF
  will reject every form and report it as "Your session expired".

## Dev Credentials

All passwords are `password!`. Key accounts: `superadmin@example.com`, `org_admin1@example.com`, `user_1@example.com`.

## Documentation — keep these current

Six documents describe how this app is built and why. **Update them as part of the work that
changes them, in the same commit — not afterwards.** A stale document is worse than no document,
because the next person will trust it.

| Document | Update it when |
| --- | --- |
| `design.md` | You add or change a component, token, layout or UI convention. It is the normative spec for the design system. |
| `docs/changelog.md` | Always. Every change gets a row: the commit, and what changed in a sentence that will still mean something in a year. This is the record of what happened and when. |
| `docs/design-decisions.md` | You make a judgement call worth explaining — why this pattern and not the obvious alternative. Append a dated entry with the reasoning, including alternatives rejected. |
| `docs/domain-model.md` | You change a model, an association, an enum or a role. Its claims are read off the code — verify with `rails runner`, do not recall them. |
| `docs/migration-map.md` | You migrate something, retire a legacy pattern, or find a leftover. Keep the translation tables and the "not migrated" list true. |
| `docs/onboarding.md` | You change setup, testing conventions, or anything a *user* sees — it has a maintainer half and a user half, and the user half goes stale quietly because contributors do not read it. |
| `docs/architecture/decisions/` | A structural decision is made. ADRs are historical records: add a new one, supersede an old one, but do not rewrite what a past decision said. |

The cadence: **work, then document, then commit and push, at every checkpoint.** Not batched at
the end. The documentation and the change it describes belong in the same commit, and a
checkpoint that is not pushed is a checkpoint that can be lost — this workspace has been reset
out from under the work three times.

**Do this without being asked.** Finishing a piece of work means: update whichever of the six
documents it touched — `design.md`, `docs/onboarding.md`, `docs/migration-map.md` and the rest —
then commit and push. Do not stop to ask whether to document it, and do not wait for permission
to push. The one thing that still needs asking is a *design* decision: show a preview and let
the user choose before building a screen.

A user-visible change almost always touches `docs/onboarding.md`. Its user half goes stale
quietly, because contributors do not read it — check it every time, not only when it seems
obviously relevant.

Three habits that go with this:

- **Verify claims before writing them down.** Numbers in these documents were measured
  (`grep`, `bin/design/status.rb`, `rails runner`, the specs), not estimated. If you state a
  number, measure it in the same session you write it.
- **Record the decision where someone will look for it.** A comment explains the line; the
  decision log explains the choice; the change log says when it landed. Use all three when the
  choice was not obvious.
- **Name what you chose not to do.** A known-inert leftover that is written down costs nothing;
  the same leftover undocumented costs the next person an afternoon deciding whether it matters.
