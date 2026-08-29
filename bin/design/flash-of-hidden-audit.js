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
const PASSWORD = process.env.SEED_PASSWORD || "password!";

// Pages carrying a controller that hides something in `connect()`.
const PAGES = {
  bank: ["/distributions/new", "/donations/new", "/purchases/new", "/manage/edit",
         "/partners/new", "/partner_groups/new", "/audits/new"],
  super: ["/admin/users/1/edit", "/admin/users/new"]
};

const ROLES = { bank: "org_admin1@example.com", super: "superadmin@example.com" };

async function signIn(page, email) {
  await page.goto(BASE + "/users/sign_out", { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.goto(BASE + "/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", PASSWORD);
  await Promise.all([page.waitForNavigation(), page.click("input[type=submit], button[type=submit]")]);
}

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

  for (const [role, email] of Object.entries(ROLES)) {
    const context = await browser.newContext({ viewportSize: { width: 1400, height: 900 } });
    const page = await context.newPage();
    await signIn(page, email);

    for (const path of PAGES[role]) {
      // `commit` rather than `load`: the point is to look before scripts have run.
      const resp = await page.goto(BASE + path, { waitUntil: "commit" }).catch(() => null);
      if (!resp || resp.status() !== 200) continue;
      checked++;

      const first = await page.evaluate(VISIBLE).catch(() => []);
      await page.waitForLoadState("networkidle").catch(() => {});
      await page.waitForTimeout(900);
      const settled = await page.evaluate(VISIBLE).catch(() => []);

      const settledKeys = new Set(settled.map((e) => e.key));
      first
        // select2 replaces a <select> with its own container, which is a swap rather than a hide.
        .filter((e) => !settledKeys.has(e.key))
        .filter((e) => e.tag !== "SELECT")
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
