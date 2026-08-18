# Form page audit — new, edit and form partials

Audited 2026-08-18. 98 pages matching `new.html.erb`, `edit.html.erb` or `_form.html.erb`;
**40 carry at least one finding**.

These pages render on a design system layout, which is why the migration reported them as done.
The layout is not the page: a view can sit inside the correct shell and still build its own
header, its own card and its own inputs. That is what most of these do.

Devise views are judged against the auth layout, which has no page header bar — a plain `<h1>`
carrying the design system's own classes is correct there and is not counted as a finding.

## What each finding means

| Finding | Why it matters |
| --- | --- |
| **dead class** | `form-horizontal`, `text-bold`, `form-group` and friends are defined nowhere. `text-bold` is the one that bites: the author meant `font-bold`, so the heading is not bold and never has been. |
| **no page_header** | The page builds its own `<h1>` block. Spacing, the back link and the actions slot then drift per page, which is the thing `page_header` exists to stop. |
| **hand-rolled card** | The card's classes are pasted inline instead of rendering `shared/essentials/card`, so a change to the card does not reach it. |
| **AdminLTE comment** | `<!-- left column -->`, `<!-- jquery validation -->`, `<!-- form start -->` — scaffolding from a framework that is gone. Harmless, and a reliable marker of a view nobody has revisited. |
| **Title Case** | design.md specifies sentence case for everything a person reads. |

## Findings

| Page | Dead class | No page_header | Hand-rolled card | AdminLTE comments | Title Case |
| --- | --- | --- | --- | --- | --- |
| `account_requests/new.html.erb` | `text-bold` | — | yes | — | Essentials Bank Account Request Form |
| `admin/barcode_items/_form.html.erb` | — | — | yes | 3 | — |
| `admin/barcode_items/edit.html.erb` | — | yes | — | — | Editing Barcode Item |
| `admin/barcode_items/new.html.erb` | — | yes | — | — | New Barcode Item |
| `admin/base_items/edit.html.erb` | `form-horizontal` | yes | yes | 3 | Editing Base Item |
| `admin/base_items/new.html.erb` | `form-horizontal` | yes | yes | 3 | New Base Item |
| `admin/broadcast_announcements/_form.html.erb` | `form-horizontal` | — | yes | 3 | — |
| `admin/broadcast_announcements/edit.html.erb` | — | yes | — | — | Edit Broadcast Announcement |
| `admin/broadcast_announcements/new.html.erb` | — | yes | — | — | Send Broadcast Announcement |
| `admin/organizations/edit.html.erb` | — | yes | yes | 3 | — |
| `admin/organizations/new.html.erb` | — | yes | yes | 3 | New Organization |
| `admin/partners/edit.html.erb` | — | yes | yes | 3 | Updating Partner Information |
| `admin/questions/edit.html.erb` | — | yes | — | — | Edit This |
| `admin/questions/new.html.erb` | — | yes | — | — | — |
| `admin/users/edit.html.erb` | — | yes | yes | 3 | Editing User |
| `broadcast_announcements/_form.html.erb` | `form-horizontal` | — | yes | 3 | — |
| `broadcast_announcements/edit.html.erb` | — | yes | — | — | Edit Broadcast Announcement |
| `broadcast_announcements/new.html.erb` | — | yes | — | — | Send Broadcast Announcement |
| `organizations/edit.html.erb` | — | yes | yes | 3 | — |
| `partner_groups/_form.html.erb` | `form-horizontal`, `text-bold` | — | yes | 3 | Which Item Categories Can They Request |
| `partner_groups/edit.html.erb` | — | yes | — | — | Updating Partner Group |
| `partner_groups/new.html.erb` | — | yes | — | — | New Partner Group |
| `partner_users/_form.html.erb` | — | — | yes | — | Invite New User |
| `partners/authorized_family_members/_form.html.erb` | `form-horizontal` | — | yes | 3 | — |
| `partners/authorized_family_members/edit.html.erb` | — | yes | — | — | Edit Authorized Family Member |
| `partners/authorized_family_members/new.html.erb` | — | yes | — | — | New Authorized Family Member |
| `partners/children/_form.html.erb` | `form-horizontal` | — | yes | 3 | — |
| `partners/children/edit.html.erb` | — | yes | — | — | Edit Child |
| `partners/children/new.html.erb` | — | yes | — | — | New Child |
| `partners/families/_form.html.erb` | `form-horizontal` | — | yes | 3 | — |
| `partners/families/edit.html.erb` | — | yes | — | — | Edit Family |
| `partners/families/new.html.erb` | — | yes | — | — | New Family |
| `partners/family_requests/new.html.erb` | — | yes | yes | — | Family Details |
| `partners/individuals_requests/new.html.erb` | `form-horizontal` | yes | yes | — | New Request |
| `partners/profiles/step/edit.html.erb` | — | yes | — | — | Edit My Organization |
| `partners/requests/new.html.erb` | `form-horizontal` | yes | yes | — | New Request |
| `profiles/edit.html.erb` | `form-horizontal` | yes | — | — | Editing Partner |
| `profiles/step/edit.html.erb` | `form-horizontal` | yes | — | — | Editing Partner |
| `users/registrations/edit.html.erb` | — | — | yes | — | — |
| `users/registrations/new.html.erb` | — | — | — | — | Contact Us |

## Where they cluster

Not evenly. Three groups account for most of it:

- **The partner portal's own forms** — families, children, authorized family members, requests.
  Every one has a hand-rolled card and `form-horizontal`.
- **The admin area** — base items, barcode items, organizations, partners, users, questions,
  announcements. The admin area was migrated last and least.
- **Bank-side forms reached from a tab or a dialog** rather than from a nav item: partner groups
  is the clearest case, which is how this audit started.

The pattern is that a page reached by a *secondary* route — a tab, a dialog, a link at the
bottom of another form — got less attention than a page with its own place in the sidebar.

## Fixing one

The shape is the same every time:

1. Replace the hand-rolled `<section>`/`<h1>` block with `shared/essentials/page_header`, adding
   `back:` — most of these have no way back except the browser button.
2. Replace the pasted card classes with `render "shared/essentials/card"`.
3. Delete `form-horizontal` and any other class nothing defines. Fix `text-bold` to `font-bold`
   or, better, use the heading token.
4. Sentence case the headings and the submit labels.
5. Delete the AdminLTE comments.

## Verifying

```bash
ruby bin/design/form-audit.rb        # re-runs this audit
bundle exec rspec spec/system        # the shell specs cover header structure
```
