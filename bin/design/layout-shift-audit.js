// Finds content that MOVES after it is drawn, on every screen in the app.
//
// Reported on Partner agencies: "the group tab does not have a filter so the card jumps up and
// down. It is very odd visual experience." That one was a shift *between* two pages and was found
// by measuring both. This asks the more general question -- what moves *within* a page, after the
// reader can already see it -- and asks the browser rather than guessing, using the same
// `layout-shift` entries Chrome scores Cumulative Layout Shift from.
//
// CLS is a Core Web Vital: Google's thresholds are **0.1 good, 0.25 poor**. The score is the shift
// fraction times the distance fraction, summed over the session window, so a small element moving a
// long way and a large element moving a short way both count.
//
// Two things this deliberately does NOT flag:
//
//   - A shift the reader caused. Opening a disclosure or applying a filter is *supposed* to move
//     what is below it; `hadRecentInput` marks those and the browser excludes them already.
//   - The dev-only overlays. rack-mini-profiler and Bullet inject fixed badges that are not in
//     production and have fooled a DOM-reading audit on this project before.
//
// Usage: pw bin/design/layout-shift-audit.js
//        pw bin/design/layout-shift-audit.js --all          list every page, not only the offenders
//        pw bin/design/layout-shift-audit.js --width=390    a phone, where tables stack into cards
const { chromium } = require("playwright");
const { signIn, targets: allTargets } = require("./targets");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";
const SHOW_ALL = process.argv.includes("--all");
// A shift is a property of the layout, and the layout changes at the breakpoints: a table that
// stacks into cards is a different page. Default is the desktop width the other audits use.
const WIDTH = Number((process.argv.find((a) => a.startsWith("--width=")) || "").split("=")[1] || 1400);

// Chrome's own thresholds, so "bad" here means what it means everywhere else.
// Below this, run-to-run variation on a loaded machine exceeds the difference between screens, so
// a ranking of them carries no information. Set from measurement, not taste: every screen in this
// app sits between 0.007 and 0.011, and four runs put three different pages on top.
const NOISE = 0.02;
const GOOD = 0.1;
const POOR = 0.25;

const ROLES = {
  super: process.env.SUPER_EMAIL || "superadmin@example.com",
  bank: process.env.BANK_EMAIL || "org_admin1@example.com",
  partner: process.env.PARTNER_EMAIL || "verified@example.com"
};

// Screens with no app chrome; nothing here is part of the design system's layout.
const SKIP = [/^\/$/, /^\/privacypolicy$/, /^\/termsofservice$/, /^\/admin$/];


// Installed before any document script, so the observer is watching from the first frame.
const OBSERVE = () => {
  window.__shifts = [];
  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      // The browser marks anything within 500ms of a real interaction. Those are the reader's
      // own doing and are excluded from CLS for exactly that reason.
      if (entry.hadRecentInput) continue;
      window.__shifts.push({
        value: entry.value,
        sources: (entry.sources || []).map((s) => {
          const n = s.node;
          if (!n || !n.tagName) return "(anonymous)";
          const id = n.id ? `#${n.id}` : "";
          const cls = n.className && typeof n.className === "string"
            ? "." + n.className.split(/\s+/).filter(Boolean).slice(0, 2).join(".") : "";
          return `${n.tagName.toLowerCase()}${id}${cls}`;
        })
      });
    }
  }).observe({ type: "layout-shift", buffered: true });
};

const COLLECT = () => {
  const shifts = window.__shifts || [];
  const noise = /profiler|bullet-|mini-profiler/i;
  const score = shifts.reduce((sum, s) => sum + s.value, 0);
  const blame = {};
  for (const s of shifts) {
    for (const src of s.sources) {
      if (noise.test(src)) continue;
      blame[src] = (blame[src] || 0) + s.value;
    }
  }
  return {
    score,
    worst: Object.entries(blame).sort((a, b) => b[1] - a[1]).slice(0, 3)
      .map(([sel, v]) => `${sel} (${v.toFixed(3)})`)
  };
};

