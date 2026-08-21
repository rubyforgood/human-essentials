// The WCAG criteria axe cannot check, checked by driving the browser.
//
// axe is static: it inspects a rendered tree. These need something to happen first -- a key
// pressed, a viewport resized, a stylesheet overridden. Each check below names the criterion it
// covers so a failure is traceable to the standard rather than to an opinion.
//
// Run: pw bin/design/wcag-manual.js
const { chromium } = require("playwright");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";

const PAGES = [
  ["dashboard", "/dashboard"],
  ["distributions", "/distributions"],
  ["new distribution", "/distributions/new"],
  ["items", "/items"],
  ["partners", "/partners"],
  ["organization settings", "/manage/edit"],
  ["reports hub", "/reports"],
  ["pick ups", "/distributions/schedule"]
];

async function signIn(page, email) {
  await page.goto(`${BASE}/users/sign_in`);
  await page.fill("#user_email", email);
  await page.fill("#user_password", "password!");
  await page.click("input[type=submit], button[type=submit]");
  await page.waitForLoadState("networkidle");
}

const fails = [];
const record = (criterion, page, detail) => fails.push({ criterion, page, detail });

// 1.4.10 Reflow at 320px, and 1.4.4 Resize text at 200% (which is the same page at half width).
//
// NOT measured with documentElement.scrollWidth. That counts the content of a clipped scroll
// container, so a data table inside `overflow-x: auto` reports hundreds of pixels of page overflow
// that no user can scroll to. Chased that for a while: `html { overflow-x: hidden }` did not change
// it, which is the tell. body.scrollWidth and an actual scroll attempt agree with each other and
// with the screen.
//
// Data tables are exempt from 1.4.10 anyway -- the criterion excludes content requiring
// two-dimensional layout -- so what matters is whether the *page* scrolls sideways, not the table.
async function horizontalOverflow(page, label, width, criterion) {
  await page.setViewportSize({ width, height: 800 });
  await page.waitForTimeout(300);

  // Swipe, do not call scrollTo. The three obvious measurements each answer a different question
  // and two of them are wrong:
  //
  //   documentElement.scrollWidth  counts content clipped inside a scroll container. A data table
  //                                in `.table-scroll` makes it report ~1140px on a 320px screen.
  //   body.scrollWidth             stays at the viewport width even when the page does scroll.
  //   window.scrollTo(9999, 0)     gets past `overflow-x: clip` on the root, which a finger
  //                                cannot. This used to be measured, stored in `scrolled`, and
  //                                then never read -- and when it was finally read it reported
  //                                four pages that no user can actually scroll.
  //
  // What is left is to swipe and see whether the page moved, which is the question the criterion
  // is asking. Data tables are exempt from 1.4.10 anyway: it excludes content that requires
  // two-dimensional layout, so the table may scroll inside its own container.
  const anchor = await page.evaluate(() => {
    const h = document.querySelector("main h1, h1");
    return h ? { y: Math.round(h.getBoundingClientRect().top + 8), left: Math.round(h.getBoundingClientRect().left) } : null;
  });
  let moved = 0;
  if (anchor) {
    await page.mouse.move(Math.round(width / 2), Math.max(anchor.y, 90));
    await page.mouse.wheel(900, 0);
    await page.waitForTimeout(250);
    moved = await page.evaluate((before) => {
      const h = document.querySelector("main h1, h1");
      const d = h ? before - Math.round(h.getBoundingClientRect().left) : window.scrollX;
      window.scrollTo(0, 0);
      return d;
    }, anchor.left);
  }

  const outside = await page.evaluate(() => {
    const vw = document.documentElement.clientWidth;
    return [...document.querySelectorAll("main *")]
      .filter((el) => el.getBoundingClientRect().right > vw + 2)
      // Anything inside a horizontal scroller is reachable, which is what the criterion asks.
      // Determined by computed style rather than a class list, so a scroller nobody named still
      // counts -- the Trix toolbar row is one.
      .filter((el) => {
        for (let a = el.parentElement; a && a !== document.body; a = a.parentElement) {
          const ox = getComputedStyle(a).overflowX;
          if (ox === "auto" || ox === "scroll" || ox === "hidden" || ox === "clip") return false;
        }
        return true;
      })
      .slice(0, 3)
      .map((el) => `${el.tagName.toLowerCase()}.${(el.className || "").toString().split(" ")[0]}`);
  });

  if (moved > 2 || outside.length) {
    const parts = [];
    if (moved > 2) parts.push(`swipes ${moved}px sideways`);
    if (outside.length) parts.push("outside any scroller: " + outside.join(", "));
    record(criterion, label, `${parts.join("; ")} at ${width}px`);
  }
  await page.setViewportSize({ width: 1280, height: 900 });
}

const reflow = (page, label) => horizontalOverflow(page, label, 320, "1.4.10 Reflow");
const zoom = (page, label) => horizontalOverflow(page, label, 640, "1.4.4 Resize text");

// 1.4.12 Text spacing: applying the required spacing must not clip content.
async function textSpacing(page, label) {
  await page.addStyleTag({
    content: `* { line-height: 1.5 !important; letter-spacing: 0.12em !important;
                  word-spacing: 0.16em !important; }
              p { margin-bottom: 2em !important; }`
  });
  await page.waitForTimeout(250);
  const clipped = await page.evaluate(() =>
    [...document.querySelectorAll("main button, main a, main h1, main h2, main label")]
      .filter((el) => el.scrollWidth > el.clientWidth + 2 && getComputedStyle(el).overflow === "hidden")
      .slice(0, 3)
      .map((el) => el.textContent.trim().slice(0, 30)));
  if (clipped.length) record("1.4.12 Text spacing", label, `clipped: ${clipped.join(" | ")}`);
}

