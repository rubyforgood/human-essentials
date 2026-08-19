# View audit

Every view, by page kind, checked against the design system. Re-run with:

```bash
ruby bin/design/page-audit.rb            # everything
ruby bin/design/page-audit.rb show       # one kind: show, index, form, partial
```

It exits non-zero if any **defect** is found. **Debt** is reported but not enforced.

`status.rb` asks whether a view contains design system markup. Every page here does, which is
why it reports them all as migrated. **The layout is not the page**: a view can sit in the right
shell and still build its own header, its own card and its own inputs.

Excluded: `shared/essentials/*` (the components are the definition, not a copy), mailer
templates (inline style is the only option in an email client), and `static/*` (standalone
public documents on their own stylesheet, deliberately outside the system — see
[migration-map.md](migration-map.md)).

## Two severities

| | Meaning |
| --- | --- |
| **DEFECT** | Wrong now. A class nothing defines, a hardcoded inline style, layout built from `&nbsp;`, Title Case where the house style is sentence case, or no `page_header` and therefore no back link. |
| **debt** | Renders correctly, but the card's classes are pasted inline instead of rendering the component, so a change to the card can never reach it. Also AdminLTE comments — inert, and a reliable marker of a view nobody has revisited. |

## Current state

```
== show (31 files, 0 with defects, 0 debt only)

== index (43 files, 13 with defects, 0 debt only)
  DEFECT  admin/barcode_items/index.html.erb                   Title Case: Barcode Items; no page_header; hand-rolled card; 1 AdminLTE comment
  DEFECT  admin/base_items/index.html.erb                      Title Case: All Base Items; no page_header; hand-rolled card; 1 AdminLTE comment
  DEFECT  admin/broadcast_announcements/index.html.erb         Title Case: Broadcast Announcement; no page_header; hand-rolled card; 2 AdminLTE comments
  DEFECT  admin/ndbn_members/index.html.erb                    no page_header; hand-rolled card; 4 AdminLTE comments
  DEFECT  admin/organizations/index.html.erb                   Title Case: All Human Essentials Organizations; no page_header; hand-rolled card; 1 AdminLTE comment
  DEFECT  admin/partners/index.html.erb                        no page_header; hand-rolled card; 1 AdminLTE comment
  DEFECT  admin/users/index.html.erb                           no page_header; hand-rolled card; 1 AdminLTE comment
  DEFECT  broadcast_announcements/index.html.erb               Title Case: Broadcast Announcement; no page_header; hand-rolled card; 2 AdminLTE comments
  DEFECT  events/index.html.erb                                Title Case: History Filter; no page_header; hand-rolled card; 5 AdminLTE comments
  DEFECT  partner_users/index.html.erb                         no page_header
  DEFECT  partners/requests/index.html.erb                     Title Case: Essentials Requests; no page_header; 1 AdminLTE comment
  DEFECT  reports/annual_reports/index.html.erb                no page_header; hand-rolled card
  DEFECT  users/index.html.erb                                 no page_header; hand-rolled card; 1 AdminLTE comment

== form (98 files, 0 with defects, 0 debt only)

== partial (157 files, 30 with defects, 9 debt only)
    debt  admin/questions/_question_form.html.erb              hand-rolled card; 3 AdminLTE comments
    debt  admin/users/_roles.html.erb                          hand-rolled card; 3 AdminLTE comments
  DEFECT  events/_snapshot_event_row.html.erb                  1 inline style; 3 &nbsp;
    debt  help/_bank_questions.html.erb                        hand-rolled card
  DEFECT  items/_item_row.html.erb                             1 &nbsp;
  DEFECT  organizations/_details.html.erb                      Title Case: Annual Survey; hand-rolled card
  DEFECT  partner_users/_users.html.erb                        1 inline style; hand-rolled card
  DEFECT  partners/profiles/edit/_agency_distribution_information.html.erb Title Case: Agency Distribution Information; hand-rolled card
    debt  partners/profiles/edit/_agency_information.html.erb  hand-rolled card
  DEFECT  partners/profiles/edit/_agency_stability.html.erb    Title Case: Agency Stability; hand-rolled card
  DEFECT  partners/profiles/edit/_area_served.html.erb         1 inline style; Title Case: Area Served; hand-rolled card
  DEFECT  partners/profiles/edit/_attached_documents.html.erb  Title Case: Additional Documents; hand-rolled card
    debt  partners/profiles/edit/_contacts.html.erb            hand-rolled card
  DEFECT  partners/profiles/edit/_media_information.html.erb   1 &nbsp;; Title Case: Media Information; hand-rolled card
  DEFECT  partners/profiles/edit/_organizational_capacity.html.erb Title Case: Organization Capacity; hand-rolled card
  DEFECT  partners/profiles/edit/_partner_settings.html.erb    3 &nbsp;; hand-rolled card
  DEFECT  partners/profiles/edit/_pick_up_person.html.erb      Title Case: Pick Up Person; hand-rolled card
  DEFECT  partners/profiles/edit/_population_served.html.erb   Title Case: Poverty Information; hand-rolled card
    debt  partners/profiles/edit/_sources_of_funding.html.erb  hand-rolled card
  DEFECT  partners/profiles/show/_agency_distribution_information.html.erb Title Case: Agency Distribution Information; hand-rolled card
  DEFECT  partners/profiles/show/_agency_information.html.erb  Title Case: Agency Information; hand-rolled card
  DEFECT  partners/profiles/show/_agency_stability.html.erb    Title Case: Agency Stability
  DEFECT  partners/profiles/show/_area_served.html.erb         Title Case: Area Served; hand-rolled card
  DEFECT  partners/profiles/show/_attached_documents.html.erb  Title Case: Attached Documents; hand-rolled card
  DEFECT  partners/profiles/show/_contacts.html.erb            Title Case: Executive Director; hand-rolled card
  DEFECT  partners/profiles/show/_media_information.html.erb   Title Case: Media Information; hand-rolled card
  DEFECT  partners/profiles/show/_organizational_capacity.html.erb Title Case: Organizational Capacity
  DEFECT  partners/profiles/show/_pick_up_person.html.erb      Title Case: Pick Up Person; hand-rolled card
  DEFECT  partners/profiles/show/_population_served.html.erb   Title Case: Population Served
    debt  partners/profiles/show/_sources_of_funding.html.erb  hand-rolled card
    debt  partners/profiles/step/_accordion_section.html.erb   hand-rolled card
  DEFECT  partners/profiles/step/_area_served_form.html.erb    1 inline style
  DEFECT  partners/profiles/step/_attached_documents_form.html.erb 1 inline style
  DEFECT  partners/profiles/step/_media_information_form.html.erb 1 &nbsp;
  DEFECT  partners/profiles/step/_partner_settings_form.html.erb 3 &nbsp;
  DEFECT  partners/requests/_history.html.erb                  Title Case: Request History
  DEFECT  profiles/_show.html.erb                              Title Case: Agency Information
  DEFECT  storage_locations/_storage_location_row.html.erb     1 &nbsp;
    debt  users/_organization_users_table.html.erb             hand-rolled card

43 files with defects, 9 with debt only
```

