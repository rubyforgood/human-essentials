// Every confirmation in the app, opened and checked for being the app's own dialog.
//
// The app replaces `window.confirm` with a styled `<dialog>`: `confirm_dialog_controller.js`
// catches the click in the *capture* phase before rails-ujs sees it, shows the dialog, and replays
// the click if the answer was yes. When that mechanism is absent -- or when a call site sits
// somewhere the controller cannot reach -- the click falls straight through to rails-ujs and the
// browser draws its own box, with the page's hostname above the message.
//
// Nothing checked all of them. The specs cover the call sites they happen to exercise, through
// `spec/support/confirm_dialog.rb`, and a call site with no spec had nothing watching it: Delete on
// `/product_drives/:id` was one, and it was reported.
//
// A static grep cannot do this. What matters is whether a *native* dialog appears when the button
// is pressed, which is only knowable by pressing it in a browser.
//
// **It never accepts.** Every confirmation is dismissed, so nothing is deleted -- including the
// native one, which is dismissed through Playwright's dialog handler.
//
// Run against a seeded development server: bin/start, then `pw bin/design/confirm-audit.js`.
const { chromium } = require("playwright");
const fs = require("fs");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const TARGETS = JSON.parse(fs.readFileSync(process.env.TARGETS || "/tmp/targets.json", "utf8"));

const PARTNER = (p) => (p.startsWith("/partners/") && !/^\/partners\/\d+/.test(p)) || p === "/partners/profile";
const ADMIN = (p) => p.startsWith("/admin");

