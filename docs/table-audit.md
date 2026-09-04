# Table audit — row actions and status badges

Audited 2026-09-04 against the running app, signed in as an organization admin, a partner and a
super admin. Counts are what a browser rendered, not what the source suggests.

**Re-run from 2026-08-18, and the row-action half of this document is now history.** All seven
deviations are gone and there is nothing left to fix: `more than one weight: 0`,
`filled button in a row: 0`, across **152** screens rather than the 27 that were hand-listed.
The sections below keep the old findings because the reasoning still explains why the rules are
what they are — but they describe a state the app is no longer in. Only the badge section still
reports live findings.

The two questions: **how many visual weights does a table use for its row actions**, and
**how many badges does a row carry**.

## The rules this is measured against

[design.md](../design.md) already settles both, and has since the migration:

- `:ghost` is the variant for "row actions, toolbar actions". `:primary` is the page's one
  main action; `:secondary` is a supporting action; `:danger` destroys.
- "A pill is a **state**, not a control: not focusable, does not look pressable."

So most of what follows is conformance, not new policy. Where this document goes beyond
design.md it says so.

## Industry practice, for the two cases that are not settled

**One weight for all row actions.** Material, Carbon, Polaris, Atlassian and GOV.UK all render
table row actions at a single low weight — text, ghost, subtle or plain link. The reason is
that a table is read down a column. Two weights in one column imply a hierarchy that does not
survive the next row: on `/partners`, "Review profile" is bordered and "Request recertification"
is not, yet each is the primary thing to do for its row. The emphasis tracks the action's name
rather than its importance, which is worse than no emphasis.

**Badge the exception, not the norm.** A column where every row is badged spends colour on
information the reader already has. Where 90% of rows say the same thing, the badge is noise
and the eye learns to skip the column — taking the exceptions with it.

**Three or more actions belong behind an overflow menu.** Carbon, Polaris and Atlassian all put
the third action onwards behind "…". This is the one place this app is close to the line and
this audit does *not* recommend changing it: see the note at the end.

## Row actions — measured

**2026-09-04: 152 screens, 0 tables using more than one weight, 0 filled buttons in a row.**
Every actions column is consistent within its table and across the app —
`bin/design/row-actions-audit.js` reports the same, with every trigger at 28px and column widths
from 76px to 198px.

Two advisories, neither a defect:

- **A menu holding two or fewer actions** on `/storage_locations`, `/donation_sites`, `/kits`,
  `/items`, `/partners`, `/partner_groups` and `/organization`. Correct when the action *set*
  varies by row state, which a single render cannot see.
- **Some rows carry no action** on `/events`. Correct where the row has no record to act on.

### The 2026-08-18 state, kept for the reasoning

19 bank-side tables and 8 admin tables were measured then; **17 conformed and 7 did not.** All
seven are fixed. The table and the explanation below are retained because they record why the
one-weight rule exists, not because anything still deviates.

| Table | Rows | Max actions | Weights used | |
| --- | --- | --- | --- | --- |
| `/items` | 208 | 3 | ghost | ✓ |
| `/distributions` | 5 | 4 | ghost | ✓ |
| `/requests` | 51 | 3 | ghost | ✓ |
| `/barcode_items` | 13 | 3 | ghost | ✓ |
| `/vendors`, `/storage_locations`, `/donation_sites` | 1–4 | 3 | ghost | ✓ |
| `/donations`, `/transfers`, `/kits`, `/manufacturers`, `/product_drive_participants` | 1–5 | 2 | ghost | ✓ |
| `/purchases`, `/adjustments`, `/product_drives` | 2–5 | 1 | ghost | ✓ |
| `/users` | 4 | 3 | ghost (source) | ✓ |
| ~~`/partners`~~ | 8 | 2 | ~~bordered + ghost~~ | fixed |
| ~~`/broadcast_announcements`~~ | 1 | 2 | ~~filled + danger~~ | fixed |
| ~~`/admin/organizations`~~ | 3 | 2 | ~~bordered + danger~~ | fixed |
| ~~`/admin/users`~~ | 5 | 2 | ~~bordered + filled~~ | fixed |
| ~~`/admin/base_items`~~ | 47 | 2 | ~~bordered + filled~~ | fixed |
| ~~`/admin/partners`~~ | 7 | 2 | ~~bordered + filled~~ | fixed |
| ~~`/admin/broadcast_announcements`~~ | 1 | 2 | ~~filled + danger~~ | fixed |

### Why the seven deviated

