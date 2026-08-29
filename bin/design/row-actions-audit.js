// Audits how a table's *actions column* behaves, which no other check here asks about.
//
// `table-audit.js` checks the visual weight of a row action (`:ghost`) and how many badges a row
// carries. Both can be perfect while the column itself is a mess: three buttons inline on one table
// and two behind a kebab on the next, a column that is 349px wide on one page and 60px on another,
// and — the one that gets reported — a column whose shape changes as you read *down* it, because
// the actions are picked by a `case` on the row's status.
//
// design.md settles the rule; this reports where the app does not follow it, and the two cases the
// rule did not cover:
//
//   3+ inline, no menu   design.md says three or more collapse. Three tables do not.
//   varies row to row    the action set depends on status or role, so the column never settles.
//   mixed heights        a labelled 30px ghost button beside a 28px kebab trigger.
//   menu for <=2         a menu where the actions would fit inline.
//
// Usage: pw bin/design/row-actions-audit.js
const { chromium } = require("playwright");
const { execSync } = require("child_process");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";

const ROLES = {
  bank: process.env.BANK_EMAIL || "org_admin1@example.com",
  super: process.env.SUPER_EMAIL || "superadmin@example.com"
};

async function signIn(page, email) {
  await page.goto(BASE + "/users/sign_out", { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.goto(BASE + "/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", PASSWORD);
  await Promise.all([page.waitForNavigation(), page.click("input[type=submit], button[type=submit]")]);
}

// Reads one table's actions column: how many controls each row shows, whether there is a menu
// trigger, and the distinct heights. Only the *last* cell, which is where a row's actions live.
const PROBE = () => {
  const table = document.querySelector("table.data-table");
  if (!table) return null;
  const rows = [...table.querySelectorAll("tbody tr")].slice(0, 40);
  if (!rows.length) return { empty: true };

  const per = rows.map((tr) => {
    const cell = tr.lastElementChild;
    if (!cell) return null;
    const controls = [...cell.querySelectorAll("a, button")].filter((e) => e.offsetParent !== null);
    // The panel is in the DOM while closed, so its items can be counted without opening it.
    // Without this a kebab row reads as "1 action" and a table with five actions behind a menu
    // looks identical to one with a single button.
    const panel = cell.querySelector("[data-popover-target='panel'], [role='menu'], [data-popover-panel]");
    const inMenu = panel ? panel.querySelectorAll("a, button").length : 0;
    return {
      n: controls.length,
      total: controls.length + inMenu - (inMenu ? 1 : 0),
      menu: !!cell.querySelector("[aria-haspopup], [data-popover-target]"),
      heights: [...new Set(controls.map((e) => Math.round(e.getBoundingClientRect().height)))],
      widths: [...new Set(controls.map((e) => Math.round(e.getBoundingClientRect().width)))]
    };
  }).filter(Boolean);

  const lastCell = table.querySelector("tbody tr:last-child > *:last-child");
  return {
    rows: per.length,
    counts: [...new Set(per.map((x) => x.n))].sort((a, z) => a - z),
    totals: [...new Set(per.map((x) => x.total))].sort((a, z) => a - z),
    menu: per.some((x) => x.menu),
    heights: [...new Set(per.flatMap((x) => x.heights))].sort((a, z) => a - z),
    columnWidth: lastCell ? Math.round(lastCell.getBoundingClientRect().width) : null
  };
};

(async () => {
  const targets = JSON.parse(execSync("bin/rails runner bin/design/route-targets.rb", {
    encoding: "utf8", maxBuffer: 8 << 20, stdio: ["ignore", "pipe", "ignore"]
  })).filter((t) => t.action === "index" || /inventory|quantity_and_location/.test(t.path));

  // Two tables that matter here are not on an index route: the organization page's users table and
  // the same table on its own page. Both were named in the report that prompted this audit.
  targets.push({ path: "/organization", controller: "organizations", action: "show" });
  targets.push({ path: "/users", controller: "users", action: "index" });

  const roleFor = (c) => (c.startsWith("admin") ? "super" : "bank");
  const browser = await chromium.launch();
  const seen = [];

  for (const [role, email] of Object.entries(ROLES)) {
    const context = await browser.newContext({ viewportSize: { width: 1600, height: 900 } });
    const page = await context.newPage();
    await signIn(page, email);
    for (const t of targets.filter((t) => roleFor(t.controller) === role && !t.controller.startsWith("partners/"))) {
      const resp = await page.goto(BASE + t.path, { waitUntil: "networkidle", timeout: 45000 }).catch(() => null);
      if (!resp || resp.status() !== 200) continue;
      const r = await page.evaluate(PROBE);
      if (r && !r.empty) seen.push({ path: t.path, ...r });
    }
    await context.close();
  }
  await browser.close();

  const withActions = seen.filter((t) => Math.max(...t.counts) > 0);
  console.log(`${seen.length} tables, ${withActions.length} with row actions\n`);
  console.log("path".padEnd(34) + "visible      total        menu  heights   column");
  seen.forEach((t) => console.log(
    t.path.padEnd(34) + ("[" + t.counts.join(",") + "]").padEnd(13) +
    ("[" + t.totals.join(",") + "]").padEnd(13) +
    (t.menu ? "yes   " : "no    ") + t.heights.join(",").padEnd(10) + (t.columnWidth ?? "?") + "px"));

  const findings = [];
  const add = (why, list) => list.forEach((t) => findings.push({ why, path: t.path, detail: JSON.stringify(t.counts) }));
  add("3+ inline, no menu", withActions.filter((t) => !t.menu && Math.max(...t.counts) >= 3));
  add("varies row to row", withActions.filter((t) => t.counts.length > 1));
  add("mixed control heights", withActions.filter((t) => t.heights.length > 1));
  // Judged on the real number of actions, menu contents included -- not on what is visible.
  add("menu for 2 or fewer", withActions.filter((t) => t.menu && Math.max(...t.totals) <= 2));

  console.log("");
  if (!findings.length) {
    console.log("every actions column is consistent within its table and across the app");
  } else {
    findings.forEach((f) => console.log(`  ${f.why.padEnd(22)} ${f.path.padEnd(32)} ${f.detail}`));
    console.log(`\n${findings.length} finding(s) across ${new Set(findings.map((f) => f.path)).size} table(s)`);
  }
  process.exit(findings.length ? 1 : 0);
})();
