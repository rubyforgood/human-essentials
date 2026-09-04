/*
 * Every HTML screen the router knows about, in a real browser, as three different users.
 *
 * bin/design/sweep.js walks a hardcoded list of 56 paths. A list goes stale silently: the three
 * historical trend pages were in the nav and never in the list, and sat unmigrated with no <h1>
 * for the whole migration without either audit noticing. This one asks the router, so a new
 * controller is covered the day it is routed.
 *
 * Targets come from bin/design/route-targets.rb, which substitutes a real record id for :id.
 *
 *   BASE_URL=http://127.0.0.1:3000 pw bin/design/route-sweep.js
 *
 * A 404 here is usually a route with no action behind it -- `resources :x` generates seven and
 * most controllers implement four -- not a defect. Those are reported separately from the
 * design findings so the two are not confused.
 */
const { chromium } = require("playwright");
const { execSync } = require("child_process");
const { signIn } = require("./targets");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";
const targets = JSON.parse(execSync("bin/rails runner bin/design/route-targets.rb", {
  encoding: "utf8", maxBuffer: 8 << 20, stdio: ["ignore", "pipe", "ignore"],
}));

const LEGACY = ["card-body", "card-header", "card-footer", "btn-primary", "btn-secondary",
  "btn-danger", "btn-success", "btn-info", "btn-warning", "form-group", "form-control",
  "input-group", "col-md-6", "col-md-4", "col-md-3", "col-sm-6", "table-responsive",
  "panel-body", "well", "callout", "info-box", "small-box", "box-title", "pull-right",
  "img-circle", "custom-select", "form-check-input", "custom-control-input", "label-default"];

// static/ renders with layout false and its own stylesheet; see docs/migration-map.md.
const EXEMPT = /^\/(privacypolicy|)$/;


const inspect = (LEGACY) => {
  const inProf = (el) => el.closest(".profiler-results, .profiler-stack-trace, #rack-mini-profiler") !== null;
  const all = (sel) => [...document.querySelectorAll(sel)].filter((e) => !inProf(e));
  // A control hidden with CSS is not in the accessibility tree, so it needs no accessible name.
  // The partner document upload hides its native file input behind a custom button.
  const shown = (sel) => all(sel).filter((e) => e.offsetParent !== null || e.getClientRects().length);
  const levels = all("h1,h2,h3,h4,h5,h6").map((h) => +h.tagName[1]);
  const skips = [];
  for (let i = 1; i < levels.length; i++) {
    if (levels[i] - levels[i - 1] > 1) skips.push(levels[i - 1] + "->" + levels[i]);
  }
  return {
    h1: all("h1").length,
    main: all("main").length,
    skips,
    legacy: LEGACY.filter((c) => all("." + CSS.escape(c)).length),
    unlabelled: shown("input:not([type=hidden]):not([type=submit]):not([type=button]), select, textarea")
      .filter((e) => !(e.labels && e.labels.length) && !e.getAttribute("aria-label") && !e.getAttribute("aria-labelledby")).length,
    nameless: shown("button, [role=button]")
      .filter((e) => !e.textContent.trim() && !e.getAttribute("aria-label") && !e.querySelector("img[alt]:not([alt=''])")).length,
    font: getComputedStyle(document.body).fontFamily.split(",")[0].replace(/"/g, ""),
  };
};

// Which role is expected to reach a given controller. A redirect elsewhere just means "not this
// user's page" and is skipped rather than reported.
const roleFor = (controller) =>
  controller.startsWith("partners/") ? "partner"
    : controller.startsWith("admin") ? "super"
      : "bank";

(async () => {
  const browser = await chromium.launch();
  const users = { super: "superadmin@example.com", bank: "org_admin1@example.com",
                  partner: process.env.PARTNER_EMAIL || "verified@example.com" };
  const findings = [], unreachable = [];
  let visited = 0;

  for (const [role, email] of Object.entries(users)) {
    let page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
    let errors = [];
    page.on("pageerror", (e) => errors.push(String(e).slice(0, 100)));
    await signIn(page, email).catch(() => {});

    for (const t of targets) {
      if (roleFor(t.controller) !== role) continue;
      errors = [];
      let resp;
      try {
        resp = await page.goto(BASE + t.path, { waitUntil: "domcontentloaded", timeout: 45000 });
      } catch {
        // A timed-out goto leaves the page busy and poisons every later navigation.
        try { await page.close(); } catch {}
        page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
        page.on("pageerror", (e) => errors.push(String(e).slice(0, 100)));
        await signIn(page, email).catch(() => {});
        unreachable.push([t.path, "timed out"]);
        continue;
      }
      if (resp.status() >= 400) { unreachable.push([t.path, "HTTP " + resp.status()]); continue; }
      if (new URL(page.url()).pathname !== t.path) continue;  // redirected: not this role's page
      if (EXEMPT.test(t.path)) continue;

      visited++;
      const a = await page.evaluate(inspect, LEGACY);
      const problems = [];
      if (a.h1 !== 1) problems.push(`h1=${a.h1}`);
      if (a.main !== 1) problems.push(`main=${a.main}`);
      if (a.skips.length) problems.push("heading skip " + a.skips.join(","));
      if (a.legacy.length) problems.push("legacy " + a.legacy.join(","));
      if (a.unlabelled) problems.push(`unlabelled inputs=${a.unlabelled}`);
      if (a.nameless) problems.push(`buttons with no name=${a.nameless}`);
      if (a.font !== "Figtree") problems.push("font " + a.font);
      if (errors.length) problems.push("js error: " + errors[0]);
      if (problems.length) findings.push([t.path, problems.join(" | ")]);
    }
    await page.close();
  }

  console.log(`${visited} screens rendered and checked, across ${Object.keys(users).length} roles\n`);

  /*
   * A sweep that rendered nothing has not found nothing -- it has not looked. This printed
   * "0 screens rendered and checked" followed by "no design findings" when the dev server had died
   * mid-run, which is a clean bill of health from an audit that never made a request. Say so and
   * exit non-zero instead.
   */
  if (visited === 0) {
    console.error("route-sweep visited no screens. Is the dev server up? This is not a pass.");
    process.exit(2);
  }
  if (findings.length === 0) {
    console.log("no design findings");
  } else {
    console.log(`${findings.length} with findings:`);
    for (const [p, why] of findings) console.log("  " + p.padEnd(46) + why);
  }
  if (unreachable.length) {
    console.log(`\n${unreachable.length} not reached (route with no action, or not HTML):`);
    for (const [p, why] of unreachable) console.log("  " + p.padEnd(46) + why);
  }
  await browser.close();
})();
