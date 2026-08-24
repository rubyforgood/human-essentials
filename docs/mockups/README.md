# Mockups

Design proposals that were shown before anything was built. They are checked in because they
are the record of what was offered and chosen, and because this workspace has been reset out
from under the work more than once.

Each one loads the app's real stylesheet, so it has to be served by the app rather than opened
from disk:

```bash
cp docs/mockups/<file>.html public/          # ignored by git; the tracked copy is the one here
cp app/assets/builds/tailwind.css public/mockup.css
# then open http://localhost:3000/<file>.html
```

They link `/mockup.css`, a plain copy in `public/`, rather than `/assets/tailwind.css`. Since the
pipeline became Propshaft (ADR 0012) the undigested asset path 404s — only
`/assets/tailwind-<digest>.css` resolves, and that digest changes on every rebuild. A mockup that
links it would silently render unstyled, which is how all nine of these were found: the heading
font had fallen back to Times New Roman.

Two traps in that arrangement, both of which have produced a mockup that lied:

- **Re-copy `mockup.css` after every Tailwind rebuild.** It is a snapshot, not a link. A mockup
  opened against a stale copy renders with the classes the app had at copy time — which is how
  a `text-slate-300` on a disabled control came out slate-600, silently, in a panel whose whole
  point was showing a disabled control.
- **A mockup can only use utility classes the app already uses somewhere.** Tailwind does not
  scan `docs/mockups/` or `public/`, so a class no view uses is not in the stylesheet at all. If
  a mockup proposes *new* styling, write the rule out in the mockup's own `<style>` block,
  exactly as it would appear in `application.css`. That is more honest anyway: it shows the rule
  being proposed rather than borrowing something that happens to look similar.

If a mockup shows responsive behaviour with an `<iframe srcdoc="...">`, **escape `<` and `>` in
the payload as well as the quotes**. rack-mini-profiler injects its script tag at the first
`</body>` in the response, and an unescaped one inside the attribute means it injects *there* --
its own quotes then terminate the attribute, and everything after it, including the width, is
swallowed. Two of the three iframes in `summary-band-options.html` silently fell back to
Chromium's default 300px that way.

| Mockup | Question it was made to answer | Outcome |
| --- | --- | --- |
| `page-actions-options.html` | Where does a tab's action belong, and how many buttons may a page header carry? | **Option A chosen**: tabs became real URLs and the primary action follows the tab. |
| `reports-options.html` | How much should a reports hub card carry, and what does an index page look like once its summary report is folded into it? | **V2 chosen**, without the per-row icons; `<tfoot>` totals dropped. Built on `design-preview-reports-hub`. |
| `date-picker-options.html` | The Litepicker popup looks foreign to the app. What is the industry-standard simple date range picker for the design system? | **Option B chosen**, keeping the wire format: a preset `<select>` with two native date inputs behind "Custom". Litepicker and its two CDN pins removed. Later: the Apply button was removed, out-of-order dates reorder themselves, and the trigger shows US short dates. |
| `showing-line-options.html` | `#date_range_label` produces a sentence fragment that nothing reads. Where should the sentence go, and is the fragment fit to build on? | **B + C chosen**: a sentence-case caption on the stats band and the period in the `:no_results` empty state, not a standalone line. Helper fixed first — five bugs, one of them the no-parameter default. |
| `summary-band-options.html` | The stats band orphans a tile, and its filled tiles float on the page in no container. One responsive card instead? | **Option B chosen**: one card, hairline separators drawn by a `gap-px` backdrop, column count following the figure count. Every row full at every breakpoint on all five pages. |
| `filter-density-options.html` | The date range cell is twice the width of its neighbours and the actions take a row of their own. Should a dense filter set collapse? | **Option C chosen**, threshold five, with the date range narrowed to one column rather than made conditional. `/donations` went 264px to 38px. |
| `pagination-options.html` | Which tables should paginate, and how many rows? | **Option B chosen** — three bands by measured row height. Recorded that `items` computes pagination and never renders it (6,442px page), and that row heights vary 4.5× so one page size cannot serve every table. |
| `pagination-designs.html` | The system already has a pager. What else would fit it, and does the pager say the right thing? | **Option A chosen**: the numbered pager stays and the label became "Showing 31–45 of 272 requests". `« First` and `Last »` kept, which the A panel had dropped — see `design.md` for why. A rows-per-page select and load-more were both argued against and not built. |
| `pagination-count-options.html` | A table that fits on one page shows no count at all, and the control set reflows as you page. What is the convention? | **Option A chosen**, with Stripe's control set: the strip always renders, Prev and Next are always there and disabled when they lead nowhere, First and Last only when there is more than one page. Found two passing bugs on the way — a model name that would not pluralise, and a spec whose "no organizations" context had one. |
| `filter-consistency-options.html` | Two bugs (every modal opens top-left; Calculate product totals is inside the filter bar), plus: should the disclosure threshold go, how does industry take a custom date range, and are two Clears needed? | **All built.** Both bugs fixed, the threshold and the second Clear deleted, and the date range rebuilt as a popover on a shared `popover` controller. `bin/design/overlay-audit.js` added, because neither existing audit had ever opened an overlay. |
| `filters-and-summary-options.html` | Four questions: why filter controls are different widths and leave trailing white space; whether to auto-apply instead of a Filter button; what "recent and upcoming" means; and what subheader the summary card needs. | **All four recommendations built**, auto-filtering as option B: a grid bar, the preset renamed, a titled summary card with a scope sentence, and filters applied on change into a Turbo Frame. |
| `line-item-row-options.html` | The "Items in this donation" row has three different control heights and no columns. How many columns should the card have, what should the barcode and remove affordances be, and is there a better shape for the row? | **Option C chosen and built**, after the select2 box fix it depended on. One scan bar per card instead of one per row, headings once, an icon-only remove, a running total; 58px a row against 96px, stacking below `sm`. All seven line item forms render one partial. |
