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
| *(this commit)* | **Reports moved below the working groups**, and nav spacing made uniform: one `space-y-4` between every top-level entry, where *Dashboard* and *Reports* had shared a list at the 2px inner spacing while everything else sat 16px apart. **The flash no longer clears when a filter applies** — that was added a commit earlier and is reversed here: removing 56px above the results shifts everything below it under the cursor, and it broke three specs that click a row action after filtering. One real bug found on the way: `auto_submit_controller` resolved its frame in `connect()`, but the form is parsed before the frame, so the export link and the announcement could silently never work. |

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
