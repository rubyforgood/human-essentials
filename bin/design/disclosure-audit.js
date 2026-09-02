// Checks every conditionally revealed field against the rule in design.md: a field that only
// applies to one answer is revealed **under the answer that needs it**, marked with an indent and
// a left rule, and is never painted before being hidden.
//
// Reported on /distributions/new: "the location and size of the shipping cost field does not make
// any sense... shouldn't it be below the shipping cost radio button?" It was 529px where every
// other field on the card was 346px, in a second grid beside the radios, 94px *above* the option
// that produces it.
//
// The four things this asserts, per reveal:
//
//   1. BELOW      -- it starts lower than the control that reveals it.
//   2. AFTER      -- it follows that control in the DOM, so Tab reaches it next.
//   3. MARKED     -- it carries the indent and the 4px left rule that say which option owns it.
//   4. IN COLUMN  -- its left edge lands on a grid column, not between two.
//
// Reveals are found by asking the *page*, not the source: anything a Stimulus controller can
// toggle `hidden` on, which is every element carrying a target name ending in the conventional
// shapes below. A source grep would miss a reveal built out of a target named something else.
//
// Usage: pw bin/design/disclosure-audit.js
const { chromium } = require("playwright");
const { targets, signIn, visit, RUNS } = require("./targets");

/*
 * **Every screen, not a list of five.** This used to name four bank pages and one admin page, and
 * a conditionally revealed field on any other screen was invisible to it -- which is the same
 * blindness that let the tooltip audit report 0 defects while there were 14. The check already
 * skips a page with no reveals on it, so widening costs nothing but time and can only find more.
 */

const COLLECT = () => {
  // A reveal is an element some control points at with aria-controls, plus the two legacy shapes
  // that predate the component -- so a reveal that has *not* been migrated still gets audited
  // rather than quietly dropping out of the report.
  const byAria = [...document.querySelectorAll("main [aria-controls]")]
    .map((t) => ({ trigger: t, panel: document.getElementById(t.getAttribute("aria-controls")) }))
    .filter((r) => r.panel && ["INPUT", "SELECT"].includes(r.trigger.tagName));

  const legacy = [...document.querySelectorAll("main [data-conditional-reveal]," +
    "main [data-hide-by-source-val-target='destination']," +
    "main [data-checkbox-with-nested-element-target='nestedElement']")]
    .filter((p) => !byAria.some((r) => r.panel === p))
    .map((p) => ({ trigger: null, panel: p }));

  const box = (e) => { const r = e.getBoundingClientRect();
    return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width) }; };

  // Every grid column line on the card, to check the *trigger* sits in a column.
  const columns = new Set();
  document.querySelectorAll("main .grid").forEach((g) => {
    let x = g.getBoundingClientRect().x;
    const cs = getComputedStyle(g);
    const gap = parseFloat(cs.columnGap) || 0;
    cs.gridTemplateColumns.split(" ").forEach((c) => {
      columns.add(Math.round(x));
      x += parseFloat(c) + gap;
    });
  });

  // A reveal nested inside another reveal measures 0x0 while its ancestor is collapsed, which
  // reads as "sits above its trigger" and is an artefact of the measurement, not a defect. So
  // un-hide the whole chain, measure, and put every one of them back.
  const withRevealed = (el, fn) => {
    const restored = [];
    for (let n = el; n && n !== document.body; n = n.parentElement) {
      if (n.classList && n.classList.contains("hidden")) { n.classList.remove("hidden"); restored.push(n); }
    }
    try { return fn(); } finally { restored.forEach((n) => n.classList.add("hidden")); }
  };

  return [...byAria, ...legacy].map(({ trigger, panel }) => {
    const cs = getComputedStyle(panel);
    const startsHidden = panel.classList.contains("hidden");

    const m = withRevealed(panel, () => {
      const p = box(panel);
      const field = panel.querySelector("input:not([type=hidden]), select, textarea");
      const label = trigger && document.querySelector(`label[for='${trigger.id}']`);
      return { p, f: field ? box(field) : null, t: trigger ? box(trigger) : null,
               labelX: label ? Math.round(label.getBoundingClientRect().x) : null };
    });

    return {
      id: panel.id || "(no id)",
      trigger: trigger ? (trigger.id || trigger.name) : null,
      triggerTag: trigger ? trigger.tagName + (trigger.type ? ":" + trigger.type : "") : null,
      inTable: Boolean(panel.closest("td, th")),
      // "plain" is the documented exception: content that already carries its own box -- a
      // callout -- is positioned under its trigger but not indented or ruled, because marking
      // one relationship twice is noise. The component says which it is, so this is read rather
      // than guessed.
      plain: panel.dataset.conditionalReveal === "plain",
      startsHidden,
      below: m.t ? m.p.y > m.t.y : null,
      after: trigger ? Boolean(trigger.compareDocumentPosition(panel) & Node.DOCUMENT_POSITION_FOLLOWING) : null,
      rule: parseFloat(cs.borderLeftWidth) || 0,
      indent: (parseFloat(cs.marginLeft) || 0) + (parseFloat(cs.borderLeftWidth) || 0) +
              (parseFloat(cs.paddingLeft) || 0),
      // The rule hangs off the trigger's own left edge: 6px in, so a 4px rule is centred under a
      // 16px radio. This is what catches a reveal parked in a column of its own -- the shipping
      // cost field was 549px to the right of the radios that produced it.
      offsetFromTrigger: m.t ? m.p.x - m.t.x : null,
      fieldX: m.f ? m.f.x : null,
      labelX: m.labelX,
      triggerX: m.t ? m.t.x : null,
      // Only meaningful where the trigger is actually laid out on a grid: several forms are a
      // plain stacked card, where there are no column lines to land on.
      //
      // **And only where it is laid out at all.** A trigger inside a collapsed accordion has a
      // zero-size rect at the origin, so its left edge is 0 and matches no column -- reported as
      // "trigger left edge 0 is on no grid column" the first time this audit was widened beyond
      // the five pages it used to know about. An element with no box cannot be misaligned.
      triggerOnColumn: (trigger && trigger.offsetParent !== null && trigger.closest("main .grid"))
        ? [...columns].some((c) => Math.abs(c - m.t.x) <= 1) : null,
      // A radio or checkbox has its label beside it, so the revealed field should line up with
      // that label. A select's label sits above it at the same left edge, so it should not.
      labelBeside: Boolean(trigger && ["radio", "checkbox"].includes(trigger.type))
    };
  });
};

