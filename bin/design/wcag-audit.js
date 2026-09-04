// WCAG 2.1 A/AA audit of every significant page, using axe-core in a real browser.
//
// axe-core is the industry-standard engine and finds roughly a third to a half of WCAG issues --
// the machine-checkable ones. It does not judge whether alt text is *good*, whether a heading
// describes its section, or whether a keyboard order makes sense. Those need a person.
//
// Install once:  npm install --no-save --prefix /tmp/axe axe-core
// Run:           pw bin/design/wcag-audit.js [--json]
const { chromium } = require("playwright");
const fs = require("fs");
const { signIn } = require("./targets");

const AXE = "/tmp/axe/node_modules/axe-core/axe.min.js";
const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const JSON_OUT = process.argv.includes("--json");

// WCAG 2.1 A and AA only. Best-practice rules are reported separately so a real failure is
// never hidden among opinions.
const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"];

const SIGNED_OUT = [
  ["sign in", "/users/sign_in"],
  ["forgot password", "/users/password/new"],
  ["account request", "/account_requests/new"],
  ["404", "/404.html"],
  ["500", "/500.html"]
];

const BANK = [
  ["dashboard", "/dashboard"],
  ["distributions", "/distributions"],
  ["new distribution", "/distributions/new"],
  ["donations", "/donations"],
  ["new donation", "/donations/new"],
  ["purchases", "/purchases"],
  ["requests", "/requests"],
  ["items", "/items"],
  ["new item", "/items/new"],
  ["storage locations", "/storage_locations"],
  ["transfers", "/transfers"],
  ["new transfer", "/transfers/new"],
  ["adjustments", "/adjustments"],
  ["audits", "/audits"],
  ["kits", "/kits"],
  ["partners", "/partners"],
  ["partner groups", "/partner_groups"],
  ["new partner", "/partners/new"],
  ["new partner group", "/partner_groups/new"],
  ["donation sites", "/donation_sites"],
  ["product drives", "/product_drives"],
  ["manufacturers", "/manufacturers"],
  ["vendors", "/vendors"],
  ["barcode items", "/barcode_items"],
  ["announcements", "/broadcast_announcements"],
  ["new announcement", "/broadcast_announcements/new"],
  ["users", "/users"],
  ["my account", "/users/edit"],
  ["organization settings", "/manage/edit"],
  ["reports hub", "/reports"],
  ["itemized distributions", "/reports/itemized_distributions"],
  ["annual survey", "/reports/annual_reports"],
  ["activity graph", "/reports/activity_graph"],
  ["history", "/events"],
  ["pick ups", "/distributions/schedule"]
];

const ADMIN = [
  ["admin dashboard", "/admin/dashboard"],
  ["admin organizations", "/admin/organizations"],
  ["admin new organization", "/admin/organizations/new"],
  ["admin users", "/admin/users"],
  ["admin base items", "/admin/base_items"],
  ["admin new base item", "/admin/base_items/new"],
  ["admin partners", "/admin/partners"],
  ["admin announcements", "/admin/broadcast_announcements"],
  ["admin account requests", "/admin/account_requests"],
  ["admin FAQ", "/admin/questions"],
  ["admin NDBN upload", "/admin/ndbn_members"]
];

const PARTNER = [
  ["partner dashboard", "/partners/dashboard"],
  ["partner profile", "/partners/profile"],
  ["partner edit profile", "/partners/profile/edit"],
  ["partner requests", "/partners/requests"],
  ["partner new request", "/partners/requests/new"],
  ["partner distributions", "/partners/distributions"],
  ["partner families", "/partners/families"],
  ["partner new family", "/partners/families/new"],
  ["partner children", "/partners/children"],
  ["partner help", "/partners/help"]
];


