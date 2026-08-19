# View audit

Cleared 2026-08-19. **329 views, 0 defects.** Three hand-rolled cards remain as debt, each with a
reason below.

```
== show     (31 files,  0 defects, 0 debt)
== index    (43 files,  0 defects, 0 debt)
== form     (98 files,  0 defects, 0 debt)
== partial  (157 files, 0 defects, 3 debt)
```

Re-run with `ruby bin/design/page-audit.rb [show|index|form|partial]`. It exits non-zero on a
defect; debt is reported and not enforced.

`status.rb` asks whether a view contains design system markup. Every page here does, which is why
it reported them all as migrated. **The layout is not the page.**

Excluded: `shared/essentials/*` (the components are the definition), mailer templates (inline
style is the only thing email clients honour), and `static/*` (deliberately outside the system).

## The three remaining, and why

| Partial | Why the card component does not fit |
| --- | --- |
| `help/_bank_questions` | The card's header is a disclosure button, not a title. `title:` takes text. |
| `partners/profiles/step/_accordion_section` | Same: the header is the accordion trigger. |
| `organizations/_details` | An admin-only edit button renders above the header, so the card has content before its title. |

Passing `title: capture { button }` would satisfy the audit and make the markup worse. They are
recorded rather than forced.

## Two severities

| | Meaning |
| --- | --- |
| **DEFECT** | Wrong now: a class nothing defines, a hardcoded inline style, layout built from `&nbsp;`, Title Case, or no `page_header` and so no back link. |
| **debt** | Renders correctly, but the card's classes are pasted inline so a change to the card cannot reach it. |

Two exemptions the audit learned along the way: an `&nbsp;` inside `sr-only` prose is a word
separator, not layout — without it a screen reader runs "Deactivate" into the explanation after
it. And a class name inside an ERB comment is not rendered, so a comment saying a class was
removed must not be reported as the class being present.

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
