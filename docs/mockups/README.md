# Mockups

Design proposals that were shown before anything was built. They are checked in because they
are the record of what was offered and chosen, and because this workspace has been reset out
from under the work more than once.

Each one loads the app's real stylesheet (`/assets/tailwind.css`), so it has to be served by the
app rather than opened from disk:

```bash
cp docs/mockups/<file>.html public/    # ignored by git; the tracked copy is the one here
# then open http://localhost:3000/<file>.html
```

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
| `date-picker-options.html` | The Litepicker popup looks foreign to the app. What is the industry-standard simple date range picker for the design system? | **Option B chosen**, keeping the wire format: a preset `<select>` with two native date inputs behind "Custom". Litepicker and its two CDN pins removed. |
| `showing-line-options.html` | `#date_range_label` produces a sentence fragment that nothing reads. Where should the sentence go, and is the fragment fit to build on? | **B + C chosen**: a sentence-case caption on the stats band and the period in the `:no_results` empty state, not a standalone line. Helper fixed first — five bugs, one of them the no-parameter default. |
| `summary-band-options.html` | The stats band orphans a tile, and its filled tiles float on the page in no container. One responsive card instead? | **Option B chosen**: one card, hairline separators drawn by a `gap-px` backdrop, column count following the figure count. Every row full at every breakpoint on all five pages. |
| `filters-and-summary-options.html` | Four questions: why filter controls are different widths and leave trailing white space; whether to auto-apply instead of a Filter button; what "recent and upcoming" means; and what subheader the summary card needs. | **All four recommendations built**, auto-filtering as option B: a grid bar, the preset renamed, a titled summary card with a scope sentence, and filters applied on change into a Turbo Frame. |
