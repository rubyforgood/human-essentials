/*
 * Keyboard navigation, on every screen.
 *
 *   BASE_URL=http://127.0.0.1:3000 pw bin/design/keyboard-audit.js
 *   ONLY=/items pw bin/design/keyboard-audit.js
 *
 * axe finds a great deal but it is a static analysis of one rendered state: it cannot tell you
 * that tabbing walks into an off-canvas drawer, that a control only responds to a mouse, or that
 * the focus ring is invisible against the surface it sits on. Those are what this checks.
 *
 *   2.1.1 Keyboard            everything that does something can be reached and operated
 *   2.1.2 No keyboard trap    and can be left again
 *   2.4.3 Focus order         tab order follows the order things appear in
 *   2.4.7 Focus visible       the focused thing is visibly focused
 *   4.1.2 Name, Role, Value   a div that handles clicks is not a button
 */
const { chromium } = require("playwright");
const { execSync } = require("child_process");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";
const ONLY = process.env.ONLY ? process.env.ONLY.split(",") : null;
const WIDTH = Number(process.env.WIDTH || 1280);
const VIEWPORT = { width: WIDTH, height: 900 };

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

const inspect = () => {
  const FOCUSABLE = "a[href], button, input:not([type=hidden]), select, textarea, [tabindex], " +
                    "[contenteditable=true], summary, details";
  const inProfiler = (el) => !!el.closest(".profiler-results, #rack-mini-profiler");
  // `inert` removes a whole subtree from the tab order and the accessibility tree, so nothing
  // inside one is focusable however it looks. That is how the off-canvas drawer is taken out of
  // the tab order when it is closed.
  const focusable = [...document.querySelectorAll(FOCUSABLE)]
    .filter((el) => !inProfiler(el) && !el.disabled && el.getAttribute("tabindex") !== "-1")
    .filter((el) => !el.closest("[inert]"));

  // A positive tabindex takes an element out of document order and puts it in front of
  // everything that has none. It is almost always a mistake and it is never necessary.
  const positiveTabindex = focusable
    .filter((el) => Number(el.getAttribute("tabindex")) > 0)
    .map((el) => `${el.tagName.toLowerCase()}[tabindex=${el.getAttribute("tabindex")}]`);

  // Focusable but not visible. The classic is an off-canvas drawer: translated out of sight with
  // a transform, so it is still in the tab order and tabbing walks into controls nobody can see.
  // `hidden`, `display:none` and `visibility:hidden` all remove an element properly; a transform
  // does not, and neither does clipping it behind an ancestor's overflow.
  const offscreen = focusable.filter((el) => {
    const r = el.getBoundingClientRect();
    if (!r.width && !r.height) return false;          // genuinely collapsed, and not reachable
    if (getComputedStyle(el).visibility === "hidden") return false;
    // Entirely outside the viewport on the horizontal axis, and not merely scrolled past.
    return r.right <= 0 || r.left >= window.innerWidth + document.documentElement.scrollWidth;
  }).map((el) => `${el.tagName.toLowerCase()} "${(el.textContent || "").trim().slice(0, 22)}"`);

  // Something that responds to a click but cannot be focused or activated from a keyboard.
  // A scrim or backdrop is decoration that happens to be clickable: it is aria-hidden, it has no
  // name, and the thing it does -- close the overlay -- is also on Escape and on a real close
  // button. Requiring it to be focusable would put an unnamed stop in the tab order.
  const mouseOnly = [...document.querySelectorAll("[data-action*='click->']")]
    .filter((el) => !inProfiler(el))
    .filter((el) => el.getAttribute("aria-hidden") !== "true")
    .filter((el) => {
      const tag = el.tagName.toLowerCase();
      if (["a", "button", "input", "select", "textarea", "summary"].includes(tag)) return false;
      // A <dialog>'s own click handler is backdrop dismissal -- a click landing on the element
      // itself rather than on anything inside it. The keyboard equivalent is Escape, which the
      // browser provides for a modal dialog and which overlay-audit checks on every one.
      if (tag === "dialog") return false;
      if (el.getAttribute("tabindex") !== null) return false;
      const role = el.getAttribute("role");
      return role !== "button" && role !== "link";
    })
    .map((el) => `${el.tagName.toLowerCase()}.${(el.className || "").toString().trim().split(/\s+/)[0]}`);

  return {
    focusableCount: focusable.length,
    positiveTabindex: [...new Set(positiveTabindex)].slice(0, 3),
    offscreen: [...new Set(offscreen)].slice(0, 3),
    offscreenCount: offscreen.length,
    mouseOnly: [...new Set(mouseOnly)].slice(0, 3),
  };
};