// 2.1.1 Keyboard and 2.4.7 Focus visible: every interactive element must be reachable by Tab and
// must show focus when it has it.
async function keyboard(page, label) {
  const result = await page.evaluate(() => {
    const interactive = [...document.querySelectorAll(
      "main a[href], main button:not([disabled]), main input:not([type=hidden]):not([disabled]), main select:not([disabled]), main textarea:not([disabled])"
    )].filter((el) => el.offsetParent !== null);
    // tabindex="-1" is correct in three cases, and reporting them is noise:
    //   - a roving-tabindex group: ARIA tabs and toolbars keep one tab stop and use arrow keys
    //   - the original <select> that select2 hides behind its own focusable proxy
    //   - anything inside a closed dialog
    const rovingRole = (el) => ["tab", "menuitem", "radio", "option"].includes(el.getAttribute("role")) ||
      el.closest('[role="toolbar"], [role="tablist"], [role="menu"]') !== null;
    const select2Proxied = (el) => el.tagName === "SELECT" && el.nextElementSibling &&
      /select2/.test(el.nextElementSibling.className || "");
    const unreachable = interactive
      .filter((el) => el.tabIndex < 0 && !rovingRole(el) && !select2Proxied(el))
      .map((el) => `${el.tagName.toLowerCase()}: ${(el.textContent || el.name || "").trim().slice(0, 24)}`);
    return { count: interactive.length, unreachable: unreachable.slice(0, 3) };
  });
  if (result.unreachable.length) {
    record("2.1.1 Keyboard", label, `not reachable by Tab: ${result.unreachable.join(" | ")}`);
  }

  // Focus the first few and confirm a visible focus indicator.
  const noIndicator = await page.evaluate(() => {
    const els = [...document.querySelectorAll("main a[href], main button:not([disabled])")]
      .filter((el) => el.offsetParent !== null).slice(0, 8);
    const bad = [];
    for (const el of els) {
      el.focus();
      const s = getComputedStyle(el);
      const hasOutline = s.outlineStyle !== "none" && parseFloat(s.outlineWidth) > 0;
      const hasRing = /(inset )?0(px)? 0(px)? 0(px)? \d/.test(s.boxShadow) || s.boxShadow !== "none";
      if (!hasOutline && !hasRing) bad.push((el.textContent || "").trim().slice(0, 24));
    }
    return bad;
  });
  if (noIndicator.length) {
    record("2.4.7 Focus visible", label, `no focus indicator: ${noIndicator.join(" | ")}`);
  }
}

// 2.4.1 Bypass blocks: the skip link must exist, take focus, and move focus to the main content.
async function skipLink(page, label) {
  // A page with autofocus has already moved focus into its form, so the first Tab lands on the
  // next field rather than the skip link. That is the autofocus doing its job, not a missing skip
  // link; focus is reset to the top before testing.
  await page.evaluate(() => {
    if (document.activeElement && document.activeElement !== document.body) document.activeElement.blur();
  });
  await page.keyboard.press("Tab");
  const state = await page.evaluate(() => {
    const el = document.activeElement;
    return { text: (el.textContent || "").trim(), href: el.getAttribute && el.getAttribute("href") };
  });
  if (!/skip/i.test(state.text)) {
    record("2.4.1 Bypass blocks", label, `first tab stop is "${state.text.slice(0, 30)}", not a skip link`);
    return;
  }
  await page.keyboard.press("Enter");
  await page.waitForTimeout(150);
  const landed = await page.evaluate(() => {
    const el = document.activeElement;
    return el.id || (el.closest("main") ? "inside main" : el.tagName);
  });
  if (!/main/i.test(landed)) {
    record("2.4.1 Bypass blocks", label, `skip link moved focus to "${landed}", not the main content`);
  }
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewportSize: { width: 1280, height: 900 } });
  await signIn(page, "org_admin1@example.com");

  const titles = new Map();
  for (const [label, path] of PAGES) {
    const res = await page.goto(BASE + path, { waitUntil: "networkidle" });
    if (!res || res.status() >= 400) { console.log(`skipped ${label} (HTTP ${res && res.status()})`); continue; }

    // 2.4.2 Page titled, and titles distinct enough to tell pages apart.
    const title = await page.title();
    if (!title || title.trim().length < 3) record("2.4.2 Page titled", label, `title is "${title}"`);
    if (titles.has(title)) record("2.4.2 Page titled", label, `same title as ${titles.get(title)}: "${title}"`);
    else titles.set(title, label);

    // 3.1.1 Language of page.
    const lang = await page.evaluate(() => document.documentElement.getAttribute("lang"));
    if (!lang) record("3.1.1 Language of page", label, "no lang attribute on <html>");

    await skipLink(page, label);
    await keyboard(page, label);
    await reflow(page, label);
    await zoom(page, label);
    await textSpacing(page, label);
    process.stdout.write(".");
  }
  console.log("\n");

  await browser.close();

  if (fails.length === 0) {
    console.log(`${PAGES.length} pages checked against 1.4.4, 1.4.10, 1.4.12, 2.1.1, 2.4.1, 2.4.2, 2.4.7, 3.1.1 — no failures`);
    process.exit(0);
  }
  const byCriterion = new Map();
  for (const f of fails) {
    const e = byCriterion.get(f.criterion) || [];
    e.push(f);
    byCriterion.set(f.criterion, e);
  }
  for (const [criterion, items] of byCriterion) {
    console.log(`${criterion} — ${items.length} page(s)`);
    for (const i of items) console.log(`   ${i.page}: ${i.detail}`);
    console.log();
  }
  process.exit(1);
})();