*Past tense throughout: all seven are fixed and the grep below returns nothing. Kept because it
records why the one-weight rule exists and how a helper can be the cause of a styling problem.*

Six of the seven were not a styling choice at all. They still called the legacy `UiHelper`
shims — `edit_button_to`, `delete_button_to`, `view_button_to`, `invite_button_to` — and
`UiHelper::VARIANT_FOR_TYPE` maps `"primary" => :primary` and `"danger" => :danger`, both of
which are **filled**. That mapping is right for a page header and wrong for a table row, and
nothing in the helper knows which it is in.

The nine cells still on legacy helpers:

```
admin/barcode_items/_barcode_item_row.html.erb              delete_button_to
admin/base_items/_base_item_row.html.erb                    edit_button_to, view_button_to
admin/broadcast_announcements/_broadcast_announcement.html.erb  delete_button_to, edit_button_to
admin/organizations/_list.html.erb                          delete_button_to, view_button_to
admin/organizations/_organization_row.html.erb              delete_button_to, edit_button_to, view_button_to
admin/partners/index.html.erb                               edit_button_to, view_button_to
admin/users/_list.html.erb                                  edit_button_to, invite_button_to
admin/users/_roles.html.erb                                 delete_button_to
broadcast_announcements/_broadcast_announcement.html.erb    delete_button_to, edit_button_to
```

`/partners` is the seventh and the only deliberate one: `_partner_row.html.erb` passes
`variant: :secondary` for "Review profile" and `:ghost` for everything else.

## Status badges — measured

**2026-09-04: six tables badge every row, and four of them have fewer than three rows, where the
measurement says nothing at all.**

| Table | Rows | Badge on each | Reading |
| --- | --- | --- | --- |
| `/partners` | 6 | Approved, Awaiting review, Approved, Invited, Recertification required, Approved | Deliberate. See below. |
| `/partners/1/approve_application` | 6 | the same six | The same table, on the approval screen. Newly visible only because the audit widened to every route. |
| `/partner_groups` | 2 | No, No | **The one worth a decision.** A boolean column, pilled in both states. |
| `/adjustments/1` | 1 | Added | One row. Says nothing. |
| `/broadcast_announcements` | 1 | Expired | One row. Says nothing. |
| `/admin/broadcast_announcements` | 1 | Expired | One row. Says nothing. |

**The count went from 1 to 6 without anything getting worse.** The audit used to visit 27
hand-listed tables and now visits every route, so five of the six are newly *looked at* rather
than newly wrong. `badgedRows === rows` is trivially true of a one-row table: it cannot tell
"badges mark the exception" from "badge on every row" with one row to go on. The script prints the
row count beside each path now, and says how many are below three, because the bare number invited
precisely the wrong conclusion.

### `/partner_groups` — a question rather than a finding

The "Send reminders?" column pills both states: `Yes` in success tone with a bell,
`No` in neutral tone with a struck-through bell. So every row carries a badge, which is what the
rule is against — but the rule exists to stop a badge shouting on a row that is not exceptional,
and a neutral grey pill is not shouting.

Three ways to read it, and it is a design call rather than a defect:

1. **Leave it.** A two-state column where both states are real information, and the neutral tone
   already marks "No" as unremarkable. Pill plus icon scans faster than a bare word.
2. **Pill only `Yes`.** "No" becomes plain text, and the badge marks the row that has something
   switched on. Most consistent with the rule as written.
3. **Pill neither.** A tick and a dash, which is what a boolean column usually gets.

Not changed, because design decisions get shown before they get built.

### The 2026-08-18 badge survey, kept

The dominant pattern was already the right one. Twelve tables badge **only the exception** and
attach it to the name rather than giving it a column:

| Table | Badges | When |
| --- | --- | --- |
| `/items`, `/vendors`, `/storage_locations`, `/donation_sites`, `/kits` | "Inactive" | only when inactive |
| `/broadcast_announcements`, `admin/…` | "Expired" | only when expired |
| dashboard low inventory, item inventory rows | "Below minimum" | only when below |

Five tables badge **every row**. Only `/partners` was an index page the script visited then; the
other four were found by reading the row partials, and are reached from a partner's or a group's
page rather than from a top-level list:

| Table | Badges per row | Distinct badge kinds |
| --- | --- | --- |
| `/partners` | 1, always | 6 (one per status) |
| `partner_users/_users` | up to 2 | 3 (Accepted / Waiting acceptance / Never) |
| `partners/_partner_groups_table` | 1, always | 3 (Yes / No / No items requestable) |
| `distributions/_pickup_day_row` | 1, always | 2 (Complete / Scheduled) |
| `partners/children/_list` | 1, always | 2 (Active / Inactive) |

