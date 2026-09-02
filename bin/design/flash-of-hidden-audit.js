// Finds content that is painted and then hidden by JavaScript -- a flash of something the reader
// was never meant to see.
//
// Reported on /distributions/new: "a ghost button that appears for a second when you refresh".
// It was the shipping cost field. The server renders it visible, and
// `distribution_delivery_controller` hides it on `connect()` unless the delivery method is
// "shipped" -- so between first paint and Stimulus booting it is on screen.
//
// The rule this checks is the one `[data-railed]` and `[data-tag-input="ready"]` already follow:
// **the server renders the correct initial state, and JavaScript takes over from there.** A
// controller may reveal; it should not have to hide something that was wrong to draw.
//
// Usage: pw bin/design/flash-of-hidden-audit.js
const { chromium } = require("playwright");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";

// Pages carrying a controller that hides something in `connect()`.
/*
 * **Every screen, not the ten that were known to have forms.** A flash is a property of what a page
 * renders and then un-renders, so any page can have one, and the ten listed here were the ten
 * somebody had already found. `visit` from `targets` is deliberately *not* used below: this audit
 * navigates with `commit` because the whole point is to look before scripts have run.
 */
const { targets, signIn, RUNS } = require("./targets");

// The controls a *swap* took over, collected from the settled DOM.
//
// A swap is not a hide: select2 replaces a <select> with its own container and the tag input
// replaces one with chips. Both leave the original in the page, hidden, doing the form's work.
//
// This is asked of each element rather than excusing the whole `<select>` tag, which is what the
// first version did -- and excusing the tag also excused four genuinely painted-then-hidden
// selects on the donation form, worth **100px** of reflow on every load. The layout-shift audit
// had to find those instead.
const SWAPPED = () => {
  const keys = new Set();
  document.querySelectorAll("select.select2-hidden-accessible").forEach((el) => {
    keys.add(el.id || el.getAttribute("name") || "");
  });
  document.querySelectorAll(".select2-container").forEach((c) => {
    const owner = c.previousElementSibling;
    if (owner && owner.tagName === "SELECT") keys.add(owner.id || owner.getAttribute("name") || "");
  });
  // The tag input keeps its select and builds chips beside it.
  document.querySelectorAll("[data-tag-input] select, [data-tag-input-target] select").forEach((el) => {
    keys.add(el.id || el.getAttribute("name") || "");
  });
  return [...keys].filter(Boolean);
};

// Everything with a box, keyed by what it is and where it sits, so a swap can be told from a hide.
const VISIBLE = () => [...document.querySelectorAll("main *")]
  .filter((e) => e.offsetParent !== null)
  .filter((e) => ["INPUT", "SELECT", "TEXTAREA", "BUTTON", "FIELDSET", "DIV"].includes(e.tagName))
  .map((e) => {
    const r = e.getBoundingClientRect();
    if (r.width < 8 || r.height < 8) return null;
    return { key: (e.id || e.getAttribute("name") || e.tagName + "." + String(e.className).split(/\s+/)[0]),
             id: e.id || null, tag: e.tagName,
             label: (e.textContent || "").replace(/\s+/g, " ").trim().slice(0, 40) };
  })
  .filter(Boolean);

(async () => {
  const browser = await chromium.launch();
  const findings = [];
  let checked = 0;

  for (const [email, wants] of RUNS) {
    const context = await browser.newContext({ viewportSize: { width: 1400, height: 900 } });
    const page = await context.newPage();
    await signIn(page, email);

    for (const { path } of targets().filter((t) => wants(t.path))) {
      // `commit` rather than `load`: the point is to look before scripts have run.
      const resp = await page.goto(BASE + path, { waitUntil: "commit" }).catch(() => null);
      if (!resp || resp.status() !== 200) continue;
      checked++;

      const first = await page.evaluate(VISIBLE).catch(() => []);
      await page.waitForLoadState("networkidle").catch(() => {});
      await page.waitForTimeout(900);
      const settled = await page.evaluate(VISIBLE).catch(() => []);

      const settledKeys = new Set(settled.map((e) => e.key));
      const swapped = new Set(await page.evaluate(SWAPPED));
      first
        .filter((e) => !settledKeys.has(e.key))
        .filter((e) => !swapped.has(e.key))
        .forEach((e) => findings.push({ path, id: e.key, label: e.label }));
    }
    await context.close();
  }
  await browser.close();

  console.log(`${checked} page(s) checked\n`);
  if (!findings.length) {
    console.log("nothing is painted and then hidden");
  } else {
    findings.forEach((f) => console.log(`  ${f.path.padEnd(26)} ${f.id.padEnd(34)} ${f.label}`));
    console.log(`\n${findings.length} element(s) visible at first paint and hidden by JavaScript`);
  }
  process.exit(findings.length ? 1 : 0);
})();
