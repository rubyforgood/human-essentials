const { chromium } = require("playwright");
const { signIn } = require("./targets");

// Every screen must be reachable *and* leavable. A page that is not in the sidebar and has no
// breadcrumb has one way out: the browser's back button. The five report pages were all like that,
// and none of them is in the sidebar -- the reports hub links to them and they link nowhere.
//
// Usage: pw bin/design/wayfinding-audit.js
//        BASE_URL=http://127.0.0.1:3000 pw bin/design/wayfinding-audit.js

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";
// Screens with no app chrome, so there is nothing for a breadcrumb to sit under and nowhere in
// the app to go back to. All of them are signed-out or standalone flows.
//
//   /                          the marketing landing page
//   /privacypolicy, /termsofservice   standalone legal documents, rendered with `layout false`
//   /account_requests/*        the request-an-account flow, before an account exists
//   /users/invitation/*        Devise's invitation acceptance, likewise
//   /admin                     a redirect, not a page
const NO_CHROME = [
  /^\/$/, /^\/privacypolicy$/, /^\/termsofservice$/,
  /^\/account_requests\//, /^\/users\/invitation\//, /^\/admin$/
];

const ROLES = {
  super: process.env.SUPER_EMAIL || "superadmin@example.com",
  bank: process.env.BANK_EMAIL || "org_admin1@example.com",
  partner: process.env.PARTNER_EMAIL || "verified@example.com"
};


(async () => {
  const { execSync } = require("child_process");
  const targets = JSON.parse(execSync("bin/rails runner bin/design/route-targets.rb", {
    encoding: "utf8", maxBuffer: 8 << 20, stdio: ["ignore", "pipe", "ignore"]
  }));

  // route-targets.rb does not carry a role; the controller namespace decides it, the same way
  // route-sweep.js works it out.
  const roleFor = (controller) =>
    controller.startsWith("partners/") ? "partner"
      : controller.startsWith("admin") ? "super"
        : "bank";

  const browser = await chromium.launch();
  const findings = [];
  let checked = 0;

  for (const [role, email] of Object.entries(ROLES)) {
    const context = await browser.newContext({ viewportSize: { width: 1400, height: 900 } });
    const page = await context.newPage();
    await signIn(page, email);

    // What this role can reach from the chrome. A page listed here is a root and needs no trail.
    const nav = await page.evaluate(() =>
      [...document.querySelectorAll("aside a[href], header a[href], nav a[href]")]
        .map((a) => new URL(a.href).pathname));
    const roots = new Set(nav);

    // A destination should appear in one navigation surface, not two. "Organization" sat in the
    // sidebar's pinned footer *and* the account menu behind the identical `can_administrate?`
    // gate -- the same link, for the same people, in two places. Neither is wrong on its own,
    // which is exactly why nothing caught it.
    const duplicates = await page.evaluate(() => {
      const surface = (a) => (a.closest("aside") ? "sidebar" : a.closest("header") ? "account menu" : "other");
      const seen = new Map();
      document.querySelectorAll("aside a[href], header a[href]").forEach((a) => {
        const path = new URL(a.href).pathname;
        const where = surface(a);
        if (!seen.has(path)) seen.set(path, new Set());
        seen.get(path).add(where);
      });
      return [...seen.entries()]
        .filter(([, places]) => places.size > 1)
        .map(([path, places]) => ({ path, places: [...places] }));
    });
    duplicates.forEach((d) =>
      findings.push({ role, path: d.path, why: `in two nav surfaces: ${d.places.join(" and ")}` }));

    for (const t of targets.filter((t) => roleFor(t.controller) === role)) {
      const resp = await page.goto(BASE + t.path, { waitUntil: "domcontentloaded", timeout: 45000 }).catch(() => null);
      if (!resp || resp.status() !== 200) continue;
      checked++;

      const r = await page.evaluate(() => {
        const main = document.querySelector("main");
        if (!main) return { noMain: true };
        return {
          h1: !!main.querySelector("h1"),
          crumb: !!main.querySelector('nav[aria-label="Breadcrumb"] a'),
          // Page tabs are lateral rather than up, but a tab strip that links a sibling section is
          // still a way out of a page -- /item_categories and /partner_groups are reached and left
          // that way, and neither is a defect.
          tabs: [...main.querySelectorAll('nav[aria-label="Sections"] a')].some(
            (a) => new URL(a.href).pathname !== location.pathname)
        };
      });

      if (NO_CHROME.some((re) => re.test(t.path))) continue;

      // Where the request *landed*, not where it was aimed. Several targets redirect -- the sweep
      // fills `:family_id` and friends with approximations -- and judging a page by the URL asked
      // for reported `/partners/authorized_family_members/new` as orphaned when it had in fact
      // redirected to the families index, which is a nav root.
      const landed = new URL(page.url()).pathname;
      if (NO_CHROME.some((re) => re.test(landed))) continue;

      const isRoot = roots.has(landed);
      if (!r.h1) findings.push({ role, path: landed, why: "no <h1>" });
      else if (!isRoot && !r.crumb && !r.tabs) {
        findings.push({ role, path: landed, why: "not in the nav, no breadcrumb, no tabs" });
      }
    }
    await context.close();
  }

  console.log(`${checked} screens checked across ${Object.keys(ROLES).length} roles\n`);
  if (!findings.length) {
    console.log("every screen is either a nav root or carries a breadcrumb");
  } else {
    findings.forEach((f) => console.log(`  ${f.role.padEnd(8)} ${f.path.padEnd(42)} ${f.why}`));
    console.log(`\n${findings.length} screen(s) with no way back`);
  }
  await browser.close();
  process.exit(findings.length ? 1 : 0);
})();