## Done

| Batch | Pages | Notes |
| --- | --- | --- |
| Form pages: partner portal, admin, bank-side | 40 | Cleared 2026-08-19. |
| Show pages | 9 | Cleared 2026-08-19. |

## What an audit cannot see

Every batch turned up something a class-name scan cannot find. All of it was obvious within
seconds of opening the page in a browser, which is why each page was opened as it was rewritten.

| Page | Found |
| --- | --- |
| `partners/families/_form`, `profiles/edit`, `partners/requests/new`, `partners/individuals_requests/new` | Divs did not balance. The browser recovered by splitting one form into two, leaving the submit button outside the fields. They worked, by the parser's error recovery. |
| `partners/families/show` | A `<tr>` that was never closed, and ten `style="width: …%"` attributes whose percentages summed to more than 100 in both tables. |
| `partners/children/show` | Five `<td>` elements closed with `</th>`. |
| `reports/annual_reports/show` | One `<h1>` per report section, inside a loop — a page could carry a dozen. |
| `admin/organizations/new` | A second `<h1>` inside the form. |
| `admin/partners/show` | An empty `<h2>` as the card header. |
| `partners/children/_form` | A stray `intersect?` expression printing `true` onto the page. |
| `admin/base_items/new` | Card header read "Update «name»" on a page for creating a record, where the name is blank. |
| `users/registrations/edit` | An empty `<button>` — a collapse toggle whose AdminLTE JavaScript is gone. |
| `organizations/edit` | An inline `<style>` block restyling `trix-editor` with hardcoded hex, duplicating the vendored stylesheet. |
| `partner_groups/_form` | `text-bold`, which Tailwind does not define — the author meant `font-bold`, so that heading was never bold. |
| `partners/requests/show` | Field labels at `text-2xl font-bold` above values at `text-lg`: every label larger than the thing it labelled. |

## One regression, caught by the suite

Replacing the header on `users/registrations/edit` dropped the staging warning with it — a
user-facing notice, not styling. `spec/system/account_system_spec.rb` caught it. Restored as a
proper alert, keeping the `.staging-warning` hook. **Read what is inside a block before swapping
it wholesale.**

## Fixing a page

1. `shared/essentials/page_header` with `back:` — most of these had no way back but the browser button.
2. `render "shared/essentials/card"` rather than the card's classes pasted inline.
3. Delete classes nothing defines. Fix `text-bold` to `font-bold`, or use the heading token.
4. Sentence case the headings, labels and submit buttons.
5. A `<dl>` for field/value pairs, styled — not a bare one, and not a one-row table.
6. **Load the page.** `form.contains(submitButton)` and a count of fields outside the form catch
   the whole unbalanced-markup class; a class-name audit catches none of it.
