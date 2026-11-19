# Peeling the `design` branch apart, by concept (#5764)

*A proposal, drafted with Claude Code. This file lives on the `design` branch as the map for breaking it up. It is not meant to merge to `main`.*

## The idea

The `design` branch (662 commits, 1,175 files, +99k/−30k) moved to the Ruby for Good design system **area by area**. Each area was switched to a new Tailwind-only layout, and Bootstrap and Tailwind never shared a page. That is why every area PR on that branch also brought new navigation, moved buttons and a new IA. They came with the layout.

This plan goes the other way. It **loads the design system on the existing pages next to Bootstrap**. Then it brings it in **one concept at a time, across the whole app**: tokens, then icons, buttons, tables, forms and so on. Each PR changes one idea everywhere and nothing else. Navigation and button placement stay put until a PR that is explicitly about them.

Three mechanisms make it safe (slices 1–2):

- **No second reset.** Tailwind's Preflight is not loaded. Bootstrap's Reboot keeps owning element defaults.
- **No class collisions.** Tailwind's class scanning is off and gets added back deliberately. If it scanned today's views it would emit about 90 utilities that Bootstrap/AdminLTE already define with different meanings. For example, `mb-3` is 0.75rem in Tailwind and 1rem in Bootstrap, and Tailwind's `collapse` (visibility: collapse) would hide every open Bootstrap collapsible. A spec fails the build on any overlap.
- **A temporary bridge.** `app/assets/tailwind/legacy/bootstrap_bridge.css` paints design tokens onto legacy classes, using the rule "swap values, keep shapes". Each later concept PR deletes its section, and the file leaves with Bootstrap.

## Built so far: a stack of 4 draft PRs

Review and merge them in order. Each PR is based on the one before, so it shows only its own diff.

| # | PR | What changes on screen | Size |
|---|---|---|---|
| 1 | #5765 `design-system/01-tailwind-foundation` | Nothing. tailwindcss-rails (standalone CLI, no Node), the token `@theme`, self-hosted Figtree, CI build step, Procfile watcher. | 21 files, +291 (10 are font binaries) |
| 2 | #5766 `design-system/02-load-alongside-bootstrap` | Nothing. 24 of 25 screenshotted pages are pixel-identical. The 25th has live data and differs between identical runs too. Also fixes a deploy-breaker: sassc-rails compresses CSS with libsass in production, libsass can't parse Tailwind v4, so `assets:precompile` would fail. The compiled Bootstrap CSS stays byte-identical. | 6 files, +56 |
| 3 | #5767 `design-system/03-tokens-on-legacy-ui` | Indigo brand replaces Bootstrap blue. The page canvas and body text move to slate. All 25 pages keep their exact dimensions. Measured in the browser: 35 kinds of element painted blue before; 1 deliberate leftover after (a categorical `bg-blue`). | 3 files, +207 |
| 4 | #5768 `design-system/04-typeface` | Figtree replaces Source Sans Pro, and the Google Fonts request is dropped. Text reflows: 14 of 25 pages change height. **Known:** at 1024px, tables that already overflowed their card on `main` now overflow more, and `/items` gains a horizontal scrollbar. Consider landing this after the tables slice. Includes a separate spec-race fix: faster page loads exposed a Litepicker race in the date-range-picker examples. That fix can also land on `main` alone. | 5 files, +42/−10 |

Each is reviewable in one sitting. Slices 1–2 are plumbing that a reviewer reasons about. Slices 3–4 a reviewer looks at.

## Track A: fixes `main` needs regardless (open now, independent)

These are bugs on `main` found inside the design branch. I verified the starred items against `main`; the others come from the branch survey and need a check before opening.

- ★ `HistoricalTrendService`: the query covers 13 months, but `index = month − current_month − 1` puts last year's same month into this month's slot.
- ★ Admin organization page: `find_by(id: @organization.storage_locations)` should look up `intake_location`.
- ★ The 500 handler renders `layouts/error`, which does not exist.
- Admin barcode-items filter never filters. `Partner#family_zipcodes_count` treats ZIP+4 as distinct. `program_zip_code` is an integer, which drops leading zeros (a migration). Broken CSV template links. `KitsController#deactivate` doesn't rescue.
- Dead routes: about 29 routes to missing actions, and `resources :requests` declared twice.
- ★ `config/initializers/site_urls.rb` uses `ENV.fetch`, but `.env.example` ships `PRODUCTION_URL=` and `DEMO_URL=` blank. A fresh `.env` therefore gets empty site URLs and 12 failing specs locally (site URL helper, account request mailer, account request system). Use `.presence ||`.
- ★ `spec/requests/storage_locations_requests_spec.rb` "GET #show … with version date set" fails 2 examples on pristine `main` locally. Worth a look; it could be date-dependent.
- Dead layouts: `layouts/partner.html.erb` and `layouts/application_old.html.erb` are not used by any controller.

