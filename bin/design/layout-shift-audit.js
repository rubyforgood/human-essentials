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
const { signIn } = require("./targets");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";
const SHOW_ALL = process.argv.includes("--all");
// A shift is a property of the layout, and the layout changes at the breakpoints: a table that
// stacks into cards is a different page. Default is the desktop width the other audits use.
const WIDTH = Number((process.argv.find((a) => a.startsWith("--width=")) || "").split("=")[1] || 1400);

// Chrome's own thresholds, so "bad" here means what it means everywhere else.
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
  const targets = JSON.parse(execSync("bin/rails runner bin/design/route-targets.rb", {
    encoding: "utf8", maxBuffer: 8 << 20, stdio: ["ignore", "pipe", "ignore"]
  }));

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

  results.sort((a, b) => b.score - a.score);
  const bad = results.filter((r) => r.score > GOOD);
  const shown = SHOW_ALL ? results : results.filter((r) => r.score > 0.01);

  console.log(`${checked} screens measured at ${WIDTH}x900\n`);
  console.log("  CLS    page                                        what moved");
  for (const r of shown) {
    const mark = r.score > POOR ? "POOR" : r.score > GOOD ? "warn" : "ok  ";
    console.log(`  ${mark} ${r.score.toFixed(3)}  ${r.path.padEnd(42)} ${r.worst.join(", ") || "-"}`);
  }
  if (!shown.length) console.log("  (nothing above 0.010)");

  const worst = results[0];
  console.log(`\nWorst: ${worst ? `${worst.path} at ${worst.score.toFixed(3)}` : "none"}.` +
    `  Chrome's thresholds: ${GOOD} good, ${POOR} poor.`);
  console.log(bad.length
    ? `\n${bad.length} screen(s) above ${GOOD}`
    : `\nevery screen is inside Chrome's "good" CLS threshold`);
  process.exit(bad.length ? 1 : 0);
})();
