# Change log

A running record of what changed, in order, with the commit that carries it. The companion
documents answer different questions:

| Document | Question it answers |
| --- | --- |
| **This file** | What changed, when, and where to find it. |
| [design-decisions.md](design-decisions.md) | Why a judgement call went the way it did. |
| [migration-map.md](migration-map.md) | What replaced what, and how to verify a page. |
| [design.md](../design.md) | How to build a screen now. |
| [domain-model.md](domain-model.md) | How the records relate. |

Newest last. Dates are commit dates.

---

## Phase 1 — Foundation (2026-08-17)

Tailwind installed alongside the existing stack, so that nothing broke while pages were moved
across one area at a time.

| Commit | Change |
| --- | --- |
| `d4ec1e400` | Design system documentation, and the layout accessibility baseline: skip link, one `<main>`, `lang` bound to `I18n.locale`, zoom lock removed. |
| `8e98ea0be` | Tailwind v4 via `tailwindcss-rails`, no Node. Tokens, Figtree and Bootstrap Icons self-hosted. |
| `6a01113ea` | The app shell and the component layer: `essentials_app`, `essentials_partner`, `essentials_auth`, and `shared/essentials/*`. |

## Phase 2 — Area by area (2026-08-17)

Each commit moves one area onto the new shell and leaves the rest untouched.

| Commit | Area |
| --- | --- |
| `d2a2ed4ec` | Dashboard |
| `f35dca40a` | Authentication |
| `0e4e811aa` | Storage locations |
| `a5e7f044a` | Vendors, manufacturers, donation sites, product drive participants |
| `f02fbdd0d` | Donations |
| `f2e1963f7` | Purchases; the "add a new one" modals became native `<dialog>` |
| `39b24a53f` | Product drives, barcode items, item categories |
| `db4dba1bd` | Requests |
| `587ef132d` | Distributions |
| `6f6f6252c` | Transfers and adjustments |
| `eaf175fac` | Items, kits, audits — inventory complete |
| `1a20d6e64` | Bank-side partner management |
| `691d662ad` | Partner portal shell and profile partials |
| `0b27c58da` | Partner portal |
| `007c4d41a` | The remaining bank-side areas |
| `f3a0f2b42` | Indentation autocorrect after the sweep |
| `71ed53360` | Icons, error pages, account request flow |

## Phase 3 — Removing the old stack (2026-08-17)

| Commit | Change |
| --- | --- |
| `cda053539` | Deleted the Bootstrap/AdminLTE view layer: five layouts, four navbar and sidebar partials. |
| `3efdd73a2` | Removed Bootstrap, AdminLTE, sass-rails, bootstrap-select and the Font Awesome CDNs from the `Gemfile`, the asset path and the importmap. |

After this point a legacy class is a defect, not a page awaiting its turn: nothing defines
those class names any more, so they render as nothing at all.

## Phase 4 — What removal exposed (2026-08-18)

Deleting the old stack turned silent breakage loud. The system specs went from 298 failures to
zero across these commits; several were pre-existing bugs the old markup had been hiding.

| Commit | Change |
| --- | --- |
| `4a50aa72d` | Helpers, icons, the last accessibility fixes. |
| `93d8295a5` | The Bootstrap markup the browser sweep never reached. |
| `2c3341476` | `design.md` rewritten as the Tailwind specification. |
| `4db829472` | Test clock shim, confirm mechanism, flash hooks. |
| `f5611e000` | Admin navigation and the staging warning restored. |
| `62ef1a7ce` | Four broken controls; the partner show page's structure. |
| `b0d6169b9` | **Approve partner posted to a GET route.** A pre-existing bug. |
| `415719d7f` | **The distribution confirmation never ran**, and forms submitted with `<input>`. Pre-existing. |
| `8942e5a69` | Cold-start empty states given their own wording; two stale globals fixed. |
| `2b1a7496e` | Spec selectors retargeted at what they mean, not at styling. |
| `86b4f9eeb` | Three defects in the admin area; select2 had no stylesheet. |
| `f0dfb990d` | The account request form's reveal. |
| `18204c6bd` | **The partner profile form's fields were outside the form.** Pre-existing. |
| `8d4b8b742` | Request specs updated to the migration's copy. |
| `8d5f93060` | The date picker is asked whether it is open, rather than trusting a global. |
| `ee1d8b410` | Decisions from the system spec pass recorded. |
| `d49e4ce5d` | The last classes that draw nothing; browser sweep checked in. |
| `6077ba541` | Wait for the date picker before typing into it. |

