# Table audit — row actions and status badges

Audited 2026-08-18 against the running app, signed in as both an organization admin and a
super admin. Counts are what a browser rendered, not what the source suggests.

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

19 bank-side tables and 8 admin tables. `maxActs` is the most actions rendered on any one row.

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
| **`/partners`** | 8 | 2 | **bordered + ghost** | ✗ |
| **`/broadcast_announcements`** | 1 | 2 | **filled + danger** | ✗ |
| **`/admin/organizations`** | 3 | 2 | **bordered + danger** | ✗ |
| **`/admin/users`** | 5 | 2 | **bordered + filled** | ✗ |
| **`/admin/base_items`** | 47 | 2 | **bordered + filled** | ✗ |
| **`/admin/partners`** | 7 | 2 | **bordered + filled** | ✗ |
| **`/admin/broadcast_announcements`** | 1 | 2 | **filled + danger** | ✗ |

**17 conform, 7 do not.** The convention is not in doubt; these are the exceptions to it.

### Why the seven deviate

Six of the seven are not a styling choice at all. They still call the legacy `UiHelper`
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

The dominant pattern is already the right one. Twelve tables badge **only the exception** and
attach it to the name rather than giving it a column:

| Table | Badges | When |
| --- | --- | --- |
| `/items`, `/vendors`, `/storage_locations`, `/donation_sites`, `/kits` | "Inactive" | only when inactive |
| `/broadcast_announcements`, `admin/…` | "Expired" | only when expired |
| dashboard low inventory, item inventory rows | "Below minimum" | only when below |

Five tables badge **every row**. Only `/partners` is an index page the script visits; the
other four were found by reading the row partials, and are reached from a partner's or a
group's page rather than from a top-level list:

| Table | Badges per row | Distinct badge kinds |
| --- | --- | --- |
| `/partners` | 1, always | 6 (one per status) |
| `partner_users/_users` | up to 2 | 3 (Accepted / Waiting acceptance / Never) |
| `partners/_partner_groups_table` | 1, always | 3 (Yes / No / No items requestable) |
| `distributions/_pickup_day_row` | 1, always | 2 (Complete / Scheduled) |
| `partners/children/_list` | 1, always | 2 (Active / Inactive) |

### `/partners` specifically

Measured on the seeded org: **6 rows, 6 row badges, plus a 7-badge filter strip = 13 badges on
one screen.** At a realistic 100 partners it is 107. Two problems, and the second is the one
that matters:

1. Every row is badged, including the majority "Approved" state.
2. **The filter strip and the status column share a visual language.** The strip in
   `_statuses.html.erb` builds its chips from `EssentialsUiHelper::PILL_TONES` — literally the
   status palette — so a control that filters the list and a badge that reports a row's state
   are the same shape, size and colour. design.md says a pill is a state and "does not look
   pressable"; here half of them are links. A reader cannot tell by looking which pills do
   something.

## Two further inconsistencies found while auditing

- **The same concept is rendered two ways.** Invitation status is plain text in
  `users/_organization_user.html.erb` (`<td><%= user.invitation_status %></td>`) and three
  coloured pills in `partner_users/_users.html.erb`.
- **A partner in `recertification_required` has no row action, and that is correct.** The
  `case status` in `_partner_row.html.erb` covers the other five statuses and falls through for
  this one, which looks like an oversight and is not. While a partner is in this state the bank
  has genuinely nothing to do: `Partner#approvable?` is `invited? || awaiting_review?`, so the
  show page offers no "Approve partner" either, and
  `PartnerRequestRecertificationService#valid?` refuses to run against a partner already in the
  state, so the request cannot be re-sent. The ball is with the partner until they resubmit,
  which moves them to `awaiting_review` and the row grows a "Review profile" button.

  Worth knowing rather than fixing. If a nudge is ever wanted — `invited` has "Re-send invite"
  for the same "waiting on the partner" situation — it needs a service change first, not a view
  change.

## Not recommended

**Do not move row actions behind an overflow menu.** Industry practice says three or more
actions belong behind "…", and `/distributions` renders four. It is still the wrong trade here:
this app is used by warehouse staff processing a list, the actions are the job rather than an
occasional detour, and hiding "Print" behind a menu costs a click on every row. `/users` already
records why its dropdown was removed in the migration. Revisit if a table reaches five.

## Verifying

`bin/design/table-audit.js` visits all 27 index tables in a real browser, reports the weights
and badge counts per table, and exits non-zero if any table uses more than one weight. Against
a seeded development server it currently reports:

```
tables audited:            27
more than one weight:      7  /partners /broadcast_announcements /admin/organizations
                              /admin/users /admin/base_items /admin/partners
                              /admin/broadcast_announcements
filled button in a row:    6  /broadcast_announcements /admin/organizations /admin/users
                              /admin/base_items /admin/partners /admin/broadcast_announcements
badge on every row:        1  /partners
```

```bash
bin/start                      # then, with the app running:
pw bin/design/table-audit.js

# The source-level version: table views still calling the legacy filled-button helpers.
# Currently 9, all listed above.
grep -rlE '(view|edit|delete|deactivate|reactivate|invite)_button_to' app/views/ |
  xargs grep -l '<td'
```

The static check and the browser check answer different halves. A grep finds the legacy helper
calls; only the browser shows what variant they resolved to, which is the thing a user sees.