## Track B: the design system, concept by concept (continues the stack)

Each slice changes one concept app-wide, and deletes its bridge section where it has one.

| Next | Concept | Why it's one PR | Rough reach on `main` |
|---|---|---|---|
| 5 | **Icons**: Font Awesome (CDN) → self-hosted Bootstrap Icons | Mechanical mapping, and mostly through helpers | ~400 `fa-*` usages |
| 6 | **Buttons**: `ui_helper`'s `_link_to`/`_button_to` emit design system buttons, then the hardcoded `btn` classes | The helper is a choke point. This is the first slice to turn Tailwind scanning on, scoped to the helper file only | 263 helper call sites + 126 hardcoded |
| 7 | **Tables**: the `data-table` look plus a scroll container | Also fixes the overflow that slice 4 surfaces | ~500 `table` class uses |
| 8 | **Forms**: swap the simple_form wrapper (`simple_form_essentials.rb` replaces the 438-line Bootstrap initializer) | One initializer restyles most forms | most forms |
| 9 | **Pagination** (a Kaminari theme), **flash/alerts**, **badges/pills** | Each is a partial set or one helper | small |
| 10 | **Cards** (+ AdminLTE `box`) | The most-used component | ~1,100 refs |
| 11 | **Page header / breadcrumb** | One partial pattern | most index/show pages |
| 12 | **App shell**: sidebar and top bar rebuilt in Tailwind with the **same** nav items, order and collapse behavior | Kept apart from any IA change (see Track C) | 3 layouts + nav partials |
| 13 | **Overlays**: Bootstrap modal/dropdown/tooltip JS → native `<dialog>` and Stimulus | Behavior-adjacent, so it gets its own focused review | ~10 controllers |
| 14 | **Grid & spacing utilities**: `row`/`col-*`/`mb-3` → Tailwind | Most diffuse, so it goes last. Scanning extends to all views once this lands | ~830 grid refs |
| 15 | **Retire** Bootstrap, AdminLTE, jQuery and Sass; Sprockets → Propshaft; delete the bridge | Only once nothing needs them | ~60 files |

Turning scanning on needs care. `main` already has stray Tailwind classes that render nothing today (`cursor-default`, `text-blue-500`, ~80 uses). They come alive when their files are scanned. So scanning grows file by file, and each PR that widens it says what started rendering.

## Track C: product and IA decisions buried in the branch (each needs a maintainer yes/no)

These were folded into "restyle" on the branch. Each should be a small PR of its own, after the concept it depends on:

- A new nav IA (Operations / Inventory / Network groups) and a `/reports` hub replacing 15 sidebar entries
- `/users` removed (folded into the organization page); 4 summary reports folded into index pages
- The items page split into 5 routed tabs
- Filters auto-submit and the Filter button removed; "All statuses" with counts
- The distributions table cut from 18 columns to 9; page-subtotal footers replaced with a whole-set "Totals" band
- Pagination banded at 15/25/50 (the Kaminari default changes)
- Actions that will fail are no longer greyed out; they run and explain why
- Validation errors shown inline with an error summary, not a flash (~30 controllers)
- A sentence-case and copy sweep across mailers, locales and model errors
- Edit/Delete moved into overflow menus on show pages

## Track D: features riding along (separate proposals)

- Structured address (migrations; ship the column drop in a later deploy than the backfill)
- Purchase → distribution
- Bulk picklist printing
- Request cancellation with a required reason
- Historical trends rework
- Calendar rework
- PDF engine Prawn → sghtmltopdf (changes printed receipts, and removes the `ruby` lockfile platform)
- Public bank finder and landing page: a policy decision, with outbound HTTP and a 1.5MB committed census file

## Probably should not land

- `public/*.html` prototype pages. Anything in `public/` is served in production.
- `docs/prompt-history.md`, `docs/skill-proposal*.md`, `.claude/skills/*`
- The `bin/workspace-*` / `lib/workspace_drift.rb` scripts
- The `bin/design` audit suite (44 files, Node + Playwright in CI), unless someone wants to own it
- `design.md` (5.2k lines) and `docs/design-decisions.md` (10.5k lines). These are worth mining, but should travel in pieces with the slice each part describes.
