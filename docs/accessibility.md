# Accessibility

Audited 2026-08-19. **WCAG 2.1 A/AA: 0 violations across 61 pages**, by axe-core 4.13.0, plus
eight criteria axe cannot test, checked by driving a browser.

## Running it

```bash
npm install --no-save --prefix /tmp/axe axe-core   # once
bin/start                                          # then, with the app running:

pw bin/design/wcag-audit.js       # axe-core, WCAG 2.1 A/AA, 61 pages, all four roles
pw bin/design/wcag-manual.js      # the criteria axe cannot check
pw bin/design/overlay-audit.js    # opens every dialog and popover, then checks them
bundle exec rspec spec/system/accessibility_system_spec.rb
```

All three scripts exit non-zero on a failure. `wcag-audit.js` groups by rule rather than by page,
because a rule broken on thirty pages is one fix and not thirty.

## What each tool covers

| | Covers | Does not |
| --- | --- | --- |
| `wcag-audit.js` (axe) | Names, roles, contrast, labels, landmarks, list structure, heading order | Whether alt text is *good*, whether a heading describes its section, whether an order makes sense |
| `wcag-manual.js` | 1.4.4, 1.4.10, 1.4.12, 2.1.1, 2.4.1, 2.4.2, 2.4.7, 3.1.1 | Anything needing judgement |
| `overlay-audit.js` | Dialogs and popovers **opened**: centring, viewport fit, accessible name, Escape, focus return, surface, plus axe on the opened overlay | Overlays it has no page in its list for |
| `accessibility_system_spec.rb` | The four fixes that regressed silently before | Everything else |

**An audit only sees the state it puts the page in.** Every dialog in this app opened in the
top-left corner for as long as both audits existed, because one reads markup and the other scans
the page as loaded, and neither had ever clicked a trigger. `overlay-audit.js` exists for that
reason, and the same question is worth asking of any new check: what state does it never reach?

axe finds roughly a third to a half of WCAG issues. **Zero violations is a floor, not a
certificate.** Screen reader testing, and testing with the people who use this app, are not
replaced by any of the above.

## What the audit found, and why each one existed

| Violation | Elements | Cause |
| --- | --- | --- |
| `label` (1.3.1, 4.1.2) | 11 | Two radios whose labels pointed at `for="account"`, which is neither radio. Seven checkboxes where an explicit `id` on the input lost the object prefix that `f.label` puts in `for`. select2's own search field, which inherits no name. |
| `color-contrast` (1.4.3) | 5 | FullCalendar dims other-month days with `opacity: 0.3`, putting slate-900 over white at **1.96:1**. |
| `definition-list` / `dlitem` (1.3.1) | 3 | Two `<address>` elements and two `<p>` sub-headings sitting directly inside a `<dl>`, and a `<dt>`/`<dd>` pair with no `<dl>` around them at all. |
| `select-name` (4.1.2) | 1 | A wrapping `f.input` generated `for="organization_ndbn_member"` against a select whose id is `organization_ndbn_member_id`. |
| `svg-img-alt` (1.1.1) | 1 | Highcharts renders `<svg role="img">` with no accessible name. |
| `aria-input-field-name` (4.1.2) | 1 | A bare `rich_text_area` renders a `trix-editor` with `role=textbox` and no name. |
| `region` (best practice) | 3 | The auth layout's brand panel was the only content outside a landmark. |

Found by the interaction checks, which axe cannot see:

| Criterion | Cause |
| --- | --- |
| 2.1.1 Keyboard | Trix ships 14 toolbar buttons at `tabindex="-1"` with no role and no arrow handling. Bold, italic and link have shortcuts; headings, quotes, code, both list types, indent, outdent and attach had no keyboard route at all. |
| 2.4.7 Focus visible | Those buttons, once reachable, had no focus indicator — Trix sets `outline: none` and ships no focus style. |
| 1.4.10 Reflow | `<fieldset>` defaults to `min-width: min-content` and refuses to shrink, pushing 61px of the settings form outside a card with `overflow-hidden` at 320px, where it was clipped. Introduced by grouping fields in fieldsets. |
| 1.4.10 Reflow | select2 defaults to `width: 'resolve'`, writing a pixel width once and never updating it: 662px inside a 550px parent. |

## Two things the cascade taught us

Both fixes needed a rule to beat a third-party stylesheet, and the remedies differ:

- **Trix** is imported into `application.css`. Raising specificity inside `@layer components` had
  no effect at all, because **an unlayered rule beats a layered one however specific the layered
  one is**. Moving the rule out of the layer fixed it.
- **FullCalendar** injects its stylesheet into `<head>` at runtime — unlayered *and* later in
  source order than anything this file can emit. That one needs `!important`, and it is the only
  `!important` in the stylesheet. Tested both ways.

There is now a "Third-party overrides" section at the end of `application.css`, deliberately
outside every layer, with that reasoning in a comment.

## Dead classes found while auditing

`deadline_day_controller.js` toggled `text-muted` and `text-danger` to signal an invalid reminder
schedule. Tailwind defines neither, so **the error state had been rendering as nothing**. Now
`text-slate-500` and `text-rose-700`.

Four partner profile partials carried `class="mb-4 card"`. `card` is defined nowhere, so those
four cards had no border, background or shadow while their siblings did. `bin/design/page-audit.rb`
now catches a bare `card`.

## Judgement calls

- **`autofocus` removed from the two long organization forms**, kept on short single-purpose ones.
  Focus starting inside the form puts it past the skip link, so a keyboard user cannot Tab forward
  to bypass the navigation. On a sign-in form autofocus earns that; on an eight-section settings
  page it does not.
- **The auth brand panel became a `<header>`** rather than being hidden from assistive technology.
  Hiding it would have been easier and worse: it is real content, and a sighted user gets it.
- **Charts get a name, not a description.** `aria-label` says what the chart is. Every chart here
  sits beside a table of the same figures, which is the alternative that carries the data. A
  per-chart summary sentence is still in the design.md backlog.

## False alarms worth knowing about

Three findings were the checks being naive, not the app:

- **`tabindex="-1"` on ARIA tabs and toolbar buttons is correct.** A roving-tabindex group keeps
  one tab stop and moves with arrow keys. Reporting the other thirteen as unreachable is wrong.
- **select2 sets `tabindex="-1"` on the original `<select>`** and provides its own focusable proxy.
- **`documentElement.scrollWidth` counts the content of a clipped scroll container.** A data table
  inside `overflow-x: auto` reported hundreds of pixels of page overflow that nothing could scroll
  to. `html { overflow-x: hidden }` not changing the number is the tell. `body.scrollWidth` and an
  actual scroll attempt agree with each other and with the screen; the checks use those.