async function audit(page, label, path) {
  const res = await page.goto(BASE + path, { waitUntil: "networkidle", timeout: 30000 });
  if (!res || res.status() >= 400) return { label, path, status: res && res.status() };

  await page.addScriptTag({ path: AXE });
  const result = await page.evaluate(async (tags) => {
    // rack-mini-profiler injects its own markup into every development page. It is dev-only
    // chrome, not app output, so auditing it reports defects that cannot ship.
    const run = await axe.run(
      { exclude: [[".profiler-results"], [".profiler-result"], ["#rack-mini-profiler"]] },
      { runOnly: { type: "tag", values: tags }, resultTypes: ["violations"] }
    );
    return run.violations.map((v) => ({
      id: v.id,
      impact: v.impact,
      help: v.help,
      tags: v.tags.filter((t) => /^wcag/.test(t)),
      nodes: v.nodes.length,
      example: v.nodes[0] && v.nodes[0].html.slice(0, 150),
      target: v.nodes[0] && v.nodes[0].target.join(" ")
    }));
  }, WCAG_TAGS);

  return { label, path, violations: result };
}

(async () => {
  const browser = await chromium.launch();
  const all = [];

  // Every screen the router knows, not the four hand-kept lists below. Those covered 61 pages
  // while route-targets.rb enumerates 163 -- and a hardcoded list is what let three unmigrated
  // pages hide from every audit for the length of the design system migration.
  const { execSync } = require("child_process");
  const routed = JSON.parse(execSync("bin/rails runner bin/design/route-targets.rb", {
    encoding: "utf8", maxBuffer: 8 << 20, stdio: ["ignore", "pipe", "ignore"],
  }));
  const forRole = (role) => routed
    .filter((t) => (t.controller.startsWith("partners/") ? "partner"
      : t.controller.startsWith("admin") ? "super" : "bank") === role)
    .map((t) => [t.path, t.path]);

  for (const [email, pages] of [
    [null, SIGNED_OUT],
    ["org_admin1@example.com", forRole("bank")],
    ["superadmin@example.com", forRole("super")],
    ["verified@example.com", forRole("partner")]
  ]) {
    const page = await browser.newPage({ viewportSize: { width: 1280, height: 900 } });
    if (email) await signIn(page, email);
    for (const [label, path] of pages) {
      try {
        all.push(await audit(page, label, path));
      } catch (e) {
        all.push({ label, path, error: e.message.slice(0, 80) });
      }
    }
    await page.close();
  }
  await browser.close();

  if (JSON_OUT) {
    fs.writeFileSync("tmp/wcag-audit.json", JSON.stringify(all, null, 2));
  }

  // Group by rule: a rule broken on 30 pages is one fix, not thirty.
  const byRule = new Map();
  let audited = 0, skipped = [];
  for (const r of all) {
    if (r.error || r.status) { skipped.push(`${r.label} (${r.error || "HTTP " + r.status})`); continue; }
    audited += 1;
    for (const v of r.violations) {
      const e = byRule.get(v.id) || { ...v, pages: [], totalNodes: 0 };
      e.pages.push(r.label);
      e.totalNodes += v.nodes;
      byRule.set(v.id, e);
    }
  }

  const rules = [...byRule.values()].sort((a, b) => b.totalNodes - a.totalNodes);
  console.log(`axe-core ${"4.13.0"} · WCAG 2.1 A/AA · ${audited} pages audited\n`);
  if (rules.length === 0) console.log("no violations");
  for (const r of rules) {
    console.log(`${(r.impact || "?").toUpperCase().padEnd(8)} ${r.id}`);
    console.log(`         ${r.help}`);
    console.log(`         ${r.tags.join(", ")}`);
    console.log(`         ${r.totalNodes} element(s) across ${r.pages.length} page(s): ${r.pages.slice(0, 6).join(", ")}${r.pages.length > 6 ? ", …" : ""}`);
    console.log(`         e.g. ${r.target}`);
    console.log(`              ${r.example}`);
    console.log();
  }
  if (skipped.length) console.log(`skipped: ${skipped.join(", ")}`);
  const total = rules.reduce((n, r) => n + r.totalNodes, 0);
  console.log(`\n${rules.length} distinct violation(s), ${total} element(s)`);
  process.exit(rules.length ? 1 : 0);
})();