async function signIn(page, email) {
  await page.goto(`${BASE}/users/sign_in`, { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", "password!");
  await page.click("input[type=submit], button[type=submit]");
  await page.waitForLoadState("networkidle");
}

// What is on the page that will ask for a confirmation, and how to reach it again after a reload.
//
// A menu panel is `hidden` until its trigger is pressed, and `popover_controller` moves it to
// <body> while it is open. The panel's **id is no handle at all**: `row_actions` builds it from
// `SecureRandom.hex(4)`, so it is different on the next request -- which is what the first draft of
// this audit recorded, and why it reported twenty controls as unreachable that were perfectly
// reachable. The trigger's `aria-label` is stable, because it names the row.
const INVENTORY = () => [...document.querySelectorAll("[data-confirm], [data-turbo-confirm]")]
  .filter((el) => !el.disabled)
  .map((el) => {
    const panel = el.closest('[role="menu"]');
    const trigger = panel ? document.querySelector(`[aria-controls="${panel.id}"]`) : null;
    // The *index* of the trigger, not its name. Four rows on /organization were all called "More
    // actions for Name Not Provided" -- a real defect, since a screen reader user cannot tell them
    // apart, and one this audit had to stop tripping over to be able to report.
    const triggers = [...document.querySelectorAll('[data-popover-target="trigger"]')];
    return {
      triggerIndex: trigger ? triggers.indexOf(trigger) : null,
      // Icon-only row actions carry no text, so the aria-label is the label. Both are recorded,
      // because matching on the wrong one is how the first draft lost four more.
      text: (el.innerText || el.value || "").replace(/\s+/g, " ").trim(),
      aria: el.getAttribute("aria-label") || "",
      triggerLabel: trigger ? trigger.getAttribute("aria-label") : null,
      tone: el.dataset.confirmTone || null,
      message: (el.dataset.confirm || el.dataset.turboConfirm || "").slice(0, 70)
    };
  });

// Mark the one control being tested, so Playwright can send it a real mouse click.
const MARK = ({ text, aria, inPanel }) => {
  const MARKER = "data-confirm-audit";
  document.querySelectorAll(`[${MARKER}]`).forEach((el) => el.removeAttribute(MARKER));
  const candidates = [...document.querySelectorAll("[data-confirm], [data-turbo-confirm]")]
    .filter((el) => !el.disabled)
    .filter((el) => !!el.closest('[role="menu"]') === inPanel)
    .filter((el) => {
      const t = (el.innerText || el.value || "").replace(/\s+/g, " ").trim();
      return (text && t === text) || (aria && el.getAttribute("aria-label") === aria);
    })
    // Visible only. Every *closed* row menu is still in the document and still holds a Reclaim,
    // so matching on the label alone marked a hidden one and the click waited for it forever.
    // Thirty-seven controls reported as unpressable were this, not the app.
    .filter((el) => el.getClientRects().length > 0);
  if (!candidates.length) return false;
  candidates[0].setAttribute(MARKER, "1");
  return true;
};

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await ctx.newPage();

  // Never accept. A native confirm that reaches here is the defect being looked for, and accepting
  // it would submit the destructive form it guards.
  const natives = [];
  page.on("dialog", async (d) => {
    natives.push({ type: d.type(), message: d.message().replace(/\s+/g, " ").trim().slice(0, 90) });
    await d.dismiss();
  });

  const findings = [];
  let controls = 0, pages = 0;

  async function pressAndWatch(path, item) {
    natives.length = 0;
    const res = await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 25000 });
    if (!res || res.status() >= 400) return null;
    await page.waitForTimeout(120);

    if (item.triggerIndex !== null) {
      const trigger = page.locator('[data-popover-target="trigger"]').nth(item.triggerIndex);
      if (!(await trigger.count())) return { ...item, path, verdict: "unreachable: no trigger for its menu" };
      await trigger.click();
      await page.waitForTimeout(180);
    }

    const marked = await page.evaluate(MARK,
      { text: item.text, aria: item.aria, inPanel: item.triggerIndex !== null });
    if (!marked) return { ...item, path, verdict: "unreachable: control not found after reload" };

    await page.locator("[data-confirm-audit]").first().click({ timeout: 8000 });
    await page.waitForTimeout(350);

    const styled = await page.evaluate(() => {
      const d = document.querySelector("[data-confirm-dialog-target='dialog']");
      if (!d || !d.open) return null;
      const t = (s) => { const el = d.querySelector(`[data-confirm-dialog-target='${s}']`); return el ? el.innerText.trim() : null; };
      return { message: t("message"), title: t("title"), accept: t("accept"),
               danger: /rose|red/.test(d.querySelector("[data-confirm-dialog-target='accept']").className) };
    });

    // Put it back however it went: dismiss the styled dialog, or the native one is already gone.
    if (styled) await page.evaluate(() => document.querySelector("[data-confirm-dialog-target='dialog']").close());

    if (natives.length) return { ...item, path, verdict: `NATIVE ${natives[0].type}`, native: natives[0].message };
    if (!styled) return { ...item, path, verdict: "no dialog at all -- the action may have run" };
    if (!styled.message) return { ...item, path, verdict: "styled dialog opened with an empty message" };
    if (item.tone === "danger" && !styled.danger) return { ...item, path, verdict: "destructive, but the confirm button is not the danger tone" };
    return null;
  }

  const runs = [
    ["org_admin1@example.com", (p) => !ADMIN(p) && !PARTNER(p)],
    ["verified@example.com", PARTNER],
    ["superadmin@example.com", ADMIN]
  ];

  for (const [email, wants] of runs) {
    await signIn(page, email);
    for (const t of TARGETS) {
      if (!wants(t.path)) continue;
      let inventory = [];
      try {
        const res = await page.goto(BASE + t.path, { waitUntil: "domcontentloaded", timeout: 25000 });
        if (!res || res.status() >= 400) continue;
        await page.waitForTimeout(100);
        inventory = await page.evaluate(INVENTORY);
      } catch { continue; }
      if (!inventory.length) continue;
      pages++;

      // One label per panel is enough: two items with the same label in the same menu cannot be
      // told apart, and there are none.
      const seen = new Set();
      for (const item of inventory) {
        const key = `${item.triggerIndex}|${item.text}|${item.aria}`;
        if (seen.has(key)) continue;
        seen.add(key);
        controls++;
        let finding;
        try { finding = await pressAndWatch(t.path, item); }
        catch (e) { finding = { ...item, path: t.path, verdict: `could not press: ${String(e).split("\n")[0].slice(0, 70)}` }; }
        if (finding) findings.push(finding);
      }
    }
  }

  await browser.close();

  console.log(`\n${controls} confirmations on ${pages} pages, all dismissed`);
  console.log(`\n-- not the app's own dialog (${findings.length}) --`);
  for (const f of findings) {
    console.log(`  ${f.path}  ${f.text || f.aria || "(unlabelled)"}${f.triggerLabel ? `  (in "${f.triggerLabel}")` : ""}`);
    console.log(`      ${f.verdict}${f.native ? `  -> "${f.native}"` : ""}`);
  }
  if (!findings.length) console.log("  none -- every confirmation is the styled dialog");

  process.exitCode = findings.length ? 1 : 0;
})();