### `/partners` specifically

**2026-09-04: the filter strip is gone, and with it the problem that mattered.**
`partners/_statuses.html.erb` no longer exists and nothing in the app renders `#partner-status`
— the audit reports **0** filter chips where it used to find 7. So a screen that carried 13
badges now carries 6, one per row.

What remains is the first point only, and it is deliberate: every row is badged, including the
majority "Approved" state, because the column *is* the status. Measured: Approved, Awaiting
review, Approved, Invited, Recertification required, Approved — five distinct values across six
rows. A status column whose values genuinely vary is not the thing the "badge the exception"
rule is aimed at.

The 2026-08-18 finding, for the record:

> 6 rows, 6 row badges, plus a 7-badge filter strip = 13 badges on one screen. **The filter strip
> and the status column share a visual language.** The strip built its chips from
> `EssentialsUiHelper::PILL_TONES` — literally the status palette — so a control that filters the
> list and a badge that reports a row's state were the same shape, size and colour. design.md says
> a pill is a state and "does not look pressable"; half of them were links.

## Two further inconsistencies found while auditing

- **The same concept is rendered two ways.** Still true on 2026-09-04. Invitation status is plain
  text in `users/_organization_user.html.erb:6` (`<td><%= user.invitation_status %></td>`) and
  three coloured pills in `partner_users/_users.html.erb`.
- **~~A partner in `recertification_required` has no row action.~~ No longer true.** The `case` in
  `_partner_row.html.erb` still falls through for that status, but the partial now ends with
  `row_items += [{label: "View partner", ...}] if row_items.empty?`, so the row gets one action
  instead of an empty column. Measured across the six seeded rows: Approved → "Request
  recertification", Awaiting review → "Review profile", Invited → "Review profile" and "Re-send
  invite", Recertification required → **"View partner"**.

  The reasoning behind the original note still holds and is worth keeping: while a partner is in
  this state the bank genuinely has nothing to *do*. `Partner#approvable?` is
  `invited? || awaiting_review?`, so the show page offers no "Approve partner" either, and
  `PartnerRequestRecertificationService#valid?` refuses to run against a partner already in the
  state. The ball is with the partner until they resubmit. The fallback gives the row a way in
  without inventing an action that would fail.

## Not recommended

**Do not move row actions behind an overflow menu.** Industry practice says three or more
actions belong behind "…", and `/distributions` renders four. It is still the wrong trade here:
this app is used by warehouse staff processing a list, the actions are the job rather than an
occasional detour, and hiding "Print" behind a menu costs a click on every row. `/users` already
records why its dropdown was removed in the migration. Revisit if a table reaches five.

## Verifying

`bin/design/table-audit.js` enumerates every route rather than a hand-kept list, visits each in a
real browser as all three roles, reports weights and badge counts per table, and exits non-zero if
any table uses more than one weight. On 2026-09-04, against a seeded development server:

```
tables audited:            152
more than one weight:      0
filled button in a row:    0
badge on every row:        6  /adjustments/1 (1 row) /partners/1/approve_application (6 rows)
                              /partners (6 rows) /partner_groups (2 rows)
                              /broadcast_announcements (1 row) /admin/broadcast_announcements (1 row)
                           4 of those have fewer than 3 rows, where this says nothing.
```

`bin/design/row-actions-audit.js` answers the other half — the shape of the actions column rather
than the weight of what is in it:

```
every actions column is consistent within its table and across the app
advisory -- a menu holding 2 or fewer actions:  /storage_locations /donation_sites /kits
                                                /items /partners /partner_groups /organization
advisory -- some rows carry no action:          /events
```

```bash
bin/start                      # then, with the app running:
pw bin/design/table-audit.js
pw bin/design/row-actions-audit.js

# The source-level version: table views still calling the legacy filled-button helpers.
grep -rlE '(view|edit|delete|deactivate|reactivate|invite)_button_to' app/views/ |
  xargs grep -l '<td'
```

**That grep now returns nothing.** It found 9 views on 2026-08-18. One call to a legacy helper
survives anywhere in `app/views` — `organizations/_header.html.erb:23`, `edit_button_to` — and it
is in a page header rather than a table cell, where it renders `:primary`. That is what design.md
asks a page's single main action to be, so it is correct output from a legacy call: worth knowing
about, not worth changing on its own.

The static check and the browser check answer different halves. A grep finds the legacy helper
calls; only the browser shows what variant they resolved to, which is the thing a user sees.
