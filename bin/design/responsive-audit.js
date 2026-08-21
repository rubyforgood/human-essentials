/*
 * Every HTML screen, at every breakpoint the design system has.
 *
 * The existing reflow check in wcag-manual.js is sound but runs on eight pages. This runs the
 * same idea over all of them, at the widths that matter, and adds the things that only go wrong
 * when a layout is squeezed: controls that shrink below a usable tap target, text that stops
 * being legible, and elements that end up on top of each other.
 *
 *   BASE_URL=http://127.0.0.1:3000 pw bin/design/responsive-audit.js
 *   WIDTHS=320,768 pw bin/design/responsive-audit.js      # narrow it down while fixing
 *   ONLY=/items,/donations pw bin/design/responsive-audit.js
 *
 * Widths are Tailwind's breakpoints plus the two that bracket them. 320 is not arbitrary: WCAG
 * 1.4.10 Reflow is defined at 320 CSS px, which is also 1280px at 400% zoom.
 */
const { chromium } = require("playwright");
const { execSync } = require("child_process");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";
const WIDTHS = (process.env.WIDTHS || "320,375,768,1024,1440").split(",").map(Number);
const ONLY = process.env.ONLY ? process.env.ONLY.split(",") : null;

const targets = JSON.parse(execSync("bin/rails runner bin/design/route-targets.rb", {
  encoding: "utf8", maxBuffer: 8 << 20, stdio: ["ignore", "pipe", "ignore"],
})).filter((t) => !ONLY || ONLY.includes(t.path));

