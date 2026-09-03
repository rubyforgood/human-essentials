/*
 * **Fixed 2026-09-03, after four earlier attempts at the wrong problem.**
 *
 * This audit took **58 seconds a page** — 525 seconds for nine pages — and had always done so;
 * nobody had timed it. Widening it to every screen was tried and reverted because it would have
 * taken two hours, and four rounds of optimisation followed: cheap discovery, an instance cap,
 * hoisting axe-core's injection out of a loop, a `Promise.race` budget. None helped, because none
 * of them was the cause.
 *
 * **The cause was three `.click().catch(() => {})` calls.** Playwright retries an unclickable
 * element until its *default 30-second timeout*, and an empty catch hides that it ever happened.
 * Measured on `/organization`: 30,335ms in `checkNativeConfirms`, for seven triggers that are menu
 * items inside a closed kebab and so have no box at all. The same pattern on the filter disclosure
 * cost another 30 seconds on every screen without a filter bar.
 *
 * Bounded clicks, a visibility filter, and condition waits in place of fixed sleeps:
 *
 *   525s for 9 screens   ->   254s for 154 screens
 *   58s per screen       ->   1.6s per screen
 *
 * The lesson is in the numbers rather than the fix: **time the thing before optimising it, and
 * time it per phase.** Guessing produced four wrong answers in a row; one measurement produced the
 * right one.
 */
// Every overlay in the app, opened and checked.
//
// This exists because of a bug the other audits could not see. Every modal <dialog> in the app
// opened in the top-left corner -- 28 files -- because a native modal is centred by the browser's
// own `margin: auto` and Tailwind's preflight resets `margin: 0`. `page-audit.rb` reads markup
// and `wcag-audit.js` scans the page as loaded; neither of them ever opened a dialog, so neither
// of them ever saw it.
//
// Two kinds of overlay, with deliberately different contracts:
//
//   dialog   a modal. Centred, inside the viewport, focus trapped by the browser, Escape closes.
//   popover  anchored to a trigger. On screen, NOT focus-trapped, Escape closes and returns
//            focus to the trigger, aria-expanded tracks the state.
//
// Install once:  npm install --no-save --prefix /tmp/axe axe-core
// Run:           pw bin/design/overlay-audit.js
const { chromium } = require("playwright");
const fs = require("fs");

const AXE = "/tmp/axe/node_modules/axe-core/axe.min.js";
const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"];

// Pages that carry an overlay, and who can see them.
/*
 * **Every screen, not the nine somebody knew had overlays.** A dialog on an unlisted page was simply
 * not audited, which is how a native browser confirm survived on `/product_drives` until somebody
 * clicked it.
 *
 * Widening this was tried once and reverted, because the audit took 58 seconds a page and 150
 * screens would have been two hours. That was never the widening's fault: three
 * `.click().catch(() => {})` calls were each waiting Playwright's default 30-second timeout and
 * swallowing it. With those bounded and the fixed sleeps replaced by condition waits it is 8x
 * faster, and the widening is affordable.
 */
const { targets, signIn, visit, RUNS } = require("./targets");

const PAGES = RUNS.flatMap(([email, wants]) =>
  targets().filter((t) => wants(t.path)).map((t) => [email, t.path]));

// Anything that could open something over the page. Cheap to ask, before any interaction -- so the
// expensive work is proportional to the number of overlays rather than the number of screens.
const HAS_OVERLAY = () => Boolean(document.querySelector(
  "dialog, [data-confirm], [data-turbo-confirm], [data-controller~='popover'], " +
  "[data-popover-target='trigger'], [data-action*='dialog#open'], [data-filter-toggle]"
));



async function axeOn(page, selector) {
  await page.addScriptTag({ content: fs.readFileSync(AXE, "utf8") });
  return page.evaluate(
    async ([sel, tags]) => {
      const result = await window.axe.run(document.querySelector(sel), {
        runOnly: { type: "tag", values: tags }
      });
      return result.violations.map((v) => `${v.id} (${v.nodes.length})`);
    },
    [selector, WCAG_TAGS]
  );
}

async function checkDialogs(page, path, findings) {
  const triggers = await VISIBLE_ONLY(await page.$$("[data-action*='dialog#open']"));

  for (const [i, trigger] of triggers.entries()) {
    const id = await trigger.getAttribute("data-dialog-id-param");
    if (!id || !(await page.$(`[id="${id}"]`))) continue;

    if (!await clickOrReport(trigger, `${path} dialog#${id}`, "the trigger", findings)) continue;
    await page.waitForTimeout(250);

    const state = await page.evaluate((dialogId) => {
      const d = document.getElementById(dialogId);
      if (!d || !d.open) return null;
      const r = d.getBoundingClientRect();
      return {
        centred: Math.abs((innerWidth - r.width) / 2 - r.left) < 4,
        onScreen: r.top >= -1 && r.left >= -1 && r.bottom <= innerHeight + 1,
        isModal: d.matches(":modal"),
        labelled: Boolean(d.getAttribute("aria-label") || d.getAttribute("aria-labelledby"))
      };
    }, id);

    if (!state) continue;
    const where = `${path} dialog#${id}`;
    if (!state.isModal) findings.push(`${where}: opened with show(), not showModal()`);
    if (!state.centred) findings.push(`${where}: not centred`);
    if (!state.onScreen) findings.push(`${where}: extends past the viewport`);
    if (!state.labelled) findings.push(`${where}: no accessible name`);

    for (const v of await axeOn(page, `#${id}`)) findings.push(`${where}: ${v}`);

    await page.keyboard.press("Escape");
    await page
      .waitForFunction((d) => !document.getElementById(d)?.open, id, { timeout: 1000 })
      .catch(() => {});
    if (await page.evaluate((d) => document.getElementById(d)?.open, id)) {
      findings.push(`${where}: Escape does not close it`);
    }
    void i;
  }
  return triggers.length;
}

