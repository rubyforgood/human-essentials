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

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";

// Each set is the tabs as a reader meets them, plus the sidebar entry they sit under. `null` for
// a set whose tabs are each their own rail entry.
const SETS = [
  { name: "Partner agencies", rail: "Partner agencies",
    tabs: ["/partners", "/partner_groups"] },
  { name: "Item catalogue", rail: "Items & inventory",
    tabs: ["/items", "/item_categories", "/items/quantity_and_location", "/items/inventory"] },
  // Kits is the fifth catalogue tab *and* a rail entry of its own -- design.md allows exactly
  // this -- so its strip must line up with the others while the rail marks Kits, not Items.
  { name: "Kits (catalogue tab and rail entry)", rail: "Kits", tabs: ["/kits"] }
];

async function signIn(page, email) {
  await page.goto(BASE + "/users/sign_out", { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.goto(BASE + "/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", PASSWORD);
  await Promise.all([page.waitForNavigation(), page.click("input[type=submit], button[type=submit]")]);
}

const MEASURE = () => {
  const current = document.querySelector("main nav a[aria-current='page']");
  const strip = current ? current.closest("nav") : null;
  return {
    stripY: strip ? Math.round(strip.getBoundingClientRect().top + window.scrollY) : null,
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

  for (const set of SETS) {
    console.log(`\n${set.name}`);
    const heights = [];

    for (const path of set.tabs) {
      const res = await page.goto(BASE + path, { waitUntil: "networkidle" }).catch(() => null);
      if (!res || res.status() >= 400) {
        findings.push(`${path}: HTTP ${res && res.status()}`);
        continue;
      }
      checked++;
      const m = await page.evaluate(MEASURE);
      heights.push({ path, y: m.stripY });

      const railed = m.railActive.includes(set.rail);
      const grouped = m.openGroups.length > 0;
      const bad = [];
      if (m.stripY === null) bad.push("no tab strip");
      if (!railed) bad.push(`the rail does not mark "${set.rail}" (it marks ${JSON.stringify(m.railActive)})`);
      if (!grouped) bad.push("no sidebar group is open -- the section collapsed underneath the reader");
      bad.forEach((b) => findings.push(`${path}: ${b}`));

      console.log(`  ${bad.length ? "FAIL" : "ok  "} ${path.padEnd(32)} strip at y=${String(m.stripY).padStart(4)}` +
        `  rail=${JSON.stringify(m.railActive)}  open=${JSON.stringify(m.openGroups)}`);
      bad.forEach((b) => console.log(`       ${b}`));
    }

    // Only meaningful for a set of more than one.
    const ys = heights.filter((h) => h.y !== null).map((h) => h.y);
    if (ys.length > 1) {
      const spread = Math.max(...ys) - Math.min(...ys);
      if (spread > 0) {
        findings.push(`${set.name}: the tab strip moves by ${spread}px between tabs`);
        console.log(`  FAIL the strip moves by ${spread}px across this set:`);
        heights.forEach((h) => console.log(`       ${h.path.padEnd(32)} y=${h.y}`));
      } else {
        console.log(`  ok   the strip is at y=${ys[0]} on all ${ys.length} tabs`);
      }
    }
  }

  await context.close();
  await browser.close();

  console.log(`\n${checked} tabs checked across ${SETS.length} sets.`);
  if (!findings.length) {
    console.log("every tab strip holds its height, and the rail keeps saying where you are");
  } else {
    console.log(`\n${findings.length} finding(s)`);
  }
  process.exit(findings.length ? 1 : 0);
})();
