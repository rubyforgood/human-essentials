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
const PAGES = [
  ["org_admin1@example.com", "/requests"],
  ["org_admin1@example.com", "/donations"],
  ["org_admin1@example.com", "/distributions"],
  ["org_admin1@example.com", "/transfers"],
  ["org_admin1@example.com", "/donation_sites"],
  ["org_admin1@example.com", "/vendors"],
  ["org_admin1@example.com", "/product_drives"],
  ["org_admin1@example.com", "/manufacturers"],
  ["org_admin1@example.com", "/dashboard"]
];

async function signIn(page, email) {
  await page.goto(`${BASE}/users/sign_in`, { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", "password!");
  await page.click("input[type=submit], button[type=submit]");
  await page.waitForLoadState("networkidle");
}

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
  const triggers = await page.$$("[data-action*='dialog#open']");

  for (const [i, trigger] of triggers.entries()) {
    const id = await trigger.getAttribute("data-dialog-id-param");
    if (!id || !(await page.$(`[id="${id}"]`))) continue;

    await trigger.click().catch(() => {});
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
    await page.waitForTimeout(200);
    if (await page.evaluate((d) => document.getElementById(d)?.open, id)) {
      findings.push(`${where}: Escape does not close it`);
    }
    void i;
  }
  return triggers.length;
}

async function checkPopovers(page, path, findings) {
  const triggers = await page.$$("[data-popover-target='trigger']");

  for (const trigger of triggers) {
    await trigger.click().catch(() => {});
    await page.waitForTimeout(250);

    // Evaluated against THIS trigger, not the first one on the page -- the account menu is also a
    // popover, and checking it instead reported every date range as broken.
    const state = await trigger.evaluate((t) => {
      if (t.getAttribute("aria-expanded") !== "true") return null;
      const panel = t.closest("[data-controller~='popover']").querySelector("[data-popover-target='panel']");
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
      await page.waitForTimeout(120);
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
  const triggers = await page.$$("[data-confirm], [data-turbo-confirm]");
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
  await triggers[0].click().catch(() => {});
  await page.waitForTimeout(300);

  page.off("dialog", onDialog);
  return seen;
}

(async () => {
  const browser = await chromium.launch();
  const findings = [];
  let dialogs = 0, natives = 0;
  let popovers = 0;

  for (const viewport of VIEWPORTS) {
    const page = await browser.newPage({ viewport: { width: viewport.width, height: viewport.height } });
    let signedInAs = null;

    for (const [email, path] of PAGES) {
      if (signedInAs !== email) {
        await signIn(page, email);
        signedInAs = email;
      }
      await page.goto(BASE + path, { waitUntil: "networkidle" });

      // Filter bars start collapsed, and the date range popover lives inside one.
      await page.click("[data-filter-toggle]").catch(() => {});
      await page.waitForTimeout(150);

      popovers += await checkPopovers(page, `${path} @${viewport.label}`, findings);
      await page.goto(BASE + path, { waitUntil: "networkidle" });
      dialogs += await checkDialogs(page, `${path} @${viewport.label}`, findings);
      natives += await checkNativeConfirms(page, `${path} @${viewport.label}`, findings);
    }
    await page.close();
  }

  console.log(`\n${dialogs} dialog(s) and ${popovers} popover(s) opened across ${PAGES.length} pages at ${VIEWPORTS.map((v) => v.label).join(" and ")}`);
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