/*
 * Click something, without the possibility of waiting thirty seconds for it.
 *
 * **`element.click().catch(() => {})` is how this audit came to take 58 seconds a page.** Playwright
 * retries an unclickable element until its *default 30-second timeout*, and the empty catch then
 * hides that it ever happened. Measured on `/organization`: 30,335ms in `checkNativeConfirms`, for
 * seven triggers that are menu items inside a closed kebab and therefore have no box at all.
 *
 * Two changes. The timeout is explicit and short, so a future unclickable control costs two seconds
 * rather than thirty. And a failure is **reported**, because a control that is on screen and cannot
 * be clicked is a real defect -- something is covering it -- and the empty catch was hiding that
 * finding just as thoroughly as it hid the delay.
 */
const CLICK_TIMEOUT = Number(process.env.OVERLAY_CLICK_TIMEOUT || 2000);

async function clickOrReport(handle, where, what, findings) {
  try {
    await handle.click({ timeout: CLICK_TIMEOUT });
    return true;
  } catch {
    findings.push(`${where}: ${what} is on screen but could not be clicked within ` +
      `${CLICK_TIMEOUT}ms -- something is covering it, or it never becomes stable`);
    return false;
  }
}

// Rendered, and therefore actually operable. A control with no box is not on the page as far as a
// pointer is concerned; `confirm-audit.js` is the one that opens menus and checks what is inside.
const VISIBLE_ONLY = async (handles) => {
  const out = [];
  for (const h of handles) if (await h.evaluate((el) => el.offsetParent !== null)) out.push(h);
  return out;
};

async function checkPopovers(page, path, findings) {
  const triggers = await VISIBLE_ONLY(await page.$$("[data-popover-target='trigger']"));

  for (const trigger of triggers) {
    if (!await clickOrReport(trigger, `${path} popover`, "the trigger", findings)) continue;
    /*
     * Wait for the panel to say it is open, not for a quarter of a second.
     *
     * A fixed sleep is both slower and less correct: it pays 250ms on every popover whether or not
     * it needed any, and it would still be too short on a slow one. 100 popovers here spent 57
     * seconds asleep. The condition is the thing actually being waited for.
     */
    await trigger.waitForElementState("stable").catch(() => {});
    await page
      .waitForFunction((t) => t.getAttribute("aria-expanded") === "true", trigger, { timeout: 2000 })
      .catch(() => {});

    // Evaluated against THIS trigger, not the first one on the page -- the account menu is also a
    // popover, and checking it instead reported every date range as broken.
    const state = await trigger.evaluate((t) => {
      if (t.getAttribute("aria-expanded") !== "true") return null;
      // By id first: an open `fixed` panel is moved to <body>, so it is no longer a descendant of
      // its controller -- see popover_controller, which does that to escape the stacking context
      // of the frozen actions column.
      const panel = document.getElementById(t.getAttribute("aria-controls")) ||
        t.closest("[data-controller~='popover']").querySelector("[data-popover-target='panel']");
      if (!panel) return null;
      const r = panel.getBoundingClientRect();
      return {
        onScreen: r.left >= -1 && r.right <= innerWidth + 1 && r.bottom <= innerHeight + 1,
        hidden: panel.hidden,
        named: Boolean(panel.getAttribute("role")),
        role: panel.getAttribute("role"),
        items: panel.querySelectorAll("[role=menuitem]").length,
        shadow: getComputedStyle(panel).boxShadow
      };
    });

    if (!state) continue;
    const where = `${path} popover`;
    if (state.hidden) findings.push(`${where}: aria-expanded is true but the panel is hidden`);
    if (!state.onScreen) findings.push(`${where}: extends past the viewport`);
    if (!state.named) findings.push(`${where}: panel has no role`);
    if (!state.shadow.includes("20px 25px")) findings.push(`${where}: not on the popover surface`);

    // A panel that calls itself a `menu` has to behave like one: the ARIA menu pattern requires
    // arrow-key movement between items. The account menu claimed `role="menu"` from the day it was
    // built and never implemented it, and nothing noticed until row action menus multiplied the
    // claim by 62 -- so the claim is checked here rather than taken on trust.
    if (state.role === "menu" && state.items > 1) {
      const before = await page.evaluate(() => document.activeElement?.textContent?.trim());
      await page.keyboard.press("ArrowDown");
      // Focus moving into the panel is the thing being waited for.
      await page
        .waitForFunction(() => document.activeElement?.getAttribute("role") === "menuitem",
          null, { timeout: 1000 })
        .catch(() => {});
      const after = await page.evaluate(() => document.activeElement?.textContent?.trim());
      if (before === after) findings.push(`${where}: role="menu" but ArrowDown does not move focus`);
    }

    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);
    const closed = await trigger.evaluate((t) =>
      t.getAttribute("aria-expanded") === "false" && document.activeElement === t);
    if (!closed) findings.push(`${where}: Escape does not close it and return focus`);
  }
  return triggers.length;
}

