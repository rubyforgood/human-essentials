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

| Mockup | Question it was made to answer | Outcome |
| --- | --- | --- |
| `page-actions-options.html` | Where does a tab's action belong, and how many buttons may a page header carry? | **Option A chosen**: tabs became real URLs and the primary action follows the tab. |
| `reports-options.html` | How much should a reports hub card carry, and what does an index page look like once its summary report is folded into it? | **V2 chosen**, without the per-row icons; `<tfoot>` totals dropped. Built on `design-preview-reports-hub`. |
| `date-picker-options.html` | The Litepicker popup looks foreign to the app. What is the industry-standard simple date range picker for the design system? | **Option B chosen**, keeping the wire format: a preset `<select>` with two native date inputs behind "Custom". Litepicker and its two CDN pins removed. |