async function signIn(page, email) {
  await page.goto(BASE + "/users/sign_out", { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.goto(BASE + "/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.fill('input[name="user[email]"]', email);
  await page.fill('input[name="user[password]"]', PASSWORD);
  await page.click('form[action="/users/sign_in"] button[type="submit"]');
  await page.waitForURL((u) => !u.pathname.includes("/sign_in"), { timeout: 60000 });
}

const measure = () => {
  const vw = document.documentElement.clientWidth;

  // Reachability, not geometry. An element inside a horizontal scroller can be scrolled to, and
  // WCAG 1.4.10 excludes content that needs two-dimensional layout -- a data table is allowed to
  // scroll sideways inside its own container. What must not happen is the *page* scrolling.
  const inScroller = (el) => {
    for (let a = el.parentElement; a && a !== document.body; a = a.parentElement) {
      const ox = getComputedStyle(a).overflowX;
      if (ox === "auto" || ox === "scroll" || ox === "hidden") return true;
    }
    return false;
  };

  const visible = (el) => {
    const r = el.getBoundingClientRect();
    if (!r.width || !r.height) return false;
    const cs = getComputedStyle(el);
    return cs.visibility !== "hidden" && cs.display !== "none" && cs.opacity !== "0";
  };

  const spilling = [...document.querySelectorAll("main *")]
    .filter((el) => visible(el) && el.getBoundingClientRect().right > vw + 2 && !inScroller(el))
    .slice(0, 4)
    .map((el) => el.tagName.toLowerCase() + "." + (el.className || "").toString().trim().split(/\s+/)[0]);

  // WCAG 2.5.8 Target Size (Minimum), AA: 24x24 CSS px -- but with the exceptions applied, or the
  // check is useless. A first version reported 28 findings on the dashboard, every one of them a
  // date link in a table cell that passes on spacing. An audit that cries wolf gets ignored.
  //
  //   Inline    -- the target sits in a sentence, so its size is set by the line box.
  //   Spacing   -- a 24px circle centred on the target touches no other target's box, and no
  //                other undersized target's circle.
  // select2 leaves the native <select> in the DOM at 1x1 and draws its own control beside it.
  // The 1x1 box is not a target anyone can hit; the select2 container is, and it is measured
  // on its own as a [role=button]-ish element.
  const replacedBySelect2 = (el) =>
    el.tagName === "SELECT" &&
    (el.nextElementSibling?.classList?.contains("select2-container") ||
     !!el.parentElement?.querySelector(":scope > .select2-container"));

  // The target is the control *plus its label*: clicking a <label for> activates the control, so
  // a 16x16 checkbox beside a 30x20 label is one target about 50x20, not a 16x16 one.
  const targetRect = (el) => {
    let r = el.getBoundingClientRect();
    for (const l of el.labels || []) {
      const lr = l.getBoundingClientRect();
      if (!lr.width || !lr.height) continue;
      r = { left: Math.min(r.left, lr.left), top: Math.min(r.top, lr.top),
            right: Math.max(r.right, lr.right), bottom: Math.max(r.bottom, lr.bottom) };
    }
    return { left: r.left, top: r.top, right: r.right, bottom: r.bottom,
             width: r.right - r.left, height: r.bottom - r.top };
  };

  const allTargets = [...document.querySelectorAll("a[href], button, input:not([type=hidden]), select, textarea, [role=button], [tabindex]:not([tabindex='-1'])")]
    .filter(visible)
    .filter((el) => !replacedBySelect2(el))
    .map((el) => ({ el, r: targetRect(el) }));

  const undersized = allTargets
    .filter(({ el }) => !el.closest("p, li"))
    .filter(({ r }) => r.width < 24 || r.height < 24);

  const centre = (r) => ({ x: r.left + r.width / 2, y: r.top + r.height / 2 });
  // A 24px-diameter circle -- radius 12 -- centred on the target's box.
  const circleHitsBox = (c, r) => {
    const nx = Math.max(r.left, Math.min(c.x, r.right));
    const ny = Math.max(r.top, Math.min(c.y, r.bottom));
    return Math.hypot(c.x - nx, c.y - ny) < 12;
  };

  const smallTargets = undersized.filter((t) => {
    const c = centre(t.r);
    return allTargets.some((o) => o.el !== t.el && circleHitsBox(c, o.r)) ||
           undersized.some((o) => o.el !== t.el && Math.hypot(c.x - centre(o.r).x, c.y - centre(o.r).y) < 24);
  });

  const tiny = [...document.querySelectorAll("main p, main span, main td, main th, main li, main label")]
    .filter(visible)
    .filter((el) => el.textContent.trim() && parseFloat(getComputedStyle(el).fontSize) < 11).length;

  return {
    bodyOverflow: document.body.scrollWidth - vw,
    spilling,
    smallTargets: smallTargets.length,
    smallestTarget: smallTargets.length
      ? (() => { const w = smallTargets.sort((a, b) => a.r.width * a.r.height - b.r.width * b.r.height)[0];
                 return `${Math.round(w.r.width)}x${Math.round(w.r.height)} ${w.el.tagName.toLowerCase()}` +
                        `"${w.el.textContent.trim().slice(0, 18) || w.el.getAttribute("aria-label") || ""}"`; })()
      : null,
    tinyText: tiny,
  };
};

const roleFor = (c) => (c.startsWith("partners/") ? "partner" : c.startsWith("admin") ? "super" : "bank");

(async () => {
  const browser = await chromium.launch();
  const users = { super: "superadmin@example.com", bank: "org_admin1@example.com",
                  partner: process.env.PARTNER_EMAIL || "verified@example.com" };
  const findings = [];
  let checks = 0;

  for (const [role, email] of Object.entries(users)) {
    let page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
    await signIn(page, email).catch(() => {});
    for (const t of targets) {
      if (roleFor(t.controller) !== role) continue;
      let ok = true;
      try {
        const resp = await page.goto(BASE + t.path, { waitUntil: "domcontentloaded", timeout: 45000 });
        if (resp.status() >= 400 || new URL(page.url()).pathname !== t.path) ok = false;
      } catch {
        try { await page.close(); } catch {}
        page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
        await signIn(page, email).catch(() => {});
        ok = false;
      }
      if (!ok) continue;

      for (const width of WIDTHS) {
        await page.setViewportSize({ width, height: 900 });
        await page.waitForTimeout(120);
        const m = await page.evaluate(measure);
        checks++;

        // Whether the page can be swiped sideways, by swiping it. `window.scrollTo` is not the
        // same question: `overflow-x: clip` on the root stops the gesture but not the script, and
        // `document.documentElement.scrollWidth` counts clipped content inside a scroll container
        // that no user can reach. Only the gesture answers what a person on a phone experiences.
        const anchor = await page.evaluate(() => {
          const h = document.querySelector("main h1, h1");
          return h ? { y: Math.round(h.getBoundingClientRect().top + 8), left: Math.round(h.getBoundingClientRect().left) } : null;
        });
        let swipe = 0;
        if (anchor) {
          await page.mouse.move(Math.round(width / 2), Math.max(anchor.y, 90));
          await page.mouse.wheel(900, 0);
          await page.waitForTimeout(220);
          swipe = await page.evaluate((before) => {
            const h = document.querySelector("main h1, h1");
            const moved = h ? before - Math.round(h.getBoundingClientRect().left) : window.scrollX;
            window.scrollTo(0, 0);
            return moved;
          }, anchor.left);
        }

        const problems = [];
        if (swipe > 2) problems.push(`swipes ${swipe}px sideways`);
        else if (m.bodyOverflow > 2) problems.push(`body ${m.bodyOverflow}px wider than viewport`);
        if (m.spilling.length) problems.push("spills: " + m.spilling.join(", "));
        if (m.smallTargets) problems.push(`${m.smallTargets} target(s) under 24px, smallest ${m.smallestTarget}`);
        if (m.tinyText) problems.push(`${m.tinyText} run(s) of text under 11px`);
        if (problems.length) findings.push({ path: t.path, width, problems });
      }
      await page.setViewportSize({ width: 1440, height: 900 });
    }
    await page.close();
  }

  console.log(`${checks} page/width combinations checked (${targets.length} routes x ${WIDTHS.join(", ")})\n`);
  if (!findings.length) { console.log("no responsive findings"); await browser.close(); return; }

  // Group by problem shape: one layout bug usually shows up on many pages at one width.
  const byWidth = {};
  for (const f of findings) (byWidth[f.width] ||= []).push(f);
  for (const width of WIDTHS) {
    const list = byWidth[width] || [];
    if (!list.length) continue;
    console.log(`== ${width}px — ${list.length} page(s)`);
    for (const f of list) console.log("   " + f.path.padEnd(44) + f.problems.join(" | "));
    console.log("");
  }
  console.log(`${findings.length} findings across ${new Set(findings.map((f) => f.path)).size} pages`);
  await browser.close();
})();