(async () => {
  const browser = await chromium.launch();
  let found = 0, defects = 0;

  let visited = 0;
  for (const [email, wants] of RUNS) {
    const ctx = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
    const page = await ctx.newPage();
    await signIn(page, email);

    for (const { path } of targets().filter((t) => wants(t.path))) {
      // `visit` waits for `load`, never `networkidle`: three form pages here take longer than the
      // 30s idle timeout, and a page an audit gives up on is a page it reports as clean.
      if (!await visit(page, path)) continue;
      visited++;
      const reveals = await page.evaluate(COLLECT);
      if (!reveals.length) continue;

      console.log(`\n${path}`);
      for (const r of reveals) {
        found++;
        const bad = [];
        if (r.trigger === null) bad.push("no aria-controls from its trigger");
        if (r.below === false) bad.push("sits ABOVE the control that reveals it");
        if (r.after === false) bad.push("comes BEFORE its trigger in the DOM");
        // A table cell's position is fixed by its column, so the indent and rule do not apply.
        const exempt = r.inTable || r.plain;
        if (!exempt && r.rule < 4) bad.push(`no left rule (${r.rule}px)`);
        if (!exempt && r.indent < 20) bad.push(`not indented (${r.indent}px)`);
        if (!exempt && r.offsetFromTrigger !== null && r.offsetFromTrigger !== 6) {
          bad.push(`hangs ${r.offsetFromTrigger}px off its trigger, not 6px -- it is not under it`);
        }
        if (r.triggerOnColumn === false) bad.push(`trigger left edge ${r.triggerX} is on no grid column`);
        if (r.labelBeside && r.labelX !== null && r.fieldX !== null && Math.abs(r.labelX - r.fieldX) > 1) {
          bad.push(`field at ${r.fieldX} does not line up with its option's label at ${r.labelX}`);
        }
        defects += bad.length ? 1 : 0;
        const mark = bad.length ? "FAIL" : "ok  ";
        console.log(`  ${mark} ${r.id}` +
          (r.triggerTag ? `  <- ${r.triggerTag} ${r.trigger}` : "") +
          (r.inTable ? "  [table cell]" : "") + (r.plain ? "  [plain: carries its own box]" : "") +
          `  indent ${r.indent}px, rule ${r.rule}px`);
        bad.forEach((b) => console.log(`       ${b}`));
      }
    }
    await ctx.close();
  }

  await browser.close();
  // The page count is part of the finding: "0 defects" means nothing without it.
  console.log(`\n${visited} screens, ${found} conditional reveals, ${defects} with a defect.`);
  process.exit(defects ? 1 : 0);
})();