## Phase 5 — Error pages and local access (2026-08-18)

| Commit | Change |
| --- | --- |
| `7cd23ab5b`, `1ef1dcb26` | `403`, `404`, `422` and `500` rebuilt as self-contained documents: inline tokens, vendored typeface, no stylesheet or script, because they must render when the app cannot. |
| `839bcf57b` | Behind a proxy, relax the CSRF origin check rather than forcing https. Forcing `assume_ssl` broke plain-http port forwarding with "Your session expired". |

## Phase 6 — Documentation (2026-08-18)

| Commit | Change |
| --- | --- |
| `20c0b0587` | `design.md` made to stand on its own, opening with the domain rather than the components. |
| `fee6f6090` | `migration-map.md` added. |
| `e3092bf80` | `onboarding.md` added (maintainers). |
| `dffb25b7f` | Keeping these documents current made a standing instruction in `CLAUDE.md`. |
| `dfb7b8f89` | `domain-model.md` added, read off the models rather than recalled. |
| `b5bc183e6`, `57e8cddc3` | The last references to the design system's origin app removed, including from the ADRs; one sentence mangled by that edit repaired. |
| `f61d7a22e` | The user-facing half of `onboarding.md`. |
| `dbe7418b1` | **Four invisible icons** on the bank-side partner profile editor. Found by grepping for undefined classes, not by the tooling. |
| `3cf21e1f9` | This change log. |
| `f61a4fd5f` | The migration map brought to the current measured state; the grep for undefined classes promoted into the verification commands. |
| `4f7b7fdd1` | `design.md` given the full document set and its measured status; today's four decisions logged; the standing instruction in `CLAUDE.md` extended to six documents and a stated cadence. |
| `0fd3f13ca` | A change log hash orphaned by an amend, corrected; the ancestry check and the reason the last row lags written down. |
| `e0c31a7e9` | All 27 index tables audited for row-action weight and badge density; `docs/table-audit.md` and `bin/design/table-audit.js` added; the row-action and badge rules made explicit in `design.md`. |
| `bc04f2243` | Corrected the audit: the empty `recertification_required` action cell is right, not a defect. |
| `a9f8d26ab` | **Every table row action is now `:ghost`.** 13 cells across 12 views moved off the legacy `*_button_to` shims and off `:secondary`. The audit script reports 0 tables with more than one weight, down from 7, and 0 filled buttons in rows, down from 6. |
| `e6ac2c21d`&hellip;`011c24fbb` | Partner list rebuilt on the shared filter bar, developed on `design-preview-partner-status` over five review rounds. |
| *(merge)* | **`design-preview-reports-hub` merged into `design`** — 13 commits, 139 files. Reports, page actions, 49 form and show pages, and the WCAG audit. Verified on the merge: 2904 examples 0 failures, axe 0 violations across 61 pages, all interaction checks pass, rubocop and erb_lint clean. |
| *(reports hub branch)* | **All 9 show pages cleared.** `bin/design/page-audit.rb` replaces the form-only script and covers show, index, form and partial, separating defects from debt. Found: a `<tr>` never closed, five `<td>`s closed with `</th>`, one `<h1>` per section inside a loop, an empty `<h2>` card header, and ten `width: %` inline styles summing past 100%. |
| *(reports hub branch)* | **All 40 form pages from the audit rewritten**, in three batches: partner portal, admin area, bank-side. `page_header` with a back link, the card component, fields through `f.input`, fieldsets for radio and checkbox groups, sentence case. Found on the way: three forms whose divs did not balance so the submit sat outside the fields, a stray expression printing `true` onto a page, a second `<h1>`, an empty collapse button, and an inline `<style>` block duplicating the vendored trix CSS. `bin/design/form-audit.rb` reports 0 findings, down from 40. |
| *(reports hub branch)* | Partner groups given their own page and URL; the Groups tab became a link so the page's primary action follows it, removing the fourth button that sat above the table. New `page_tabs` component for tabs that navigate. `docs/form-page-audit.md` added: 40 of 98 form pages still hand-roll their header, card or inputs inside a correct shell. |
| *(reports hub branch)* | **Reports rebuilt.** Four summary reports removed and their figures folded onto the index pages they duplicated; `<tfoot>` totals dropped in favour of a filtered band above the table; old report URLs redirect. The sidebar's 15-item Reporting group became one rail entry leading to a six-card hub for the eleven reports an index page cannot show. On `design-preview-reports-hub`; mockup in `docs/mockups/`. |
| *(merge)* | **Merged into `design`.** Status chips replaced by a labelled select; single-filter bars apply on change and drop "Clear filters"; "All statuses" added; status colour now means *who is blocked*; pill icons dropped and pills no longer wrap. Two bugs fixed on the way: a blank status filter matched every partner including deactivated ones, and the select chevron sat 4px from the border because padding does not move a native arrow. |
| `51b81a0cd` | Two modulepreload links dropped from every page: the `@fullcalendar/core/` directory pin, which has no module at its URL, and `sinon`, 180KB of test-only fake-timer support. The dead `esms-options` script removed from the shared head — es-module-shims has not shipped with importmap-rails since 2.0. 66 preload links per page, down to 64. |
| `152ca4b34` | **The last 42 view defects cleared** — 14 index pages and 30 partials. `bin/design/page-audit.rb` reports 329 views, 0 defects, 3 documented items of debt. |
| `751d16757`, `1d17753f6` | Date range picker options mocked up before building: the measured diagnosis, three industry patterns, and the wire-format constraint. The injected-rule count corrected from an estimate to a measurement, 72. |
| `e64e7a42b` | **Litepicker replaced by a preset `<select>` plus two native date inputs.** Both unversioned jsDelivr pins removed, along with `window.isLitepickerActive` and 102 lines of `application.js` (192 lines to 90). Preset ranges now computed server-side in `Time.zone`, so "Today" cannot disagree with the day the query filters on. Two latent bugs fixed on the way: the server rendered *prose* into the `filters[date_range]` field and Litepicker overwrote it during setup, and `filters[date_range_label]` carried that same prose rather than the preset name, so every named period collapsed to the generic wording after one round trip. Validation moved from `window.alert()` into the page. Three unused spec page objects pointing at the removed summary routes deleted. Wire format unchanged. |
| `d955031f7` | The "showing" line mocked up before building. Measuring `#date_range_label` first is what found that it could not produce the sentence: 4 of 13 outputs wrong, ambiguous or empty. |
| `1bb4d1d76` | **The selected period is now said in words**, in a sentence-case caption above the stats band on 4 index pages and in the `:no_results` empty state on 7. `#date_range_label` fixed first — **five** bugs, none of which anything could have caught because nothing read the method: `to_fs(:short)` carries no year, so *All time* rendered as "during the period 19 Aug to 19 Aug"; *This year* and *All time* had no clause and fell through to their dates; a range starting today returned `""`; and with no parameter it claimed "this year", which is the state every index page opens in and describes neither the default window nor anything else. The preset/clause pairing is now tested exhaustively. |
| `ab982834f` | The summary band mocked up before rebuilding. `CLAUDE.md` told to document and push without being asked; the `<iframe srcdoc>` / rack-mini-profiler trap recorded in the mockup README. |
| `c58dac6aa` | **The summary band is one card with hairline separators**, and its column count follows the figure count. It was a flat `sm:grid-cols-2 lg:grid-cols-3` whatever the number of figures, so it orphaned a tile on every page that had one — 3 + 1 at 1360px with four figures, 2 + 1 at 900px with three. Measured after: every row full at every breakpoint on all five call sites. The per-figure `slate-50` fill is gone, and the radius is 16px like every other card rather than 12px. Separators are a `gap-px` grid over a `slate-200` backdrop rather than `divide-x`, which borders by DOM order and so draws in the wrong place in any grid of more than one row. |
| `8a59c3297` | Filter bar and summary card options mocked up before building: the measured widths and trailing gaps, the Turbo Drive constraint on auto-applying, and three subheaders. |
| `2b5df7653` | **The filter bar is a grid**, so the controls are one width and the rows are full — it was `flex flex-wrap` with content-sized items, giving six widths across four pages and up to 852px of trailing space. 43 cell wrappers across 15 files. The summary card gained a title and a scope sentence (`essentials_stats_scope`), and `Default (recent and upcoming)` became `Last 2 months and next month`. |
| `a79452bd5` | **Filters apply on change, into a Turbo Frame; the Filter button is gone.** Sixteen bars plus the report card. Four details were each found by breaking them: `target="_top"` on the frame, without which every row action fetches a page with no matching frame and Turbo discards it (66 specs); `data-turbo="true"` on the form, without which Drive being off means a silent full page reload; `turbo_action: "advance"` to keep the URL shareable; and keeping the form outside the frame so focus survives. The export link is rebuilt from the form on each frame load — it sits outside the frame and would otherwise export the previous filter's rows. A `role="status"` region announces the new count, and `wait_for_filters` waits on network idle because Turbo never marks these frames busy. `events` and `distributions_by_county/report` were rebuilt rather than converted: both hand-rolled their filters, and `page-audit.rb` calls both clean. |
| `71f8468cc` | Filter density mocked up: the two defects measured, and three densities offered. |
| `1ae7f6e0a` | **The date range cell is one column like every other**, the actions follow the last filter instead of taking a row, and a bar of five filters or more collapses behind a Filters button with chips for whatever is set. `/donations` 264px to 38px, `/distributions` and `/requests` 188px to 38px, `/transfers` and `/items` to 64px from the two fixes alone. The threshold is counted in the partial so no call site decides it. Chips are built in the browser because the bar does not re-render when a filter applies. Three traps recorded in `docs/design-decisions.md`: `turbo:frame-load` fires on first connect too, so clearing the flash there deleted it on every page load; clearing the flash reflows the page and a coordinate-driven click lands where the button was; and the spec helper's quiet period has to exceed the 400ms text debounce. |
| `83a2fd534` | Filter consistency mocked up, and two bugs recorded with it: every modal opening top-left, and Calculate product totals living inside the filter bar. |
| `e543a08d7` | **Every dialog in the app was in the top-left corner** — 28 files. A native modal is centred by the browser's `margin: auto` and Tailwind's preflight resets it; one rule in `@layer base` restores that plus the `max-height` it also takes. `bin/design/overlay-audit.js` added, because the bug survived both existing audits: one reads markup, the other scans the page as loaded, and **neither had ever opened anything**. On its first run it found a second real thing, a dialog list that could not be scrolled by keyboard. Also: the disclosure threshold is gone so every filter bar behaves the same; the duplicate "Clear filters" inside the panel is gone; the date range is a popover, which removes the 216px cell that inline custom dates produced; the account menu moved onto the same `popover` controller and off `shadow-lg`; Calculate product totals moved into the page header; and Capybara's default wait went 2s to 5s, because filtering is asynchronous now and the failures read as wrong row counts rather than timeouts. |
| `c14ed96c2` | **Sidebar weight now follows the level, not the behaviour.** Dashboard, Reports and My organization were at the child weight (500/slate-600) beside Operations and Inventory at the parent weight (600/slate-700), all six at the same indent, so a top-level destination read as a child that had lost its parent. The rail's pinned item and the page footer are both `h-14` with a full-bleed border, so their rules meet at one height and run into the rail's `border-r` as a single line — they were 12px apart. Nav ordering written into `design.md`; *Reports* sitting at the top beside *Dashboard* is noted as against that rule and left pending a decision. |
| `8a90b6437` | **Reports moved below the working groups**, and nav spacing made uniform: one `space-y-4` between every top-level entry, where *Dashboard* and *Reports* had shared a list at the 2px inner spacing while everything else sat 16px apart. **The flash no longer clears when a filter applies** — that was added a commit earlier and is reversed here: removing 56px above the results shifts everything below it under the cursor, and it broke three specs that click a row action after filtering. One real bug found on the way: `auto_submit_controller` resolved its frame in `connect()`, but the form is parsed before the frame, so the export link and the announcement could silently never work. |
| `0536b3a68` | **Sprockets replaced by Propshaft** (ADR 0012). After the design system migration there was nothing left for a compiler to do: no `//= require` directives, no ERB assets, no Sass, no bundling, and one stylesheet the Tailwind CLI had already minified. Three pieces of configuration existed only to stop the compiler compiling — a disabled CSS compressor, an initializer rejecting the Tailwind source from the load path, and a hand-kept precompile list — and all three are gone, along with `manifest.js` and `terser`. Measured: the served stylesheet differs from the build by 24 bytes, which is Propshaft quoting 12 `url()` values; every font still resolves, icons render, 70 JS modules load, no failed requests. The development trap inverted — precompiling locally now *freezes* assets rather than refreshing them — and `CLAUDE.md`, `design.md` and `docs/onboarding.md` were updated to say so. |
| `292dfe41f` | The Propshaft row's own hash filled in — a commit cannot contain it. |
| `b56845b5c` | **Pagination audited across all 22 index tables**, and the nine mockups repaired: under Propshaft the undigested `/assets/tailwind.css` 404s, so every one of them had silently fallen back to Times New Roman. Found by measuring the heading font, not by looking. The audit's two findings: `items_controller` assigns `@paginated_items` and the name appears nowhere else in the repository, so the view renders all 51 items at 121px a row — a 6,442px page with no pager; and row heights differ 4.5× across the app, from 45px on `/users` to 205px on `/purchases`, which is why one page size cannot serve every table. |
| `081711102` | **Three page-size bands, and every unbounded index table now has a pager.** `Pagination::TALL/MEDIUM/COMPACT` (15/25/50) chosen by measured row height, so every full page lands between 1.8 and 3.4 screens; nineteen call sites name their band. Kaminari's default went from *5 in development, 50 elsewhere* to 25 everywhere — the split meant a page under review never looked like the page in production, so nobody ever saw the long table. Five tables gained a pager (audits, transfers, barcode items, announcements, admin base items) and `items` finally renders the collection its controller had always computed: 6,442px to 1,815px. Three defects found on the way, each on every page that used the component: the pager sat between **two** hairlines twelve pixels apart, because both the card footer and the partial drew the chrome; a single-page collection drew an **empty bordered strip**, because `capture` of a blank render is not blank in development where `annotate_rendered_view_with_filenames` puts a comment in the buffer — now `essentials_pagination_footer` returns `nil` instead; and page links did a whole-page visit rather than updating the results frame, losing the scroll position. `broadcast_announcements` was ordered with `.reverse` in the view, which reverses one page and not the collection, so it is ordered in the query now. Design options for the pager itself mocked up rather than built. |
| `727c59bda` | **The pager says how many rows matched.** "Page 3 of 19" became "Showing 31–45 of 272 requests" — option A of four designs put up in `docs/mockups/pagination-designs.html`. A page number is a proxy: it changes meaning whenever the page size does, which the three bands had just made concrete, and it never answered the question an index page's filter bar raises. The noun comes from Kaminari's `entry_name`, lowercased word by word so a word with an internal capital keeps it and a future `/admin/ndbn_members` reads "NDBN members". `« First` and `Last »` were kept although the mockup's A panel dropped them — jumping to the oldest record is a real task on audits and events. A rows-per-page select and load-more were both argued against in the mockup and not built. |
| `30cc779ee` | **The pager is always there, and so are its controls.** Option A of three in `docs/mockups/pagination-count-options.html`. A table that fitted on one page showed no strip at all — nine of sixteen index pages — so nothing said how many rows matched; measuring that turned up the same fault on longer tables, where the control set changed width as you paged (`/requests` was 7 controls on page 1, 14 on page 5, 8 on page 10). Now `‹ Prev` and `Next ›` are always drawn and disabled when they lead nowhere, `« First` and `Last »` appear only when there is more than one page, and the strip renders for any table with rows — an empty one still gets nothing, rather than a bar reading "0 of 0". Disabled is `<span aria-disabled="true">` at `opacity-60`, the app's existing treatment, measured at 2.88:1 against a live link's 7.56:1. Kaminari renders nothing for a single page by design and returns nil so the caller can supply fall-back HTML, which is the hook the one-page control set uses. Two passing bugs found on the way: `/product_drives` read "2 product drive", because Rails only pluralises a locale entry written as a one/other hash and `product_drive: "Product Drive"` is a plain string; and a spec context called "there are no organizations" had one, the super admin's own, created after its `delete_all` — its assertion passed only because a single page drew no Next. The filter announcement stops saying "Results updated" on paginated pages and reads the real total. |
| `3fc211c7f` | **The three historical trend pages migrated** — they were the last screens the first sweep missed. Their controllers had been given `layout "essentials_app"` and marked migrated in a comment; the views were never touched, so each was a bare Highcharts config with no page header, no card and **no `<h1>`**, and the tab title was just the organization name. Three near-identical 39-line files became one partial. Each now also carries the same figures as a table: `design.md` says a chart is never the only representation of the data, and these were the only chart pages in the app, so the rule had nowhere it was being kept. `bin/design/status.rb` was reporting them as migrated because its heuristic looked for `essentials_` with an underscore and so missed every `render "shared/essentials/…"` — it understated the migrated count by 51 pages and now excludes mailers and `static/` too. **A test-isolation bug surfaced on the way**: the test environment used the default `FileStore` cache under `tmp/cache`, which survives between runs, and `historical_data_cache_job_spec` writes a stubbed series into it — a bare Hash, a shape `HistoricalTrendService#series` cannot return. A later run read it back for a different organization that had been given the same id. 65MB and 9,317 files had accumulated. Test now uses `:memory_store` and the stub is the real shape. |
| `5a953fe9d` | **Callout extracted as a component** — 21 copies of the same twelve-class string across 20 files, each with its own margin baked in and no two agreeing on whether the role was `status`, `alert`, `note` or absent. Tint, border and glyph now come from `FLASH_STYLES`, the map the flash strip already used, so the two cannot drift into different shades of amber. Every call site's tone, role and margin were preserved exactly and the result diffed against the rendered pages to prove it. Two traps recorded in `design.md`: a partial rendered *somewhere* with a given local keeps it `defined?` and nil at the call sites that omit it, so `defined?(role) ? role : default` silently dropped the default on every callout that relied on it — `local_assigns` is the only safe idiom; and ERB tags inside an ERB comment end the comment early, which had already happened once in `_pagination`. |
| `46aea92d5` | **Dead scaffolding, dead classes and two unlabelled selects.** `donations/add_item`, `donations/remove_item` and `distributions/print` were Rails scaffold stubs from 2018 reading "Find me in app/views/…"; the first two had no controller action, so implicit rendering served that text to anyone who hit the route. Templates and the two dead routes removed. The four `account_requests` status pages were hand-rolled cards starting at `h3` with no `h1`, one with an orphan `</li>` and one with `style="color: #ff0505"` — rebuilt on the card and callout components. Classes that style nothing removed: `custom-select` ×3, `form-check`/`form-check-input`, `custom-control-input`, `text-md`, and `row flex-row` ×2 (which had no `flex`, so its alignment utilities did nothing either). Two selects were unlabelled: `admin/barcode_items` used `label_tag` with one argument, making `for="filter_by_item_category"` against `filters_barcodeable_id`, and `account_requests/new` repeated the `f.input`-wrapping-`f.association` defect already fixed once in `organizations/edit`. Two grids built their column class from a runtime value — Tailwind only generates a class it can find literally, so `lg:grid-cols-<%= n %>` worked by luck; both go through `essentials_grid_columns` now. |
| `11c7a3869` | **Disclosure extracted, and the last three hand-rolled cards cleared** — `page-audit.rb` reports **0 defects and 0 debt** for the first time. The FAQ lists and the partner profile accordion each hand-rolled the same open/close card, and the three copies had drifted: only one wrapped its trigger in a heading, only one put its row actions outside the button. `organizations/_details` had **two Edit buttons** on one card, and the top one was wrapped in `border-t` — footer chrome — so it drew a stray hairline above the heading; it is one card action in the header now. `bin/design/undefined-classes.py` added as a fourth audit: it reports the class tokens the stylesheet does not define, separating deliberate JS, spec and gem hooks from the 26 genuine orphans, which `migration-map.md` now lists with the reason each is left alone. `bin/design/status.rb` counts `render "shared/essentials/…"` as migrated markup and skips mailers and `static/`. |
| `6c3da46d5` | **The sweep asks the router now, and found eleven more unlabelled controls.** `bin/design/route-sweep.js` and `route-targets.rb` replace a hardcoded list of 56 paths with every GET route that renders HTML — 139 screens, visited as a super admin, a bank admin and a partner, with a real record id substituted for `:id`. The list is what hid the historical trend pages: they were in the sidebar, never on it, and had no `<h1>` for the length of the migration. On its first run the new sweep found the partner portal, which the old list never visited at all: nine unlabelled selects on the profile editor (`label: false` and nothing else, so the county and client-share controls had no accessible name), two on the child form, and an unlabelled file input. The two `date_of_birth` fields were the last in the app still using three dropdowns — simple_form labels only the year — and are now `html5: true` like every other date, with `start_year`/`end_year` becoming `min`/`max`. |
| `PENDING` | **The storage-locations flake was a real bug in every row action.** It had been recorded twice as a pre-existing flake and measured at 4 runs in 8 on a clean `HEAD`. It is a defect: row actions are `button_to` forms inside a results turbo-frame, and Turbo's `elementIsNavigatable` returns true inside a frame **even with Drive off** — so Turbo intercepted the submission, fetched the redirect and had to promote it to a top-level visit because the frame targets `_top`. Half the time that did nothing: confirm accepted, PUT handled, page unchanged. `essentials_action_button` sets `data-turbo="false"` now, so the browser submits the form. 0 failures in 20 runs. Diagnosed by instrumenting rails-ujs — the failing and passing runs made identical server requests, and both fired `confirm:complete answer=true` and a `submit` event, which is what ruled out everything else. |
| `PENDING2` | **Two dead-class bugs in JavaScript, and the audit extended to find them.** `password_visibility_controller` toggled `fa-eye`/`fa-eye-slash` — Font Awesome, removed in the migration — against markup that had been moved to Bootstrap Icons, so the icon never changed and the button's `aria-label` stayed "Show password" whatever the state. `file_input_controller` added Bootstrap's `font-weight-bold` and `list-unstyled`, so the selected-files heading was not bold and the list kept its bullets. And `application.js` called `classList.contains(".fc-prev-button")` with a leading dot, which is always false, so every unnamed calendar button was announced as "Next period" — including Today. `undefined-classes.py` scans JavaScript now. **The 23 remaining inert class names were removed** rather than left documented: a permanently non-zero audit is one people stop reading. Three of them turned out not to be inert and would have been deleted on the script's word — `filterrific-periodically-observed` and `form-inputs` belong to gems, and `filter-bar-submit` is defined in an inline `<style>` inside a `<noscript>`, which is what makes the filter bar work without JavaScript. The script reads gem `lib/` and inline `<style>` blocks now. |

