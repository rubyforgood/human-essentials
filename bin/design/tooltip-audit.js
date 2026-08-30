// Checks that an icon-only control says what it is, and says it the app's way.
//
// Once an inline actions column became two 28px icons, the label had to come back somehow. The
// `title` attribute is not it: it is browser chrome, it shows nothing on keyboard focus, and it
// fails WCAG 1.4.13 three ways (not dismissible, not hoverable, not persistent). Carbon, Primer,
// MUI, Ant Design, Salesforce and Atlassian all use a component tooltip and none uses `title`.
//
// Four assertions, per icon-only control in an actions column:
//
//   1. NAMED      -- it has an accessible name, from `aria-label` or its text.
//   2. TOOLTIP    -- it has `data-tooltip`, so a sighted user can find out what it does.
//   3. NO TITLE   -- and no `title`, which would draw a second tooltip on top of ours.
//   4. AGREES     -- the tooltip and the accessible name say the same thing.
//
// Then, once, in a real browser: the bubble appears on **keyboard focus**, is `aria-hidden` so the
// action is not announced twice, and Escape dismisses it.
//
// Usage: pw bin/design/tooltip-audit.js
const { chromium } = require("playwright");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";

const PAGES = {
  bank: ["/donations", "/transfers", "/product_drive_participants", "/purchases", "/product_drives",
         "/kits", "/manufacturers", "/barcode_items", "/item_categories", "/adjustments",
         "/distributions", "/items", "/audits", "/vendors", "/requests", "/donation_sites",
         "/storage_locations", "/partners", "/broadcast_announcements"],
  super: ["/admin/organizations", "/admin/users", "/admin/base_items", "/admin/partners",
          "/admin/barcode_items", "/admin/broadcast_announcements"]
};
const ROLES = { bank: "org_admin1@example.com", super: "superadmin@example.com" };

async function signIn(page, email) {
  await page.goto(BASE + "/users/sign_out", { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.goto(BASE + "/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", PASSWORD);
  await Promise.all([page.waitForNavigation(), page.click("input[type=submit], button[type=submit]")]);
}

const COLLECT = () => [...document.querySelectorAll("main .cell-actions a, main .cell-actions button")]
  .filter((el) => !el.closest("[role='menu']"))          // menu items carry visible labels
  .map((el) => {
    const text = (el.textContent || "").replace(/\s+/g, " ").trim();
    return {
      what: el.getAttribute("aria-label") || text || "(unnamed)",
      iconOnly: text === "",
      // The kebab is a menu trigger, not an action. It is already identifiable from
      // `aria-haspopup`, and a tooltip repeating "More actions for <this row>" on every row is
      // noise rather than help -- the menu it opens carries the labels.
      trigger: el.hasAttribute("aria-haspopup"),
      named: Boolean(el.getAttribute("aria-label") || text),
      tooltip: el.dataset.tooltip || null,
      title: el.getAttribute("title"),
      agrees: !el.dataset.tooltip || el.dataset.tooltip === (el.getAttribute("aria-label") || text)
    };
  });

(async () => {
  const browser = await chromium.launch();
  let controls = 0, iconOnly = 0, defects = 0;

  for (const [role, paths] of Object.entries(PAGES)) {
    const ctx = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
    const page = await ctx.newPage();
    await signIn(page, ROLES[role]);

    for (const path of paths) {
      await page.goto(BASE + path, { waitUntil: "networkidle" }).catch(() => {});
      const found = await page.evaluate(COLLECT).catch(() => []);
      const bad = [];
      for (const c of found) {
        controls++;
        if (c.iconOnly && !c.trigger) iconOnly++;
        if (!c.named) bad.push(`unnamed control`);
        if (c.iconOnly && !c.trigger && !c.tooltip) bad.push(`"${c.what}" is icon-only with no data-tooltip`);
        if (c.title) bad.push(`"${c.what}" still carries title="${c.title}"`);
        if (!c.agrees) bad.push(`"${c.what}" tooltip says "${c.tooltip}"`);
      }
      // Dedupe: a table repeats the same defect once per row.
      const unique = [...new Set(bad)];
      defects += unique.length;
      if (found.length) {
        console.log(`  ${unique.length ? "FAIL" : "ok  "} ${path.padEnd(30)} ${found.length} controls, ` +
          `${found.filter((c) => c.iconOnly && !c.trigger).length} icon-only, ` +
          `${found.filter((c) => c.trigger).length} menu triggers`);
        unique.forEach((b) => console.log(`       ${b}`));
      }
    }
    await ctx.close();
  }

  // The behaviour `title` cannot do, checked once rather than asserted in prose.
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await ctx.newPage();
  await signIn(page, ROLES.bank);
  await page.goto(BASE + "/donations", { waitUntil: "networkidle" });
  const sel = "main .cell-actions [data-tooltip]";
  await page.evaluate((s) => document.querySelector(s).focus(), sel);
  await page.waitForTimeout(150);
  const onFocus = await page.evaluate(() => {
    const b = document.querySelector(".tip-bubble");
    return b && { text: b.textContent, ariaHidden: b.getAttribute("aria-hidden") };
  });
  await page.keyboard.press("Escape");
  await page.waitForTimeout(150);
  const afterEscape = await page.evaluate(() => Boolean(document.querySelector(".tip-bubble")));
  await ctx.close();
  await browser.close();

  console.log("\nbehaviour a `title` cannot manage:");
  const behaviour = [];
  if (!onFocus) behaviour.push("nothing appears on keyboard focus");
  else if (onFocus.ariaHidden !== "true") behaviour.push("the bubble is not aria-hidden, so the action is announced twice");
  if (afterEscape) behaviour.push("Escape does not dismiss it");
  behaviour.forEach((b) => console.log(`  FAIL ${b}`));
  if (!behaviour.length) console.log("  ok   appears on keyboard focus, aria-hidden, dismissed by Escape");
  defects += behaviour.length;

  console.log(`\n${controls} row-action controls, ${iconOnly} icon-only, ${defects} defects.`);
  process.exit(defects ? 1 : 0);
})();
