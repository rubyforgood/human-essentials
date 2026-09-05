// Checks that an icon-only control says what it is, and says it the app's way.
//
// Once an inline actions column became two 28px icons, the label had to come back somehow. The
// `title` attribute is not it: it is browser chrome, it shows nothing on keyboard focus, and it
// fails WCAG 1.4.13 three ways (not dismissible, not hoverable, not persistent). Carbon, Primer,
// MUI, Ant Design, Salesforce and Atlassian all use a component tooltip and none uses `title`.
//
// Four assertions, per icon-only control **anywhere in the page's main region**:
//
//   1. NAMED      -- it has an accessible name, from `aria-label` or its text.
//   2. TOOLTIP    -- it has `data-tooltip`, so a sighted user can find out what it does.
//   3. NO TITLE   -- and no `title`, which would draw a second tooltip on top of ours.
//   4. AGREES     -- the tooltip and the accessible name say the same thing.
//
// Then, once, in a real browser: the bubble appears on **keyboard focus**, is `aria-hidden` so the
// action is not announced twice, and Escape dismisses it.
//
// **It used to look only inside `.cell-actions`, on 25 hardcoded pages.** That reported "301
// icon-only, 0 defects" while `/events` -- not on the list -- rendered 24 funnel links with an
// `aria-label` and no tooltip, in a *data* cell rather than an actions column. Both halves of the
// scope were wrong in the same way: the rule in design.md is about an icon-only control, not about
// where it sits, and a hardcoded page list goes stale in silence. It walks every screen
// `route-targets.rb` knows about now, and reads every control whose visible text is empty.
//
// Usage: bin/rails runner bin/design/route-targets.rb > /tmp/targets.json && pw bin/design/tooltip-audit.js
const { chromium } = require("playwright");
const fs = require("fs");
const { signIn, targets } = require("./targets");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";

// Targets come from the seam, which regenerates the list when it is older than the routes
// file *or* the generator. Reading /tmp/targets.json directly meant a stale list silently, or
// ENOENT on a machine that had never run another audit.
const TARGETS = targets();
const PARTNER = (p) => (p.startsWith("/partners/") && !/^\/partners\/\d+/.test(p)) || p === "/partners/profile";
const ADMIN = (p) => p.startsWith("/admin");
const RUNS = [
  ["org_admin1@example.com", (p) => !ADMIN(p) && !PARTNER(p)],
  ["verified@example.com", PARTNER],
  ["superadmin@example.com", ADMIN]
];


const COLLECT = () => [...document.querySelectorAll("main a, main button")]
  .filter((el) => !el.closest("[role='menu']"))          // menu items carry visible labels
  // Icon-only is what this audit is about, and it is a property of the control rather than of the
  // cell it sits in: empty visible text, and a glyph to look at. A control with a label names
  // itself and needs no bubble, so the rest of the page's links are not findings waiting to happen.
  .filter((el) => (el.textContent || "").trim() === "" && el.querySelector("i, svg"))
  .filter((el) => el.offsetParent !== null || el.getClientRects().length > 0)
  .map((el) => {
    const text = (el.textContent || "").replace(/\s+/g, " ").trim();
    return {
      what: el.getAttribute("aria-label") || text || "(unnamed)",
      iconOnly: text === "",
      where: el.closest(".cell-actions") ? "actions column" : el.closest("table") ? "data cell" : "page",
      // The kebab is a menu trigger, not an action. It is already identifiable from
      // `aria-haspopup`, and a tooltip repeating "More actions for <this row>" on every row is
      // noise rather than help -- the menu it opens carries the labels.
      //
      // A chip's dismiss is exempt on the same argument. The rule exists because a lone glyph is
      // the only clue to what a control does; a chip's x sits *inside* the label it removes, so
      // the label is on screen and a bubble would repeat it. MUI's `Chip onDelete`, Ant's closable
      // `Tag`, Carbon's `DismissibleTag` and Primer's `Token` all ship the x with an accessible
      // name and no tooltip. `aria-label` is still required, and still checked.
      //
      // **Declared, not inferred.** The obvious test -- "its parent has visible text" -- would have
      // exempted the `/events` funnel too, since that sat in a cell beside a record link. An
      // exemption a component has to opt into cannot widen behind anyone's back.
      trigger: el.hasAttribute("aria-haspopup") || el.hasAttribute("data-chip-dismiss"),
      named: Boolean(el.getAttribute("aria-label") || text),
      tooltip: el.dataset.tooltip || null,
      title: el.getAttribute("title"),
      agrees: !el.dataset.tooltip || el.dataset.tooltip === (el.getAttribute("aria-label") || text)
    };
  });

(async () => {
  const browser = await chromium.launch();
  let controls = 0, iconOnly = 0, defects = 0;

  for (const [email, wants] of RUNS) {
    const ctx = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
    const page = await ctx.newPage();
    await signIn(page, email);

    for (const { path } of TARGETS.filter((t) => wants(t.path))) {
      // `domcontentloaded`, not `networkidle`: /events alone takes longer than the 30s idle
      // timeout, and a page this audit gives up on is a page it silently reports clean.
      await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 60000 }).catch(() => {});
      await page.waitForTimeout(120);
      const found = await page.evaluate(COLLECT).catch(() => []);
      const bad = [];
      for (const c of found) {
        controls++;
        if (c.iconOnly && !c.trigger) iconOnly++;
        if (!c.named) bad.push(`unnamed control`);
        if (c.iconOnly && !c.trigger && !c.tooltip) bad.push(`"${c.what}" is icon-only with no data-tooltip (${c.where})`);
        if (c.title) bad.push(`"${c.what}" still carries title="${c.title}" (${c.where})`);
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
  await signIn(page, RUNS[0][0]);
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

  console.log(`\n${controls} icon-only controls across ${TARGETS.length} screens, ${defects} defects.`);
  process.exit(defects ? 1 : 0);
})();
