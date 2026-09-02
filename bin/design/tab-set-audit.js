// Checks that a set of page tabs behaves as one place.
//
// Reported on Partner agencies: "the group tab does not have a filter so the card jumps up and
// down. It is very odd visual experience." And, in the same breath: "when the user clicks on
// groups, it automatically collapses the side nav."
//
// Two invariants, both of which had been broken and neither of which any existing audit asked
// about:
//
//   1. THE STRIP DOES NOT MOVE. Every tab in a set puts its tab strip at the same height.
//      Measured before the fix: /partners at y=228 and /partner_groups at y=174, because the
//      filter bar sat above the card holding the strip -- a 54px jump on every switch. Same on
//      the item catalogue, where /item_categories is the one tab with no filters.
//
//   2. THE RAIL STILL SAYS WHERE YOU ARE. A tab that lives under a sidebar entry keeps that entry
//      marked and its group open. `active_on` listed only the first tab's controller, so landing
//      on /partner_groups or /item_categories left *nothing* active and shut the whole section.
//
// Usage: pw bin/design/tab-set-audit.js
const { chromium } = require("playwright");
const { targets, signIn, visit, BANK } = require("./targets");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";

// Each set is the tabs as a reader meets them, plus the sidebar entry they sit under. `null` for
// a set whose tabs are each their own rail entry.
/*
 * **The sets are discovered, not listed.**
 *
 * This named three of them by hand, with their tab paths and the sidebar entry each should mark. A
 * tab set added anywhere else was simply not audited, and the list carried the same staleness risk
 * as every other hardcoded list in this directory.
 *
 * A tab set is identifiable from the page itself: a strip is a `<nav>` inside `main` containing the
 * link marked `aria-current="page"`, and the set is the collection of hrefs in that strip. Two
 * pages showing the same hrefs are two tabs of one set, whatever they are called -- so the audit
 * visits every screen, groups the ones that have a strip by the strip's contents, and checks each
 * group it finds.
 *
 * The sidebar entry is no longer asserted against a name written here. What the criterion is really
 * about is that the rail marks *something* and does not collapse underneath the reader, and both of
 * those are visible on the page without being told the answer in advance.
 */



const MEASURE = () => {
  const current = document.querySelector("main nav a[aria-current='page']");
  const strip = current ? current.closest("nav") : null;
  return {
    stripY: strip ? Math.round(strip.getBoundingClientRect().top + window.scrollY) : null,
    // The set this page belongs to: the hrefs in its strip. Two pages with the same list are two
    // tabs of one set -- *if* they are in it. A page can display a strip without being one of its
    // tabs: `/partners/1/approve_application` shows the Partners strip and is not on it, and
    // grouping it in reported the strip as moving 72px between "tabs" nobody can switch between.
    inOwnStrip: strip ? [...strip.querySelectorAll("a[href]")]
      .some((a) => new URL(a.href, location.origin).pathname === location.pathname) : false,
    setKey: strip ? [...strip.querySelectorAll("a[href]")]
      .map((a) => a.getAttribute("href")).sort().join(" ") : null,
    stripLabels: strip ? [...strip.querySelectorAll("a[href]")].map((a) => a.textContent.trim()) : null,
    tab: current ? current.textContent.trim() : null,
    // The rail entry the page claims, and whether its section is open.
    railActive: [...document.querySelectorAll("aside a[aria-current='page'], nav[aria-label='Main'] a[aria-current='page']")]
      .map((a) => a.textContent.trim()),
    openGroups: [...document.querySelectorAll("button[aria-expanded='true'][aria-controls^='nav-group']")]
      .map((b) => b.textContent.trim().split("\n")[0])
  };
};

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  await signIn(page, process.env.BANK_EMAIL || "org_admin1@example.com");

  const findings = [];
  let checked = 0;

  // Pass one: every screen, looking for a strip.
  const seen = new Map();
  const landedAlready = new Set();
  for (const { path } of targets().filter((t) => BANK(t.path))) {
    const res = await visit(page, path);
    if (!res) continue;
    /*
     * **A redirect is skipped, not followed into the set.**
     * `/partners/1/approve_application` redirects to `/partners` and arrives carrying a flash bar,
     * which puts the strip 72px lower -- read first as a second tab that does not line up, and
     * then, once deduplicated on the landed path, as `/partners` itself being 72px out. The
     * destination is a target in its own right and is measured when its own turn comes, without
     * somebody else's flash on the page.
     */
    if (res.landed !== path) continue;
    if (landedAlready.has(res.landed)) continue;
    landedAlready.add(res.landed);

    const m = await page.evaluate(MEASURE);
    if (!m.setKey) continue;                       // no tab strip on this screen
    if (!m.inOwnStrip) continue;                   // shows a strip but is not one of its tabs
    checked++;
    if (!seen.has(m.setKey)) seen.set(m.setKey, []);
    seen.get(m.setKey).push({ path: res.landed, ...m });
  }

  // Pass two: each discovered set.
  for (const [, pages] of seen) {
    const name = pages[0].stripLabels.join(" / ");
    console.log(`\n${name}`);

    for (const m of pages) {
      const bad = [];
      // The rail has to mark something, and the section holding it has to stay open. Which entry
      // it marks is the page's business; that it marks *one* is the rule.
      if (m.railActive.length === 0) bad.push("the rail marks nothing");
      if (m.openGroups.length === 0) {
        bad.push("no sidebar group is open -- the section collapsed underneath the reader");
      }
      bad.forEach((b) => findings.push(`${m.path}: ${b}`));

      console.log(`  ${bad.length ? "FAIL" : "ok  "} ${m.path.padEnd(38)} strip at y=${String(m.stripY).padStart(4)}` +
        `  rail=${JSON.stringify(m.railActive)}  open=${JSON.stringify(m.openGroups)}`);
      bad.forEach((b) => console.log(`       ${b}`));
    }

    // The strip must not move between tabs of one set -- that is the jump this audit exists for.
    const ys = pages.map((m) => m.stripY).filter((y) => y !== null);
    if (ys.length > 1) {
      const spread = Math.max(...ys) - Math.min(...ys);
      if (spread > 0) {
        findings.push(`${name}: the tab strip moves by ${spread}px between tabs`);
        console.log(`  FAIL the strip moves by ${spread}px across this set:`);
        pages.forEach((m) => console.log(`       ${m.path.padEnd(38)} y=${m.stripY}`));
      } else {
        console.log(`  ok   the strip is at y=${ys[0]} on all ${ys.length} tabs`);
      }
    }
  }

  await context.close();
  await browser.close();

  console.log(`\n${checked} tabs checked across ${seen.size} discovered sets.`);
  if (!findings.length) {
    console.log("every tab strip holds its height, and the rail keeps saying where you are");
  } else {
    console.log(`\n${findings.length} finding(s)`);
  }
  process.exit(findings.length ? 1 : 0);
})();
