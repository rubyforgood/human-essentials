# Every instruction given on this project

**199 prompts, 22 August – 2 September 2026, across three sessions.** This is the demand side of the
design-system migration: what was actually asked for, in the order it was asked.

## How this was collected

Read out of the Claude Code transcripts for this repository —
`2c8f34a3` (22–26 Aug, 62 prompts), `1eb39daf` (25–28 Aug, 44), `594c391c` (28 Aug – 2 Sep, 93) —
taking only records that are a person typing. Tool results, system reminders, hook output,
compaction summaries and three stray task notifications were excluded; nothing else was.

**What was changed:** spelling, punctuation, sentence boundaries, and the dictation artefacts
("Syed NAV" for *side nav*, "Moodle" for *modal*, "force" for *parse*, "next year refers to" for
*next to Refers to*). Where a prompt pasted text back from a previous reply, the quoted part is kept
but marked.

**What was not changed:** the ask, the scope, the reasoning, the order of clauses, and the tone. A
prompt that was blunt is still blunt. A prompt that asked four unrelated things still asks four
unrelated things — that turned out to be a characteristic of the workflow, not noise.

Each entry is tagged with its original position and date, so `[121 · 28 Aug]` can be found in the
transcript.

## What the shape of it says

| | Category | Count |
| --- | --- | ---: |
| A | [Reporting a defect found by using the app](#a-reporting-a-defect-found-by-using-the-app) | 79 |
| B | [Choosing between presented options](#b-choosing-between-presented-options) | 56 |
| C | [Asking for research and a preview before building](#c-asking-for-research-and-a-preview-before-building) | 23 |
| D | [Ordering an app-wide consistency sweep](#d-ordering-an-app-wide-consistency-sweep) | 11 |
| E | [Verification, testing and CI](#e-verification-testing-and-ci) | 14 |
| F | [Copy and language](#f-copy-and-language) | 9 |
| G | [Setup, environment and access](#g-setup-environment-and-access) | 11 |
| H | [Documentation and memory discipline](#h-documentation-and-memory-discipline) | 5 |
| I | [Rigour and prevention](#i-rigour-and-prevention) | 3 |
| J | [Safety and recovery](#j-safety-and-recovery) | 3 |

The rows sum to 214 rather than 199 because fifteen prompts are listed under two categories — a
report that is also a sweep, a choice that is also a documentation order. Every one of the 199 is
listed at least once.

Categories are assigned by the prompt's *primary* demand. Most prompts do more than one thing — a
typical one reports a defect, asks what the industry does, asks for a preview, and orders a sweep,
in one breath. That compounding is the most distinctive feature of the set and is why the counts
below understate C and D in particular.

Three observations that matter more than the counts:

**Almost every defect was found by looking at the running app, not by reading code.** "On the
purchases page, the comments column increases the height of the row exponentially." The reports are
visual, specific to a page, and frequently include a guess at the cause. Nothing in this set came
from a bug tracker.

**The same five demands recur in almost every substantive prompt**: what does the design system say,
what does the industry do, show me a preview before you build, apply it everywhere, and write the
decision down. Those five are the process, and they were repeated because they were repeatedly not
followed.

**The last eight prompts are about the tools rather than the app.** Once the screens were right the
attention moved to whether the checks could be trusted — "why did this get missed by previous
audits", "how can this be caught earlier", "add the selftest to CI". That progression from product
to process is the arc of the project.

---

<a id="a-reporting-a-defect-found-by-using-the-app"></a>
## A. Reporting a defect found by using the app

The dominant mode: open a page, find something wrong, describe it precisely, usually with a question
about why it is that way.

### Layout, spacing and alignment

- `[2 · 22 Aug]` The avatar menu does not need to show the user's name — just the avatar with
  initials. Check the design system for the convention.
- `[11 · 23 Aug]` On the dashboard, in the announcement section, the icon is in the body of the card
  rather than the header. Check the design system and industry standard for the convention.
- `[12 · 23 Aug]` *(quoting my own note back)* "Not what you asked about, and it may be deliberate
  for a compact grid card, but it's the kind of thing that drifts." — Yes, fix this.
- `[14 · 23 Aug]` Required fields have an asterisk with three dots below it. Update it to the design
  system convention, which is the red asterisk. Audit and update across the app. Remove the helper
  text at the top of the page about required fields — the red `*` is the convention, and the text is
  pushing the card far down the screen.
- `[95 · 27 Aug]` Under Items & Inventory for "New item", under Kits for "New kit" and so on, those
  pages are left-aligned but do not span the page. Check the design system for alignment; it should
  be centred per industry standard.
- `[98 · 27 Aug]` The card is left-aligned. Look at the design system to see whether it should be
  centred in the space, and make a recommendation.
- `[105 · 28 Aug]` The scroll bar is very dark. When the user scrolls to the bottom of the page it
  hovers oddly. It has no padding above the pagination, and no border radius, so it does not match
  the rest of the components.
- `[107 · 28 Aug]` There is still an issue with it sticking to the pagination component — no padding
  between the scroll bar and pagination when you reach the bottom of the screen.
- `[108 · 28 Aug]` Now there is too much padding between the pagination component and the scroll
  bar. It needs to match the padding below pagination.
- `[109 · 28 Aug]` Under Items & Inventory for "New item", under Kits for "New kit" and so on, the
  button is nested inside the card with a divider separating them. Check the design system for the
  pattern — this does not look right.
- `[118 · 28 Aug]` Do that sweep for the other shell-first migrated pages. Also, there is too much
  space between the header and the card — measure what it is supposed to be from the design system.
  And the users table was not migrated. **This is really frustrating. Why do I need to point out
  elements individually on the same page?** The button is not in the right location either.
- `[119 · 28 Aug]` The Annual Survey section does not have enough padding at the bottom of the
  table.
- `[120 · 28 Aug]` The organization settings edit page has issues: too much padding below the helper
  deck and above the card; a divider line that begins at the end of the subheader text, which is not
  a pattern; radio button options without enough spacing. Check industry standard and the design
  system for all of it. "Deadline in a day" reminder email has a word truncated and cut off — looks
  like a bug. The rich text editor does not match the rest of the page stylistically; if one does not
  exist in the design system, design one that matches visually, based on industry standard, and add
  it. Does the icon on that button match the convention for the rest of the app?
- `[121 · 28 Aug]` Address inputs are not formatted the way addresses are elsewhere, they span the
  full width of the card, and there is no padding below the Save button. Do all CTA buttons have
  leading icons? Audit the entire app for consistency. The custom requests field with the chips is
  not intuitive — show me design previews with options. There is now far too much padding between
  the radio options; what is industry standard? What are the odd squares underneath "additional
  text" for the reminder email and distribution email content? That looks like a bug. This helper
  text too: "You can use %{partner_name} to include the partner's name."
- `[143 · 29 Aug]` The location and size of the shipping cost field make no sense. It should match
  the three-column width of the other inputs. Shouldn't it sit below the shipping cost radio button?
  What is industry standard for progressive disclosure like this?
- `[149 · 30 Aug]` On Partner Agencies, the Groups tab has no filter, so the card jumps up and down.
  It is a very odd visual experience. Also, clicking Groups automatically collapses the side nav.
  What is industry standard here? The same applies to Kits. What is standard for tab sets where some
  tabs have filters and others do not? The filter appearing and disappearing is very jarring.
- `[152 · 30 Aug]` On the Requests page the picklist design is not ideal — blue background, no
  padding. Show me design previews that merge industry standard with the design system's aesthetic.
  Also, the "Show product totals" button pushes the table down a long way. Is that the right place
  for it?
- `[154 · 30 Aug]` On Items & Inventory, shouldn't there be equal padding above and below the filter
  dropdown? Also, if there is a single filter, is there any need for a filter dropdown that then
  reveals one category — on the item list there is only NDBN reporting category. And the checkbox is
  floating rather than centre-aligned to the dropdown.
- `[156 · 30 Aug]` The padding is still not equal above and below the filter dropdown, and the
  filter dropdown still appears where there is only one filter — for example on Items & Inventory,
  on the item list page.
- `[163 · 31 Aug]` On Product Drives, when you click "View" on a row, the button copy is "Make a
  correction" and "Delete". The placement of these buttons looks reversed. Is "correction" accurate,
  or too verbose — wouldn't "Edit" work?
- `[174 · 31 Aug]` There is a bug: the range picker is on the right and completely squeezed into a
  narrow column.
- `[182 · 1 Sep]` There is too much padding between the Months and Compare fields. Shouldn't the
  Months field be called "Date range", or something more generic? There is also no way to clear the
  chips from the collapsed Compare field once they are selected — how would we add "Clear all"?
  Would helper text for Date range and Compare be useful? And this helper text means nothing to a
  non-technical person: "Cached, so it may be up to 24 hours behind."
- `[183 · 1 Sep]` The Compare input is taller than the date range field. It does not look good. In
  the graph, "September 2026, so far" breaks the visual symmetry. And the chips make that input so
  wide that they push the visualisation down. Show me design previews that solve these.
- `[189 · 1 Sep]` On the History report there is a filter button next to "Refers to". It is not clear
  what happens when it is pressed, or how to reverse it. The scroll bar is stuck on the item
  dropdown — that looks like a bug. All of this needs fixing. Why is there an icon button with no
  label or tooltip, and no information about what it does or how to undo it? The alignment also looks
  wrong.

### Tables

- `[3 · 22 Aug]` Several tabs in Items & Inventory have secondary buttons embedded in the tables,
  pushing the table content down. What is industry standard for handling this? Show me a preview of
  the recommendation, and once a decision is made add it to the design system. Then audit the rest of
  the app for consistency.
- `[32 · 24 Aug]` On Purchases, the comments column increases row height exponentially, making it
  very hard to parse the information and see the data actually in the rows. What is industry
  standard for handling long free-text fields in a table? Show me a design preview with your
  recommendation. Then update all tables with open text fields to follow the convention, and update
  the design system file.
- `[35 · 24 Aug]` Fix the distributions actions column that is making rows tall.
- `[43 · 25 Aug]` The scroll bar is not visible and there is no signifier that this table scrolls
  horizontally.
- `[45 · 25 Aug]` The fade covers the pinned column — is that right? I also cannot see the scroll
  bar. What triggers it? What is a better way to do this, and what is industry standard? The user
  also has to scroll to the bottom of the page to discover the functionality at all.
- `[47 · 25 Aug]` On Purchases, at every breakpoint the table stays in horizontal scroll. That is not
  the design system convention — it should be arranged in the card with stacked labelled fields, in
  one or two columns depending on breakpoint. Match the design system and industry standard, then
  audit all tables across the app and update them.
- `[49 · 25 Aug]` The grey overlay on the horizontal scroll looks odd and rather quaint. Show me
  better ways to do this; it needs updating.
- `[102 · 27 Aug]` There is still a bug where a ghost scroll bar appears above the actual scroll bar
  and then disappears. This needs to be fixed. The scroll bar styling is also very heavy-handed —
  what is a better way to style it? Look at industry standard, match the design system's aesthetic,
  and show me design previews.
- `[124 · 29 Aug]` On Items & Inventory the two buttons are nested in a kebab menu, but on other
  pages — Barcode Items, Donation Sites — there are three buttons and they are not nested. The
  Partner Agencies table and the organization users table are especially bad: buttons of different
  sizes, sometimes present and sometimes absent, which is visually jarring. There needs to be
  consistency in action treatment across all tables. What does the design system and industry
  recommend? Once approved, add it to the design system, audit the app, and apply it everywhere.
- `[126 · 29 Aug]` What is industry standard for an "Actions" column header in tables with actions at
  the end? Show me design previews with recommendations. What has the rule done for tables with
  buttons of different sizes that appear sometimes and not others? On Items & Inventory, why are some
  Deactivate buttons disabled? It is not clear to the user why, so it is very confusing. How do we
  fix that?
- `[145 · 29 Aug]` User feedback on tables: having the action at the far end of a horizontal scroll,
  for someone processing many rows, is very frustrating. Show me design options that resolve this,
  based on industry standard for data-heavy tables with actions.
- `[169 · 31 Aug]` Under Reports, the monthly distribution table does not match the design system.
  There is padding missing on both sides. Has pagination been applied? The data visualisation also
  does not match the design system's aesthetic. Show me design previews of options for the data
  visualisations, with recommendations and industry standard — then audit and update all the reports.
- `[171 · 31 Aug]` The sparkline column makes the table too wide and adds a scroll in the desktop
  view. Is there a way to trim it so the desktop viewport does not scroll?

### Components behaving wrongly

- `[15 · 23 Aug]` The donation page has two validation error summaries — one above the card, below
  the required-fields text, and another above the Back button. Why are there two separate error
  conventions? Follow the design system and industry standard for a single convention across all
  pages. The field-level validation text is also red; it should be grey, with a warning icon. Check
  the design system and match the convention.
- `[16 · 23 Aug]` Fix the `admin/partners/edit` input blocks too. The icon has no background, the
  text is red and should be grey, and the error text in the summary should not be red — or check what
  colour it should be.
- `[17 · 23 Aug]` The text is now blue and underlined. This is an issue. **I have had to prompt
  multiple times to fix this.** Look in the design system and match its pattern and industry
  standard. These look like blue links; they should be plain text with the bullets offset beneath the
  title, which is standard error-message styling.
- `[18 · 24 Aug]` On the donation page, the "Items in the donation" card is a mess. The barcode
  scanner field is one size, the barcode icon another. The item dropdown does not match the other
  dropdowns, and nor does quantity. Match the convention for columns per card. Suggest alternatives
  for the barcode icon by comparing with industry standard, and the same for the Remove button. Is
  there a better way to handle each row? Show me a design preview of options with your
  recommendations, based on industry standard for inventory management apps.
- `[20 · 24 Aug]` How was the width of the barcode entry chosen? Should it be one column wide? What
  does industry recommend? Also a small bug: the barcode icon moves left when clicked, and resets on
  refresh.
- `[22 · 24 Aug]` The barcode field should either match the size of the storage location field or be
  half the full width. Right now it aligns with nothing. What is industry standard? Show me a preview
  before building.
- `[26 · 24 Aug]` In the "Items in this donation" card, is a divider between each row industry
  standard? It looks very busy. Show me a preview of how to do this better. Also, "Item" and
  "Quantity" do not match the typography standard for table column headers — audit every instance of
  that miss.
- `[39 · 25 Aug]` There is a question mark on hover — what is that?
- `[53 · 25 Aug]` If there were three different kinds of report, how does the user choose? I do not
  see it under Export — there is only one export.
- `[62 · 26 Aug]` The calendar view on Pick-ups & Deliveries does not match the rest of the design
  system. The Today button and the back/forward buttons do not match button conventions, and the font
  looks different from the rest of the app. What is industry standard for an embedded calendar like
  this? The helper text also needs work: "Scheduled distributions, by day" is not helpful.
- `[78 · 26 Aug]` Under Pick-ups & Deliveries, on the calendar, the Week view button does not work.
  There is also no way to select a date range, or a month in a different year — the only route is
  stepping back and forward one month at a time. What is industry standard? Show me a preview with
  your recommendations.
- `[80 · 27 Aug]` The Today button still does nothing. What is the value of having it when the
  current month is already highlighted blue and the button does nothing?
- `[84 · 27 Aug]` The three Reset buttons stay gated — what does that mean? And what range is the
  list for? It is not clear at all.
- `[86 · 27 Aug]` Under Network → Partner Agencies, when a user clicks an individual partner, that
  page is awful. The buttons make no sense. Why is the badge next to the button? The ZIP codes modal
  triggered by "See ZIP codes" is not properly styled and sticks to the top of the page — where would
  that button sit better? In the Partner Details card, the placement of "Edit details" and "Manage
  users" makes no sense. "Edit partner profile" does not match the design system, padding is missing;
  it is a mess. Use the design system and industry standard to fix it, and show me design previews
  with your recommendations.
- `[90 · 27 Aug]` The Service Area card does not look right — the two-column format makes the
  information very difficult to parse. Recommend different design options. Also, on the Edit Partner
  Profile page the secondary button is on the left and the primary on the right. Is that the right
  placement?
- `[92 · 27 Aug]` The ZIP code section is difficult to read. What is industry standard for displaying
  information like this? How is it sorted? A run of numbers with some spacing is very hard to parse.
  Show me design previews with your recommendations.
- `[111 · 28 Aug]` Fix the status pill in the page header actions.
- `[112 · 28 Aug]` Fix the admin dashboard card pills too.
- `[116 · 28 Aug]` The organization view page is a problem — it looks as though it was not migrated
  at all. The one you reach from the Organization button at the bottom left, or from the avatar
  dropdown.
- `[128 · 29 Aug]` On Items & Inventory, in the kebab menu with Edit and Deactivate: when there is no
  helper text, Edit is hard left and Deactivate is right-aligned in a menu sized for the helper text.
  That makes no sense. What is a better way? This menu is very odd — I have never seen it used
  anywhere else. Would a click with a banner explaining why Deactivate is unavailable work better?
  Also, the confirmation modal for Deactivate is styled by the browser, not by the design system. How
  did that get past the audit?
- `[130 · 29 Aug]` If the selection cannot be deactivated, why is there a confirmation modal?
  Shouldn't the banner appear on click?
- `[131 · 29 Aug]` Why is Organization in both the side nav footer and the avatar dropdown? What is
  industry standard for its location? Duplicating it is not the right answer.
- `[132 · 29 Aug]` On the new kit page this banner appears at the bottom, above the CTA. What
  triggered it, and why is it at the bottom where the user cannot see it straight away? "You will not
  be able to change the composition of the kit once it is saved."
- `[136 · 29 Aug]` On the "New barcode" page, add the barcode icon that opens the camera so the user
  can scan a barcode.
- `[137 · 29 Aug]` You should have matched the design pattern to Inventory Audit, where "Scan a
  barcode" already exists. Is that not in the design system? Why did you not reuse the component for
  consistency? Also, the icon you built spills out of the input field, so there is a bug anyway. Show
  me a design preview of what this page would look like with a matching component, and your
  recommendations.
- `[139 · 29 Aug]` When I click the button in the barcode field, it does not trigger the camera.
- `[140 · 29 Aug]` Under Operations → Purchases, viewing a purchase: there should be a "Start a
  distribution" CTA in the header. Why is that missing?
- `[142 · 29 Aug]` The new distribution page has a strange ghost button that appears for a second on
  refresh — it looks like a shopping cart button with an input. This looks like a bug.
- `[157 · 30 Aug]` On the Requests page, the "Print picklists" batch action makes the filter
  disappear. The filter and the picklist action are never both present. Why? They should not be
  mutually exclusive. Look at industry standard to inform the choice.
- `[165 · 31 Aug]` On the Donation Sites page, the Import and Export buttons look as though their
  icons are mixed up. Audit buttons for consistency — make sure they all have leading icons where
  they need them, and that they are consistent across the entire app.
- `[167 · 31 Aug]` On Product Drives, clicking "View" on a row and then "Delete" opens a destructive
  pop-up modal that is native to the browser. It needs to be styled. Audit every instance like this
  across the app and fix it everywhere. **Why did this get missed by previous audits?**
- `[176 · 31 Aug]` What are these categories? The category dropdown also has no padding to the right
  of the chevron. This stacked chart is not accessible — it is a set of colours that all look very
  similar. Show me design solutions. Who adds categories, and which ones are these?
- `[180 · 31 Aug]` Why is the category dropdown still showing? Making a selection in the table and
  being taken to the top of the screen, then having to scroll back down to make another, is not ideal
  behaviour. The categories should live at the top of the table in a multi-select dropdown, properly
  spaced from the month dropdown. If that is not ideal, recommend alternatives — but plotting in the
  table and having it render in the chart makes no sense. It creates too much friction.
- `[191 · 1 Sep]` On the vendor page, the new vendor address does not match the address / city /
  state format — four fields — used elsewhere. Audit the app for address inputs and make them
  consistent, based on industry standard. Add this decision to design.md and make sure you audit for
  it in future.

### Things that were simply broken

- `[13 · 23 Aug]` Add that to the to-do list. None of the dropdown fields have the right padding to
  the right of the chevron. Why did that happen? Audit and fix across the app.
- `[51 · 25 Aug]` On the Requests page there are four buttons — three secondary, one primary. What is
  industry standard for the number of buttons on a page? These are too many. Also, what does the
  "Calculate product totals" button do? It opens a modal, but there is no actual total. Audit the
  rest of the app for button consistency.
- `[69 · 26 Aug]` Remove the twelve permanent July rows — I do not understand what the issue with
  these July rows is.
- `[71 · 26 Aug]` In the "New product drive participant" modal there is text reading "(phone or email
  required)", which is not aligned with the design system. Audit every modal for correct
  required-field behaviour and update them.
- `[115 · 28 Aug]` Are you able to fix those bugs?
- `[133 · 29 Aug]` Delete the `/users` page, since it is redundant.
- `[134 · 29 Aug]` Fix the `/users/new` form so that it actually adds a user.
- `[177 · 31 Aug]` The categories for this report could be fifty items. What is the maximum number of
  items, and who decides it? Look at the seeded data for the visualisation you just replaced. This is
  not a workable solution. What is industry standard for something like this?

---

<a id="b-choosing-between-presented-options"></a>
## B. Choosing between presented options

Short, and load-bearing. Almost always a letter, usually with a rider that narrows or extends the
choice. The riders are where most of the design system's rules came from.

- `[4 · 22 Aug]` A, with D first. *(quoting my question back)* So "audit the rest of the app for
  consistency" resolves to making Items match Partners. One open question: do you want the new rule
  to cover filter bands like the storage locations one, or only action buttons? That changes whether
  the sweep touches one page or two. What is your recommendation, and why?
- `[5 · 22 Aug]` Go ahead with your recommendation.
- `[9 · 23 Aug]` Do the two straight swaps. What is your recommendation on the other two?
- `[10 · 23 Aug]` Go ahead with your recommendation.
- `[19 · 24 Aug]` Go with C, and add all decisions to the appropriate docs.
- `[23 · 24 Aug]` Go with A and update design.md.
- `[27 · 24 Aug]` Go with B, but make sure the spacing is accurate, that the Remove button is WCAG
  compliant, and that it stays on the same row at larger viewports.
- `[30 · 24 Aug]` Go with option B for the empty state and C for the ghost button, but make sure it
  matches destructive ghost button styling — which is not red, as you showed in the preview. Then
  check and update all empty states to match.
- `[31 · 24 Aug]` Yes, do them.
- `[34 · 24 Aug]` Go with C.
- `[37 · 25 Aug]` Go with C. How does C account for really long names? Is there a character limit?
  Doesn't it push the most pertinent information out of the user's view? What other options are
  there, with recommendations?
- `[38 · 25 Aug]` What about C3, but with the truncation carrying a tooltip like the comment column,
  displaying the name on hover?
- `[42 · 25 Aug]` Go with C, and log all decisions in the docs.
- `[44 · 25 Aug]` Build D, apply it to all such tables, and track it in the design system docs.
- `[46 · 25 Aug]` We can go with option B, however —
- `[50 · 25 Aug]` Go with B, and extend it to the shadow on the pinned column as well.
- `[52 · 25 Aug]` Go with B. Make sure the pattern follows the design system's recommendation and
  components.
- `[56 · 26 Aug]` Go with B, update it across the app, and ensure it is inclusive, gender neutral and
  not ableist.
- `[59 · 26 Aug]` Go with B and your recommendations.
- `[64 · 26 Aug]` Commit the Procfile fix and build the calendar changes. Go with A, with the toolbar
  from C, and add the proposal for the subtitle.
- `[66 · 26 Aug]` Add it to `db/` as a proper task. Also, is there no monthly or weekly view in a
  conventional calendar format?
- `[68 · 26 Aug]` Go with your recommendation, build it, and update the docs.
- `[79 · 26 Aug]` Go with your recommendation.
- `[81 · 27 Aug]` Go with your recommendation. Is this industry standard? Disabled buttons are not
  ideal.
- `[83 · 27 Aug]` Revert it — keep it always enabled.
- `[85 · 27 Aug]` Go with A, plus the caption.
- `[89 · 27 Aug]` Build all five — but before you do, what is the benefit of adding a Service Area
  card, and why was that your first recommendation?
- `[91 · 27 Aug]` Go with A. Make sure column headers, titles and subtitles match the design system.
- `[94 · 27 Aug]` Go with B.
- `[97 · 27 Aug]` Go with C. Look also at the placement on the page — centred or left-aligned.
- `[101 · 27 Aug]` Leave it as it is today.
- `[106 · 28 Aug]` Go ahead with B.
- `[110 · 28 Aug]` Go with C, update all pages with buttons, and add the rule to the design system. Is
  there a caveat for buttons tied to actions inside cards? What is the rule, and how does it work
  alongside page-level action buttons?
- `[117 · 28 Aug]` Go with A.
- `[125 · 29 Aug]` Go with option A, assuming it includes the actions column header title. Also, did
  you add the breadcrumbs rule to design.md? I asked you to make sure all decisions — design
  patterns, migration and onboarding changes — go into the respective documents. Are you still doing
  that? Make sure you do it for all ongoing work, and keep it in your memory.
- `[127 · 29 Aug]` Go with the visible header and visible help text.
- `[129 · 29 Aug]` Go with B, and make this helper text more coherent and helpful: "It is still in
  inventory or used by a kit. Move or use its stock first." Also fix the popover, and audit for such
  instances across the app.
- `[138 · 29 Aug]` Use the joined pattern and update it everywhere. Make the helper text more
  helpful.
- `[141 · 29 Aug]` Go with A, and close the print gap too.
- `[144 · 29 Aug]` Go with A, and audit the app for any other progressively disclosed fields and
  apply the same rule. Make sure you are continuously adding new rules and decisions to all of the
  documents. Keep that in your memory and do it on an ongoing basis.
- `[146 · 30 Aug]` Do A, then C next.
- `[147 · 30 Aug]` Yes, do 3 as well. But can this have a tooltip covering the label of the action
  the icon performs? Show me a design preview before you build it.
- `[148 · 30 Aug]` Build the full set, and option B.
- `[151 · 30 Aug]` Yes, fix the mobile table stacking too.
- `[153 · 30 Aug]` Go with A — but is the row with the helper text necessary? This one: "Tick a row
  to select it." What is industry standard?
- `[155 · 30 Aug]` Fix the alignment, and take B.
- `[164 · 31 Aug]` Go with A, and apply it to the other three. Should there be at least one primary
  CTA? What is industry standard?
- `[166 · 31 Aug]` Go with A — make everything consistent.
- `[170 · 31 Aug]` Go with A and D, then audit and update all the reports. Make sure this meets WCAG
  standards, and log the decisions in all the appropriate docs.
- `[173 · 31 Aug]` Go with option A, your recommendation — but can the user only select completed
  months?
- `[179 · 31 Aug]` Go with B and build A+B. However, this does not address how it will look when
  several items are selected. Should there be a cap? If so, how would that be handled?
- `[181 · 31 Aug]` Go with option B. Cap at four items as before, match the "Category" and "Item"
  subheader styling to the design system, and make it a typeahead multi-select so users can find
  items easily.
- `[184 · 1 Sep]` The chips need to be near the input field so the user can make sense of their
  relationship. Either B or C. Good work — look at industry and make a recommendation with a design
  preview before building. Go with your recommendation for showing the month currently underway.
- `[185 · 1 Sep]` Build C.
- `[188 · 1 Sep]` A, with B's share bar. Make sure the buttons match the design system's styling for
  tables.
- `[192 · 1 Sep]` Go with option B. Clearly document the current state, and the reason for choosing
  B, in the docs.

---

<a id="c-asking-for-research-and-a-preview-before-building"></a>
## C. Asking for research and a preview before building

The rule that shaped the whole project: find out what the industry does, show it before you build it.
It appears as a clause in most Category A prompts too; these are the ones where it is the whole ask.

- `[20 · 24 Aug]` How was the width of the barcode entry chosen? Should it be one column wide? What
  does industry recommend?
- `[22 · 24 Aug]` What is industry standard? Show me a preview before building.
- `[28 · 24 Aug]` What do the design system and industry standard say about icon buttons like this
  one? Are they recommended? Should they have a visible label, or a hover label? Are they screen
  reader compliant?
- `[29 · 24 Aug]` Add a tooltip, or make it a ghost button to match the rest of the app — what is the
  recommendation? Also, what does the empty state look like? Show me design previews before
  building.
- `[33 · 24 Aug]` Can option B work together with a tooltip on hover showing the whole comment, so
  the user can still see the information? What is industry standard for that? Show me a preview.
- `[36 · 25 Aug]` Show me a preview for the no-wrap table option, with recommendations on the best
  option.
- `[40 · 25 Aug]` Now do the fewer-columns option for distributions. Show me recommendations and tell
  me why. What are the downsides of removing columns?
- `[41 · 25 Aug]` Show me a preview first. Is this industry standard? Where and how is it used?
- `[55 · 26 Aug]` Copy like this on the Requests page is not very helpful: "Essentials requested by
  partner agencies." What is a better way to write this helper text, and can it be updated across the
  app for consistency?
- `[58 · 26 Aug]` Fix "Need help?" too — this does not sound right: "Say how many of each item you
  need." Use the design system and industry standard to write the copy. Is it in second or third
  person? Show me previews with recommendations and reasoning before building; once approved, add it
  to the design system.
- `[67 · 26 Aug]` Show me a preview for the week and day views with the value additions you have
  highlighted, and track these in the design system and the other docs.
- `[82 · 27 Aug]` Given the many design systems that do not disable it, what is your recommendation?
- `[93 · 27 Aug]` Why the grid rather than the chips?
- `[96 · 27 Aug]` Show me a design preview first.
- `[99 · 27 Aug]` Show me a preview and explain it with the mock-ups.
- `[100 · 27 Aug]` I want to see it as HTML, as it would look in the app, so I can make a good
  decision.
- `[150 · 30 Aug]` Audit the rest of the app for similar layout shifts.
- `[172 · 31 Aug]` For the data visualisations and the date range — what is industry standard? Should
  there be a month/year date range? Are there other ways to handle it? Show me design previews with
  recommendations.
- `[175 · 31 Aug]` Would other parameters or styles of data visualisation be helpful? Include them in
  the design previews.
- `[178 · 31 Aug]` Before building A+B, what are your recommendations on the category filter? What is
  the best way to design it? Show me with a design preview.
- `[186 · 1 Sep]` The table helper text does not make sense. What is a better way to phrase this:
  "Narrowed to what you are comparing"? Also audit for helper text like this across the app.
- `[187 · 1 Sep]` Under Reports → Manufacturer Donations, the page does not look right. It needs
  redesigning — offer some options based on industry standard.
- `[195 · 2 Sep]` Wire up the slow target and run those over all 150 screens. Before that: what is a
  slow target, and how will it help?

---

<a id="d-ordering-an-app-wide-consistency-sweep"></a>
## D. Ordering an app-wide consistency sweep

Never "fix this page". Always "fix this everywhere, and make sure it stays fixed". This is the
category that produced the audit scripts, because a sweep that is not enforced silently comes undone.

- `[6 · 22 Aug]` Do the filter-consistency pass on the storage locations date band.
- `[7 · 22 Aug]` Do the barcode items filter too.
- `[25 · 24 Aug]` Review and update copy across the entire app so that it is inclusive, has no
  ableist or gender-specific language, and follows industry-standard, WCAG-approved copy conventions.
  That includes making headers, sub-text, labels and buttons compliant, with succinct neutral copy.
- `[61 · 26 Aug]` Fix the rest of the "we" strings too.
- `[72 · 26 Aug]` Fix the family requests form validation too.
- `[73 · 26 Aug]` Now fix the import button gating inconsistency.
- `[114 · 28 Aug]` I want to keep all the design functionality, but bring in all the updates from
  main. I do not want any old Bootstrap patterns coming back, and anything brought in should be
  brought up to date with the design system.
- `[123 · 28 Aug]` None of the reports have a breadcrumb back to the reports dashboard. Make sure all
  pages have breadcrumbs and a way to get to the previous page. None of the tables in the reports
  section match the design system — audit and fix. Use the design system and industry standard for
  the breadcrumb styling.
- `[158 · 30 Aug]` Audit the app for other places where I generalised from one system.
- `[159 · 30 Aug]` Fix the remaining 28 unevidenced citations.
- `[194 · 2 Sep]` Run a WCAG audit on the entire app. Ensure compliance of all elements and patterns.
  Do this with the persona of a senior engineer and designer at GitHub.

---

<a id="e-verification-testing-and-ci"></a>
## E. Verification, testing and CI

- `[8 · 22 Aug]` Fix the page-audit card check too, and tell me how to test it.
- `[54 · 25 Aug]` Tell me how to test that in the app.
- `[60 · 26 Aug]` Run the audits and specs, then commit and push.
- `[74 · 26 Aug]` Show me the vendors page with both buttons, and show me how to test it.
- `[75 · 26 Aug]` Run the vendor importer spec.
- `[76 · 26 Aug]` Run the full suite and push.
- `[104 · 28 Aug]` Where did we land on fixing the scroll bar, based on your recommendation and my
  choosing option B?
- `[135 · 29 Aug]` Explain what the `/users` page you deleted was and what it did. Make sure there is
  documentation on why it was removed. What have you added? Show me how to test it — I cannot follow
  what you are saying.
- `[161 · 30 Aug]` Run the full suite.
- `[162 · 30 Aug]` Re-run the three flaky specs to see whether they were the contamination.
- `[190 · 1 Sep]` Address the two flagged inline-style audit findings.
- `[193 · 1 Sep]` Run the `RemoveAddressFromProviders` migration.
- `[197 · 2 Sep]` Add the self-test to CI so it runs on every PR.
- `[198 · 2 Sep]` Create a document with all of my prompts from the beginning of this project. Clean
  up the grammar and sentence structure, but make sure the essence is not lost. Once you have
  collected them, sort them into logical categories, then use those to build a migration and
  enhancement skill that can be used across other apps in a similar way. Give me your
  recommendations on the best way to do this before actually building the whole thing.

---

<a id="f-copy-and-language"></a>
## F. Copy and language

- `[25 · 24 Aug]` *(also a sweep)* Review and update copy across the entire app: inclusive, no
  ableist or gender-specific language, WCAG-approved conventions, succinct and neutral.
- `[55 · 26 Aug]` "Essentials requested by partner agencies" is not helpful. What is a better way to
  write this helper text, and can it be applied across the app?
- `[57 · 26 Aug]` Show me the new copy on the partner portal pages, and add copy review to the docs.
- `[58 · 26 Aug]` Fix "Need help?" too. Is the copy in second or third person? Show me previews with
  reasoning before building; once approved, add it to the design system.
- `[61 · 26 Aug]` Fix the rest of the "we" strings too.
- `[119 · 28 Aug]` The button in the users table, "Invite user to this organization", feels very
  verbose. What is the recommendation?
- `[129 · 29 Aug]` Make this helper text more coherent and helpful: "It is still in inventory or used
  by a kit. Move or use its stock first."
- `[186 · 1 Sep]` "Narrowed to what you are comparing" does not make sense. What is a better way to
  phrase it? Audit for such helper text across the app.
- `[182 · 1 Sep]` This helper text means nothing to a non-technical person: "Cached, so it may be up
  to 24 hours behind."

---

<a id="g-setup-environment-and-access"></a>
## G. Setup, environment and access

Small in number, and every one of them blocked everything else until it was resolved.

- `[0 · 22 Aug]` Can you create me an SSH key I can add to GitHub for pushing and pulling?
- `[1 · 22 Aug]` It is added. Can you test it, then pull down the design branch and set our current
  branch to design — that is where we will be doing all our work. Then start a local dev server so I
  can view the work.
- `[21 · 24 Aug]` I can no longer access localhost to test the app.
- `[24 · 24 Aug]` Can't you leave the server running? I need to be able to look at it while you are
  working — it keeps going away.
- `[63 · 26 Aug]` I am not able to see the design preview.
- `[65 · 26 Aug]` Seed some data so I can test the calendar page.
- `[87 · 27 Aug]` Where is the design preview?
- `[88 · 27 Aug]` The design preview still does not work.
- `[103 · 28 Aug]` Ensure we are working on the Human Essentials design branch and the local server
  is up.
- `[113 · 28 Aug]` Rebase main into the branch.
- `[122 · 28 Aug]` I cannot see the preview.

---

<a id="h-documentation-and-memory-discipline"></a>
## H. Documentation and memory discipline

Few in number because they are usually a clause inside another prompt — "and log the decisions in
all the appropriate docs". These are the ones where documentation was the whole point.

- `[48 · 25 Aug]` Write me a process document for the work I have been doing with you — the whole
  process. Make it succinct, call it `process.doc`, and make sure you capture how you are pointed at
  the design system and all the steps to execute. Write the summary as a journey or process map,
  something someone can read at a glance and understand.
- `[57 · 26 Aug]` Add copy review to the docs.
- `[125 · 29 Aug]` Did you add the breadcrumbs rule to design.md? I asked you to make sure all
  decisions — design patterns, migration and onboarding changes — go into the respective documents.
  Are you still doing that? Make sure you do it for all ongoing work, and keep it in your memory.
- `[144 · 29 Aug]` Make sure you are continuously adding new rules and decisions to all of the
  documents. Keep that in your memory and do it on an ongoing basis.
- `[191 · 1 Sep]` Add this decision to design.md and ensure you are auditing for it in future.

---

<a id="i-rigour-and-prevention"></a>
## I. Rigour and prevention

Three prompts, and they changed how the work was done more than any others.

- `[160 · 30 Aug]` How can this be prevented from happening in future? Is there something you can put
  into the design system file? And can you go back and finish the audit you were working on before
  this began?
- `[167 · 31 Aug]` *(also a defect report)* Why did this get missed by previous audits?
- `[196 · 2 Sep]` That makes five false positives from new or widened checks over two days — how can
  this be fixed, and how do we make sure it is caught earlier?

---

<a id="j-safety-and-recovery"></a>
## J. Safety and recovery

- `[70 · 26 Aug]` I do not understand. Are you recommending something destructive that will remove
  things from my database? What is a way to fix what you have broken?
- `[77 · 26 Aug]` Go ahead and delete, if this is not a destructive action.
- `[168 · 31 Aug]` The workspace keeps resetting. Can you stop that from happening?

---

## The chronological arc

Reading the same 199 in order rather than by category, the project moves through five phases.

**Days 1–2 (22–23 Aug) — one page at a time.** Access, branch, dev server, then individual
components: the avatar menu, an icon in the wrong part of a card, the required-field asterisk. The
phrase "audit the rest of the app" appears on the very first substantive prompt and never goes away.

**Days 3–5 (24–26 Aug) — the pattern establishes.** Report, ask for the industry standard, ask for a
preview, choose a letter, order a sweep, demand it be written down. Tables dominate: row height,
long text, horizontal scroll, pinned columns. The first process document is requested on day 4.

**Days 6–8 (27–29 Aug) — whole screens.** Partner detail, organization settings, the distribution
form. The prompts get longer and carry four or five separate faults each. Frustration surfaces twice
in the record: "I have had to prompt multiple times to fix this", and "Why do I need to point out
elements individually on the same page?"

**Days 9–11 (30 Aug – 1 Sep) — reports, and the first doubts about the tooling.** Data
visualisation, filters, comparison. Then the question that changes the register: "Why did this get
missed by previous audits?"

**Day 12 (2 Sep) — the tools themselves.** A WCAG audit of the whole app, widening a sampled check
to every screen, a diagnosis of why five checks reported failures that were not real, and a CI job so
the checks are tested on every PR. No screen is discussed at all.
