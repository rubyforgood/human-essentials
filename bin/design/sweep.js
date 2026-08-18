// Walks every significant page in a real browser and reports, per page:
//   - leftover Bootstrap/AdminLTE classes (which are defined nowhere and draw nothing)
//   - Font Awesome classes (same)
//   - heading level skips, and whether there is exactly one <h1> and one <main>
//   - form controls with no accessible name, and buttons with no accessible name
//   - stylesheets loaded from anywhere but this app
//   - JavaScript console errors
//   - whether the page is actually rendering in Figtree
//
// Usage: start the app on 127.0.0.1:3003, then `pw bin/design/sweep.js`.
//
// This complements the specs rather than repeating them: it catches things that render
// without raising -- an unlabelled control, a skipped heading level, a class that no longer
// exists -- which a request spec passes straight over.
const { chromium } = require("playwright");

// Walks the main pages of the app as a signed-in bank admin and reports the things a design
// migration silently gets wrong: leftover Bootstrap class names, Font Awesome icons that
// draw nothing, missing/duplicated landmarks, heading-order skips, unlabelled controls,
// and any page that errors outright.
const PATHS = [
  "/dashboard", "/donations", "/donations/new", "/purchases", "/purchases/new",
  "/requests", "/distributions", "/distributions/new", "/distributions/schedule",
  "/items", "/items/new", "/kits", "/kits/new", "/storage_locations", "/storage_locations/new",
  "/transfers", "/transfers/new", "/adjustments", "/adjustments/new", "/audits", "/audits/new",
  "/barcode_items", "/partners", "/partners/new", "/partner_groups/new",
  "/donation_sites", "/vendors", "/manufacturers", "/product_drives", "/product_drive_participants",
  "/events", "/reports/activity_graph", "/reports/annual_reports", "/reports/distributions_summary",
  "/users", "/help", "/organization", "/partner_groups/new", "/admin/questions",
  "/admin", "/admin/account_requests", "/admin/organizations", "/admin/users",
  "/admin/base_items", "/admin/barcode_items", "/admin/broadcast_announcements",
  "/admin/ndbn_members", "/admin/partners", "/admin/users/new",
  "/reports/itemized_donations", "/reports/donations_summary",
  "/reports/purchases_summary", "/reports/product_drives_summary", "/broadcast_announcements",
  "/item_categories/new", "/distributions_by_county/report",
];

const LEGACY = ["card-body","card-header","card-footer","btn-primary","btn-secondary","btn-danger",
  "content-header","container-fluid","form-group","col-md-12","breadcrumb","pull-right","box-body",
  "table-striped","nav-tabs","modal-dialog","form-control","info-box","small-box"];

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1400, height: 1000 } });
  const page = await ctx.newPage();
  const consoleErrors = [];
  page.on("pageerror", (e) => consoleErrors.push(String(e).slice(0, 120)));

  await page.goto("http://127.0.0.1:3003/users/sign_in", { waitUntil: "networkidle" });
  await page.fill('input[name="user[email]"]', "org_admin1@example.com");
  await page.fill('input[name="user[password]"]', "password!");
  await Promise.all([page.waitForNavigation({waitUntil:"networkidle"}).catch(()=>{}), page.click('input[type="submit"], button[type="submit"]')]);

  const rows = [];
  for (const path of PATHS) {
    consoleErrors.length = 0;
    let status = "?";
    try {
      const res = await page.goto("http://127.0.0.1:3003" + path, { waitUntil: "domcontentloaded", timeout: 20000 });
      status = res ? res.status() : "?";
      await page.waitForTimeout(150);
    } catch (e) { rows.push({ path, error: String(e).slice(0, 90) }); continue; }

    const r = await page.evaluate((LEGACY) => {
      const inProf = (el) => el.closest(".profiler-results, .profiler-stack-trace, #rack-mini-profiler") !== null;
      const legacy = LEGACY.filter((c) => [...document.querySelectorAll("." + CSS.escape(c))].some((el) => !inProf(el)));
      const headings = [...document.querySelectorAll("h1,h2,h3,h4,h5,h6")].filter((h) => !inProf(h)).map((h) => +h.tagName[1]);
      let skip = null;
      for (let i = 1; i < headings.length; i++) if (headings[i] - headings[i - 1] > 1) { skip = `h${headings[i-1]}->h${headings[i]}`; break; }
      const unlabelled = [...document.querySelectorAll("input:not([type=hidden]):not([type=submit]):not([type=button]), select, textarea")]
        .filter((el) => !inProf(el) && !(el.labels && el.labels.length) && !el.getAttribute("aria-label") && !el.getAttribute("aria-labelledby")).length;
      const namelessButtons = [...document.querySelectorAll("button, a")]
        .filter((el) => !el.textContent.trim() && !el.getAttribute("aria-label") && !el.querySelector("img[alt]:not([alt=''])")).length;
      return {
        legacy, skip, unlabelled, namelessButtons,
        h1: [...document.querySelectorAll("h1")].filter((h) => !inProf(h)).length,
        mains: [...document.querySelectorAll("main")].filter((m) => !m.closest(".profiler-results, .profiler-stack-trace, #rack-mini-profiler")).length,
        fa: document.querySelectorAll('[class*="fa-"]:not([class*="bi-"])').length,
        font: getComputedStyle(document.body).fontFamily.split(",")[0].replace(/"/g, ""),
        externalCss: [...document.querySelectorAll("link[rel=stylesheet]")].filter((l)=>!l.href.includes("127.0.0.1")).length,
      };
    }, LEGACY);
    rows.push({ path, status, ...r, jsErrors: consoleErrors.length ? consoleErrors[0] : null });
  }

  const bad = rows.filter((r) => r.error || r.status >= 400 || (r.legacy && r.legacy.length) || r.fa || r.h1 !== 1 || r.mains !== 1 || r.skip || r.unlabelled || r.namelessButtons || r.externalCss || r.jsErrors || (r.font && r.font !== "Figtree"));
  console.log(`pages audited: ${rows.length}`);
  console.log(`clean: ${rows.length - bad.length}`);
  if (bad.length) { console.log("\nISSUES:"); bad.forEach((b) => console.log("  " + JSON.stringify(b))); }
  await browser.close();
})();