---

## Current state

Measured on 2026-08-18 as of `dbe7418b1`, the last entry above. Re-run the commands in
[migration-map.md](migration-map.md#verifying-a-migration) to check them.

| | |
| --- | --- |
| Commits on the branch | 52 |
| Files changed against `main` | 604 |
| Controllers on a design system layout | 63 of 65 |
| Views carrying design system markup | 299 of 392 |
| Stimulus controllers | 30 |
| Undefined legacy classes left in `app/views` | 0 |

Verified at `0fd3f13ca`: `bundle exec rspec` 2903 examples, 0 failures, 1 pending (a
pre-existing `xit`); `rubocop` 648 files, no offenses; `erb_lint` 420 files, no errors.

The 93 views without design system markup are not a backlog. 55 are ten lines or fewer, 39 are
partials, 12 are mailer templates, and two are the `static/` marketing pages that are
deliberately outside the app shell. The remainder carry no markup of their own: chart
configuration, the `<head>` partial, and simple_form field lists whose markup comes from the
`:essentials` wrapper.

### Known inert leftovers

Not defects — they render nothing and change nothing — but they are still there:

- `class: 'form-horizontal'` on 12 forms. A Bootstrap 4 class that Bootstrap 5 had already
  dropped, so it was doing nothing before this work either. Left in place because removing it
  means editing option hashes rather than substituting a token, and that is the kind of edit
  that has already broken markup once on this branch.

---

## Keeping this current

Add an entry in the same change that makes it. One row: the commit, and what changed in a
sentence that will still mean something in a year.

A commit cannot contain its own hash, so the last row is filled in by the next commit. Check
the hashes are real and on the branch before you trust them — `git cat-file -e` is not enough,
it succeeds for dangling objects left behind by an amend:

```bash
grep -oE '`[0-9a-f]{9}`' docs/changelog.md | tr -d '`' | sort -u |
  while read -r h; do git merge-base --is-ancestor "$h" HEAD || echo "NOT ON BRANCH: $h"; done
```

- A **decision** — a judgement call someone could reasonably have made differently — goes in
  [design-decisions.md](design-decisions.md) as well, with its reasoning.
- A change to **how screens are built** updates [design.md](../design.md).
- A change to **what replaced what** updates [migration-map.md](migration-map.md).
- A change to the **models or their relationships** updates [domain-model.md](domain-model.md).

If a number appears in any of these documents, measure it before you write it down. Counts in
these documents have been wrong when they were recalled instead of counted, including twice
during the migration itself — which is why the verification commands are written down rather
than left as something you are supposed to remember.