(async () => {
  const { execSync } = require("child_process");
  // From the seam, which regenerates when the list is older than the routes file or the
  // generator. This shelled out on every run: correct, but it spawned Rails each time and
  // skipped the cache whose staleness rule is the point.
  const targets = allTargets();

  const roleFor = (controller) =>
    controller.startsWith("partners/") ? "partner"
      : controller.startsWith("admin") ? "super"
        : "bank";

  const browser = await chromium.launch();
  const results = [];
  let checked = 0;

  for (const [role, email] of Object.entries(ROLES)) {
    const context = await browser.newContext({ viewport: { width: WIDTH, height: 900 } });
    const page = await context.newPage();
    await signIn(page, email);
    await page.addInitScript(OBSERVE);

    for (const t of targets) {
      if (roleFor(t.controller) !== role) continue;
      if (SKIP.some((re) => re.test(t.path))) continue;

      const res = await page.goto(BASE + t.path, { waitUntil: "networkidle" }).catch(() => null);
      if (!res || res.status() >= 400) continue;
      const landed = new URL(page.url()).pathname;
      if (SKIP.some((re) => re.test(landed))) continue;

      // Fonts, select2 and the table rail all settle after networkidle; the shift they cause is
      // real and the reader sees it, so it is waited for rather than raced.
      await page.waitForTimeout(600);
      const m = await page.evaluate(COLLECT).catch(() => null);
      if (!m) continue;

      checked++;
      results.push({ role, path: landed, ...m });
    }
    await context.close();
  }

  await browser.close();

  /*
   * **Below NOISE this audit ranks nothing, because the ranking would be noise.**
   *
   * Every screen here measures around 0.007-0.011 against Chrome's 0.1 "good" threshold -- an order
   * of magnitude inside it. At that magnitude which page is "worst" is decided by machine load, not
   * by the app: four runs named three different pages (`/admin/questions/1/edit` 0.011,
   * `/admin/questions/new` 0.011, `/partners/children/1/edit` 0.007 twice). CLS measures shifts
   * *during* load, so it moves with anything competing for the CPU.
   *
   * The old `score > 0.01` cutoff had the same fault one level down: a page at 0.0105 was listed and
   * the same page at 0.0099 was not, so the list churned between runs as well.
   *
   * So: report against the threshold, which is stable and is what the audit is *for*, and say
   * plainly that the numbers underneath it are not comparable to each other.
   */
  results.sort((a, b) => b.score - a.score);
  const bad = results.filter((r) => r.score > GOOD);
  const notable = results.filter((r) => r.score > NOISE);
  const shown = SHOW_ALL ? results : notable;

  console.log(`${checked} screens measured at ${WIDTH}x900\n`);
  console.log("  CLS    page                                        what moved");
  for (const r of shown) {
    const mark = r.score > POOR ? "POOR" : r.score > GOOD ? "warn" : "ok  ";
    console.log(`  ${mark} ${r.score.toFixed(3)}  ${r.path.padEnd(42)} ${r.worst.join(", ") || "-"}`);
  }
  if (!shown.length) console.log(`  (nothing above the ${NOISE} noise floor)`);

  const highest = results[0];
  if (notable.length) {
    console.log(`\nHighest: ${highest.path} at ${highest.score.toFixed(3)}.` +
      `  Chrome's thresholds: ${GOOD} good, ${POOR} poor.`);
  } else if (highest) {
    // Neither the page nor the number. Naming a page invites somebody to go and "fix" whichever one
    // the last run happened to put on top; printing the value invites a diff between two runs to
    // look like a change. Below the floor there is one fact and this is it.
    console.log(`\nNo screen above the ${NOISE} floor, where run-to-run variation exceeds the ` +
      `difference between screens.  Chrome's thresholds: ${GOOD} good, ${POOR} poor.`);
  }
  console.log(bad.length
    ? `\n${bad.length} screen(s) above ${GOOD}`
    : `\nevery screen is inside Chrome's "good" CLS threshold`);
  process.exit(bad.length ? 1 : 0);
})();
