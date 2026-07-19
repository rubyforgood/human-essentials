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
Bootstrap 5.2, Turbo Rails, Stimulus.js, ImportMap (no Webpack/bundler). JavaScript controllers live in `app/javascript/`.

### Background Jobs
Delayed Job for async processing (emails, etc.). Clockwork (`clock.rb`) for scheduled tasks (caching historical data, reminder emails, DB backups).

### Feature Flags
Flipper is available for feature flags, accessible at `/flipper` (auth required).

## Testing Conventions

- RSpec with FactoryBot. Factories are in `spec/factories/`.
- **Setting up inventory in tests**: Use `TestInventory.create_inventory(organization, { storage_location_id => [[item_id, quantity], ...] })` from `spec/inventory.rb`. There's also a `setup_storage_location` helper in `spec/support/inventory_assistant.rb`.
- System tests use Capybara with Cuprite driver. Failed screenshots go to `tmp/screenshots/` and `tmp/capybara/`.
- Models use `has_paper_trail` for audit trails and `Discard` for soft deletes (not `destroy`).
- The `Filterable` concern provides `class_filter` for scope-based filtering on index actions.

## Dev Credentials

All passwords are `password!`. Key accounts: `superadmin@example.com`, `org_admin1@example.com`, `user_1@example.com`.
