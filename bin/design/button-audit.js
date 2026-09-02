// Audits every page header against the rule design.md already settles:
//
//   "At most three actions, exactly one of them primary, primary last."
//   "A page has one place for its main action. If a fourth button appears, that is the signal
//    that something else is wrong -- usually a section of the page wanting an action of its own."
//
// That rule was written down and never enforced, which is how /requests came to carry four.
// design.md anticipated the audit -- "the actions container carries `data-page-header='actions'`
// so a spec can count what is in it" -- but nothing ever counted.
//
// A static check cannot do this. Half these actions are conditional on a role or on a count being
// above zero, so the number of buttons a header carries is only knowable once it is rendered with
// real data. /requests shows three to an ORG_USER and four to an ORG_ADMIN.
//
// Run against a seeded development server: bin/start, then `pw bin/design/button-audit.js`.
const { chromium } = require("playwright");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";

/*
 * **Every screen, in four passes.** The list here named 43 paths and went stale -- `/users` was on
 * it and has since been deleted.
 *
 * Four rather than the usual three: a plain organization user sees a different set of buttons from
 * an admin, and half the point of this audit is that the same action looks the same wherever it
 * appears. The module supplies the three standard passes; the fourth is composed here because it is
 * this audit's concern, not everybody's.
 */
const { targets, signIn, visit, RUNS, BANK } = require("./targets");

const PASSES = [...RUNS, ["user_1@example.com", BANK]];


async function auditPage(page, path) {
  const res = await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 25000 });
  if (!res || res.status() >= 400) return { path, skipped: `HTTP ${res && res.status()}` };
  await page.waitForTimeout(120);

  return {
    path,
    ...(await page.evaluate(() => {
      // The container is only rendered when there are actions, so its absence means "a header
      // carrying none" rather than "no header" -- which is a different defect, and page-audit's.
      const box = document.querySelector('[data-page-header="actions"]');
      if (!box) return { header: !!document.querySelector("h1"), noActions: true };

      // The variant survives only in the classes the helper emitted, so it is read back from them.
      const variantOf = (el) => {
        const c = el.className;
        if (c.includes("bg-brand-600")) return "primary";
        if (c.includes("bg-rose-600")) return "danger";
        if (c.includes("border-slate-300")) return "secondary";
        if (c.includes("hover:bg-rose-50")) return "ghost-danger";
        if (c.includes("hover:bg-slate-100")) return "ghost";
        return "unknown";
      };

      // A "More actions" trigger is one action however many items hang off it.
      const actions = [...box.querySelectorAll("a, button")].filter((el) => {
        if (el.closest('[role="menu"]')) return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      });

      // design.md fixes the control height at 38px. A variant without a border used to come out
      // 36, so a primary next to a secondary was 2px short -- invisible until a header had few
      // enough buttons to sit on one row.
      const offHeight = [...document.querySelectorAll("a, button")]
        .filter((el) => {
          const c = el.className.toString();
          return c.includes("inline-flex") && c.includes("rounded-lg") && c.includes("px-3.5");
        })
        .map((el) => Math.round(el.getBoundingClientRect().height))
        .filter((h) => h > 2 && h !== 38);

      return {
        header: true,
        count: actions.length,
        variants: actions.map(variantOf),
        offHeight,
        labels: actions.map((el) => el.textContent.trim().replace(/\s+/g, " ").slice(0, 44))
      };
    }))
  };
}

(async () => {
  const browser = await chromium.launch();
  const results = [];
  for (const [email, wants] of PASSES) {
    const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
    await signIn(page, email);
    for (const { path } of targets().filter((t) => wants(t.path))) {
      try {
        results.push({ role: email.split("@")[0], ...(await auditPage(page, path)) });
      } catch (e) {
        results.push({ role: email.split("@")[0], path, skipped: e.message.slice(0, 40) });
      }
    }
    await page.close();
  }
  await browser.close();

  const seen = results.filter((r) => r.header && !r.noActions);
  const tooMany = seen.filter((r) => r.count > 3);
  const manyPrimary = seen.filter((r) => r.variants.filter((v) => v === "primary").length > 1);
  const primaryNotLast = seen.filter(
    (r) => r.variants.includes("primary") && r.variants[r.variants.length - 1] !== "primary"
  );
  const unknown = seen.filter((r) => r.variants.includes("unknown"));
  const wrongHeight = results.filter((r) => r.offHeight && r.offHeight.length);

  const report = (title, rows, describe) => {
    console.log(`\n${title}: ${rows.length}`);
    rows.forEach((r) => console.log(`  ${r.role.padEnd(12)} ${r.path.padEnd(34)} ${describe(r)}`));
  };

  console.log(`page headers checked:      ${seen.length} across ${PASSES.length} roles`);
  console.log(`headers carrying no action: ${results.filter((r) => r.noActions && r.header).length}`);
  console.log(`pages with no h1 at all:   ${results.filter((r) => r.header === false).length}`);
  console.log(`skipped:                   ${results.filter((r) => r.skipped).length}`);

  report("more than three actions", tooMany, (r) => `${r.count}: ${r.labels.join(" | ")}`);
  report("more than one primary", manyPrimary, (r) => r.labels.join(" | "));
  report("primary is not last", primaryNotLast, (r) => `${r.variants.join(",")} -- ${r.labels.join(" | ")}`);
  report("a variant the helper never emits", unknown, (r) => r.labels.join(" | "));
  report("not the 38px control height", wrongHeight, (r) => `${r.offHeight.join(", ")}px`);

  const bad = tooMany.length + manyPrimary.length + primaryNotLast.length + unknown.length +
    wrongHeight.length;
  console.log(`\n${bad} finding(s)`);
  process.exit(0);
})();