// Desktop and a phone. An overlay that fits at 1360 tells you nothing about 320, which is where
// a 26rem popover or a dialog with its own padding runs out of room -- and where "extends past
// the viewport" stops being cosmetic and starts meaning the control cannot be used.
const VIEWPORTS = [
  { width: 1360, height: 900, label: "1360x900" },
  { width: 320, height: 640, label: "320x640" },
];

// A native `window.confirm` is the one overlay nothing else here can see, and that is not a gap in
// the checks so much as a gap in what a DOM query *can* answer: it is browser chrome, not an
// element. `overlay-audit` opens `<dialog>`s and finds nothing wrong; axe scans the document and
// finds nothing to scan; and the system suite drives it with Capybara's `accept_confirm`, which
// only works on a native dialog -- so a green suite is evidence *for* it, the same shape as the
// toastr message and the frozen-column shadow earlier on this branch.
//
// The only way to see one is to listen for the event the browser raises. Clicking is safe: the
// handler dismisses, so nothing is submitted.
async function checkNativeConfirms(page, label, findings) {
  /*
   * Visible ones only. Every closed row menu still holds its Reclaim and Delete in the document,
   * with no box -- and clicking one of those is what cost thirty seconds a page. The confirmations
   * nested inside menus are `confirm-audit.js`'s job: it opens the panel first, which is the only
   * way to reach them honestly.
   */
  const triggers = await VISIBLE_ONLY(await page.$$("[data-confirm], [data-turbo-confirm]"));
  if (!triggers.length) return 0;

  let seen = 0;
  const onDialog = async (dialog) => {
    seen += 1;
    findings.push(`${label} — native browser confirm, not the design system's dialog: ` +
                  `"${dialog.message().slice(0, 60)}"`);
    await dialog.dismiss();
  };
  page.on("dialog", onDialog);

  // One is enough to prove the mechanism; they all go through the same Rails attribute.
  await clickOrReport(triggers[0], label, "a confirmation trigger", findings);
  await page.waitForTimeout(300);

  page.off("dialog", onDialog);
  return seen;
}

(async () => {
  const browser = await chromium.launch();
  const findings = [];
  let dialogs = 0, natives = 0, screensWithOverlays = 0;
  let popovers = 0;

  // The first pass over every screen records which ones have something to open; later viewports
  // revisit only those.
  let withOverlays = null;

  for (const viewport of VIEWPORTS) {
    const page = await browser.newPage({ viewport: { width: viewport.width, height: viewport.height } });
    let signedInAs = null;

    const foundHere = [];

    for (const [email, path] of (withOverlays || PAGES)) {
      if (signedInAs !== email) {
        await signIn(page, email);
        signedInAs = email;
      }
      // `visit` waits for `load`, never `networkidle`.
      if (!await visit(page, path)) continue;
      if (!await page.evaluate(HAS_OVERLAY)) continue;
      if (withOverlays === null) foundHere.push([email, path]);
      screensWithOverlays++;

      /*
       * Filter bars start collapsed, and the date range popover lives inside one.
       *
       * **The same thirty-second trap as the clicks below, in its third form.**
       * `page.click(selector).catch(() => {})` waits the default timeout for a selector that will
       * never appear — and most screens have no filter bar at all. Ask whether it is there first;
       * a page without one is not a finding, it is just a page without one.
       */
      if (await page.$("[data-filter-toggle]")) {
        await clickOrReport(await page.$("[data-filter-toggle]"),
          `${path} @${viewport.label}`, "the filter disclosure", findings);
        await page.waitForTimeout(150);
      }

      popovers += await checkPopovers(page, `${path} @${viewport.label}`, findings);
      if (!await visit(page, path)) continue;
      dialogs += await checkDialogs(page, `${path} @${viewport.label}`, findings);
      natives += await checkNativeConfirms(page, `${path} @${viewport.label}`, findings);
    }
    if (withOverlays === null) withOverlays = foundHere;
    await page.close();
  }

  console.log(`\n${dialogs} dialog(s) and ${popovers} popover(s) opened across ${PAGES.length} screens (${screensWithOverlays} with something to open) at ${VIEWPORTS.map((v) => v.label).join(" and ")}`);
  console.log(`${natives} native browser confirm(s) found\n`);
  if (findings.length === 0) {
    console.log("no findings");
  } else {
    findings.forEach((f) => console.log("  " + f));
    console.log(`\n${findings.length} finding(s)`);
  }

  await browser.close();
  process.exit(findings.length === 0 ? 0 : 1);
})();