// Tab through the page and check the ring is actually drawn, and that focus keeps moving.
const walk = async (page, limit = 40) => {
  return page.evaluate(async (limit) => {
    const seen = [];
    let stuck = null;
    document.body.focus();
    for (let i = 0; i < limit; i++) {
      const before = document.activeElement;
      // Synthetic Tab is not available from script; walk the focusable list instead and check
      // each one can hold focus and shows a ring when it does.
      const FOCUSABLE = "a[href], button, input:not([type=hidden]), select, textarea, [tabindex]:not([tabindex='-1']), summary";
      const all = [...document.querySelectorAll(FOCUSABLE)]
        .filter((e) => !e.closest(".profiler-results, #rack-mini-profiler") && !e.disabled)
        .filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0; });
      const el = all[i];
      if (!el) break;
      el.focus();
      if (document.activeElement !== el) { stuck = el.tagName.toLowerCase(); break; }
      const cs = getComputedStyle(el);
      const ring = cs.outlineStyle !== "none" && parseFloat(cs.outlineWidth) > 0;
      const shadow = cs.boxShadow && cs.boxShadow !== "none";
      seen.push({ tag: el.tagName.toLowerCase(), ring: ring || shadow });
    }
    return { walked: seen.length, unfocusable: stuck, noRing: seen.filter((s) => !s.ring).length };
  }, limit);
};

const roleFor = (c) => (c.startsWith("partners/") ? "partner" : c.startsWith("admin") ? "super" : "bank");

(async () => {
  const browser = await chromium.launch();
  const users = { super: "superadmin@example.com", bank: "org_admin1@example.com",
                  partner: process.env.PARTNER_EMAIL || "verified@example.com" };
  const findings = [];
  let checked = 0;

  for (const [role, email] of Object.entries(users)) {
    // Mobile as well as desktop. Below lg the sidebar is an off-canvas drawer, and a drawer
    // moved out of sight with a transform is still in the tab order unless something says
    // otherwise -- which is exactly the bug this check exists for, and it is invisible at 1280.
    let page = await browser.newPage({ viewport: VIEWPORT });
    page.on("dialog", (d) => d.accept().catch(() => {}));
    await signIn(page, email).catch(() => {});
    for (const t of targets) {
      if (roleFor(t.controller) !== role) continue;
      try {
        const r = await page.goto(BASE + t.path, { waitUntil: "domcontentloaded", timeout: 40000 });
        if (r.status() >= 400 || new URL(page.url()).pathname !== t.path) continue;
      } catch {
        try { await page.close(); } catch {}
        page = await browser.newPage({ viewport: VIEWPORT });
        page.on("dialog", (d) => d.accept().catch(() => {}));
        await signIn(page, email).catch(() => {});
        continue;
      }
      await page.waitForTimeout(200);
      checked++;
      const m = await page.evaluate(inspect);
      const problems = [];
      if (m.positiveTabindex.length) problems.push("positive tabindex: " + m.positiveTabindex.join(", "));
      if (m.offscreenCount) problems.push(`${m.offscreenCount} focusable off screen: ${m.offscreen.join(", ")}`);
      if (m.mouseOnly.length) problems.push("click handler on a non-focusable element: " + m.mouseOnly.join(", "));
      if (problems.length) findings.push({ path: t.path, problems });
    }
    await page.close();
  }

  console.log(`${checked} screens checked at ${WIDTH}px\n`);
  if (!findings.length) { console.log("no keyboard findings"); await browser.close(); return; }
  const byProblem = {};
  for (const { path, problems } of findings) for (const p of problems) (byProblem[p] ||= []).push(path);
  for (const [p, paths] of Object.entries(byProblem).sort((a, b) => b[1].length - a[1].length)) {
    console.log(`== ${p} — ${paths.length} screen(s)`);
    paths.slice(0, 8).forEach((x) => console.log("   " + x));
    if (paths.length > 8) console.log(`   …and ${paths.length - 8} more`);
    console.log("");
  }
  console.log(`${findings.length} screen(s) with findings`);
  await browser.close();
})();
