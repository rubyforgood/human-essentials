// The six criteria WCAG 2.2 added at A and AA, which nothing else here checks.
//
// `wcag-audit.js` runs axe against **WCAG 2.1** and `wcag-manual.js` names 2.1 criteria. WCAG 2.2
// has been a W3C Recommendation since 5 October 2023 and adds six A/AA success criteria; this app
// already covers one of them (2.5.8 Target Size, in design.md and the row-action rules) and had no
// check at all for the other five. A suite that reports zero against a superseded version of the
// standard is the most comfortable kind of wrong.
//
//   2.4.11 Focus Not Obscured (Minimum)  AA  a focused control is not *entirely* hidden by
//                                            author content -- sticky bars, floating rails.
//   2.5.7  Dragging Movements            AA  anything draggable can also be operated with a
//                                            single pointer without dragging.
//   3.2.6  Consistent Help               A   a help mechanism on several pages appears in the
//                                            same relative order on each.
//   3.3.7  Redundant Entry               A   information already given in a process is not asked
//                                            for again, unless it is re-entered on purpose.
//   3.3.8  Accessible Authentication     AA  no cognitive function test without an alternative;
//                                            in practice, the password field must accept paste.
//
// 4.1.1 Parsing was **removed** in 2.2 and is deliberately not checked.
//
// Usage: bin/rails runner bin/design/route-targets.rb > /tmp/targets.json && pw bin/design/wcag22-audit.js
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

/*
 * How many things each check actually looked at.
 *
 * A check that examines nothing reports no failures, which is indistinguishable from a check that
 * examined everything and found nothing wrong -- and that is exactly how 3.3.7 came to be printed
 * in the pass line with no implementation behind it. It is also how `consistentHelp` tested nothing
 * for two of the three roles while matching on an href only one of them has.
 *
 * Every check declares itself here and increments as it goes; a zero at the end is a failure.
 */
const EXAMINED = {
  "2.4.11 Focus not obscured": 0,
  "2.5.7 Dragging movements": 0,
  "3.2.6 Consistent help": 0,
  "3.3.7 Redundant entry": 0,
  "3.3.8 Accessible authentication": 0
};
const saw = (check, n = 1) => { EXAMINED[check] += n; };

const findings = [];
// Swappable, so `audit-selftest.js` can run one check in isolation. See the note there.
let sink = (criterion, where, detail) => findings.push({ criterion, where, detail });
const record = (...args) => sink(...args);
const captureInto = (fn) => { sink = fn; };


async function visit(page, path) {
  const res = await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 60000 })
    .catch(() => null);
  if (!res || res.status() >= 400) return false;
  await page.waitForTimeout(150);
  return true;
}

/*
 * 2.4.11 Focus Not Obscured (Minimum), AA.
 *
 * Tab through the page and, at each stop, ask whether the focused control still has a pixel of
 * itself on top. "Minimum" allows partial obscuring -- it is *entirely* hidden that fails -- so the
 * test samples a grid over the control's box and passes if the topmost element at any one of those
 * points is the control or something inside it.
 *
 * The suspects in this app are `position: fixed`: the scroll rail rides the bottom of the window at
 * z-index 20 whenever a table runs past the fold, and the sidebar is fixed the full height.
 */
const OBSCURED = () => {
  const el = document.activeElement;
  if (!el || el === document.body) return null;
  const r = el.getBoundingClientRect();
  if (r.width === 0 || r.height === 0) return null;

  const xs = [r.left + 2, r.left + r.width / 2, r.right - 2];
  const ys = [r.top + 2, r.top + r.height / 2, r.bottom - 2];
  const covering = new Set();
  let tested = 0, showing = 0;

  for (const x of xs) {
    for (const y of ys) {
      if (x < 0 || y < 0 || x > window.innerWidth || y > window.innerHeight) continue;
      tested++;
      const top = document.elementFromPoint(x, y);
      if (!top) continue;
      // The control itself, something inside it, or a wrapper it sits in: all visible.
      if (top === el || el.contains(top) || top.contains(el)) showing++;
      else covering.add(top.className ? `.${String(top.className).split(" ")[0]}` : top.tagName);
    }
  }

  if (tested === 0 || showing > 0) return null;
  return {
    what: el.getAttribute("aria-label") || (el.textContent || "").trim().slice(0, 40) ||
      el.name || el.tagName,
    by: [...covering].join(", ")
  };
};

async function focusNotObscured(page, path) {
  saw("2.4.11 Focus not obscured");
  await page.evaluate(() => document.body.focus());
  for (let i = 0; i < 60; i++) {
    await page.keyboard.press("Tab");
    const hit = await page.evaluate(OBSCURED).catch(() => null);
    if (hit) {
      record("2.4.11 Focus not obscured", path, `"${hit.what}" is completely covered by ${hit.by}`);
      return;                                    // one report per page is enough to act on
    }
    const wrapped = await page.evaluate(() => document.activeElement === document.body);
    if (wrapped && i > 0) break;
  }
}

/*
 * 2.5.7 Dragging Movements, AA.
 *
 * Anything operable by dragging must also be operable with a single pointer that does not drag --
 * a click, a tap, a press. The app's one draggable thing is the scroll rail's thumb, and the
 * question is whether the track it sits in responds to a plain click.
 */
async function draggingHasAnAlternative(page, path) {
  const rail = await page.$(".table-rail-track");
  if (!rail) return;
  saw("2.5.7 Dragging movements");

  const region = await page.$(".table-scroll");
  // Back to the start first. `focusNotObscured` has just tabbed through the page, which scrolls the
  // region sideways to reveal each focused cell -- so by the time this runs the table can already
  // be at its maximum, and a click toward the far end moves nothing. That reported `/items` as
  // failing a criterion it passes.
  await region.evaluate((r) => { r.scrollLeft = 0; });
  await page.waitForTimeout(120);
  const before = await region.evaluate((r) => r.scrollLeft);

  // A single click on the track, **clear of the thumb**, with no drag at all. Aiming at a fixed
  // fraction of the track does not do: where a table only just overflows the thumb is nearly the
  // whole track -- 95% of it on `/items/quantity_and_location` -- so a click at 85% lands on the
  // thumb, the handler correctly ignores it, and the audit reported a passing app as failing.
  const target = await page.evaluate(() => {
    const t = document.querySelector(".table-rail-track");
    const thumb = document.querySelector(".table-rail-thumb");
    const tb = t.getBoundingClientRect(), hb = thumb.getBoundingClientRect();
    const rightGap = tb.right - hb.right, leftGap = hb.left - tb.left;
    if (Math.max(rightGap, leftGap) < 8) return null;     // no track to click: nothing to test
    const x = rightGap >= leftGap ? hb.right + rightGap / 2 : tb.left + leftGap / 2;
    return { x, y: tb.top + tb.height / 2 };
  });
  if (!target) return;

  await page.mouse.click(target.x, target.y);
  await page.waitForTimeout(250);
  const after = await region.evaluate((r) => r.scrollLeft);

  if (after === before) {
    record("2.5.7 Dragging movements", path,
      "the scroll rail moves only by dragging its thumb; a click on the track does nothing");
  }

  // And the keyboard path, which is the other half of why the rail is allowed to exist at all.
  const reachable = await page.evaluate(() =>
    document.querySelector(".table-scroll")?.getAttribute("tabindex") === "0");
  if (!reachable) {
    record("2.5.7 Dragging movements", path, "the scrollable region is not focusable");
  }
}

/*
 * 3.2.6 Consistent Help, A.
 *
 * If a help mechanism is on more than one page, it is in the same place in the order on each.
 *
 * Two wrong measures were tried first, and both are worth naming because they are the obvious ones.
 *
 * **Its index as a fraction of the page's focusables.** The fraction is not the quantity the
 * criterion is about: the help link sits at the same spot on every page here, and dividing by the
 * total turned that into 12% on `/admin/base_items`, which has 111 focusables, against 62% on
 * `/help`, which has 21. Same place, different page lengths, reported as a failure.
 *
 * **Its absolute index in the tab order.** Closer, and still wrong, because the sidebar expands the
 * section you are in -- so five more nav links precede the help link on `/donations` than on
 * `/help`. A navigation that opens the current section is a state change, not an inconsistency, and
 * the criterion's exception for a change the user initiated covers it.
 *
 * What is actually invariant is the help link's **position from the end of the navigation it lives
 * in**. That does not move when a section above it opens, and it does move if someone puts the link
 * somewhere else. It is also found by accessible name rather than by href: the destination is
 * role-dependent -- bank users get an external user guide, everyone else the in-app `/help` -- so
 * an href test silently checked nothing for two of the three roles.
 */
const HELP_NAMES = ["help", "user guide"];

async function consistentHelp(page, path, seen) {
  const spot = await page.evaluate((names) => {
    const named = (e) =>
      (e.getAttribute("aria-label") || e.textContent || "").replace(/\s+/g, " ").trim().toLowerCase();
    const help = [...document.querySelectorAll("a[href]")]
      .filter((e) => e.offsetParent !== null)
      .find((e) => names.includes(named(e)));
    if (!help) return null;

    const container = help.closest("nav, aside, header") || document.body;
    const inside = [...container.querySelectorAll(
      "a[href], button, input, select, textarea, [tabindex]:not([tabindex='-1'])"
    )].filter((e) => e.offsetParent !== null);

    return {
      container: container.tagName.toLowerCase(),
      fromEnd: inside.length - 1 - inside.indexOf(help),
      label: named(help)
    };
  }, HELP_NAMES);
  if (spot) { saw("3.2.6 Consistent help"); seen.push({ path, ...spot }); }
}

/*
 * 3.3.8 Accessible Authentication (Minimum), AA.
 *
 * A cognitive function test -- remembering or transcribing something -- must have an alternative or
 * a mechanism to help. The one that bites real apps is a password field that blocks paste, which
 * breaks every password manager and forces the user to transcribe. Also checked: the field carries
 * the autocomplete token a manager needs to fill it.
 */
async function accessibleAuthentication(browser) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await ctx.newPage();

  for (const path of ["/users/sign_in", "/users/password/new"]) {
    if (!await visit(page, path)) continue;

    const fields = await page.evaluate(() =>
      [...document.querySelectorAll("input[type=password], input[type=email]")].map((el) => ({
        name: el.name,
        autocomplete: el.getAttribute("autocomplete") || "",
        // An `onpaste` that returns false, or any of the usual paste blockers.
        blocks: Boolean(el.getAttribute("onpaste") || el.getAttribute("oncopy") ||
          el.getAttribute("oncontextmenu"))
      })));

    saw("3.3.8 Accessible authentication", fields.length);
    for (const f of fields) {
      if (f.blocks) record("3.3.8 Accessible authentication", path, `${f.name} blocks paste`);
      if (!f.autocomplete) {
        record("3.3.8 Accessible authentication", path,
          `${f.name} has no autocomplete token, so a password manager cannot fill it`);
      }
    }

    // Paste, for real, rather than inferred from attributes.
    const pw = await page.$("input[type=password]");
    if (pw) {
      await pw.focus();
      await page.evaluate(() => navigator.clipboard === undefined);
      await pw.evaluate((el) => {
        const event = new ClipboardEvent("paste", { bubbles: true, cancelable: true });
        el.dispatchEvent(event);
        el.dataset.pasteDefaultPrevented = String(event.defaultPrevented);
      });
      const prevented = await pw.evaluate((el) => el.dataset.pasteDefaultPrevented === "true");
      if (prevented) record("3.3.8 Accessible authentication", path, "a paste event is cancelled");
    }
  }
  await ctx.close();
}

/*
 * 3.3.7 Redundant Entry, A.
 *
 * Information already given in a process must not be asked for again -- it is auto-populated, or
 * offered to select. The general form of this is not machine-checkable: it needs to know what
 * counts as one process. So this checks the app's real multi-step flows by name, and the summary
 * below says which, rather than claiming the criterion wholesale.
 *
 * **The first version of this file claimed 3.3.7 passed with no check behind it at all** -- named
 * in the header, printed in the pass line, never implemented. A criterion nothing tested is not a
 * criterion that passed.
 *
 * The flow here: a partner's Request becomes a Distribution. `DistributionsController#new` calls
 * `copy_from_request`, so the partner, the items and the quantities the partner already gave must
 * arrive filled in rather than blank.
 */
async function redundantEntry(page, covered) {
  if (!await visit(page, "/requests")) return;

  // The id of any request on the page. The *button* that starts one is a POST that marks the
  // request as being processed, and an audit has no business changing data -- but the page it
  // redirects to is a plain GET, and `DistributionsController#new` does the `copy_from_request`
  // either way. So this reads the same screen a user would see, and writes nothing.
  const id = await page.evaluate(() => {
    const match = [...document.querySelectorAll("a[href^='/requests/']")]
      .map((a) => a.getAttribute("href").match(/^\/requests\/(\d+)$/))
      .find(Boolean);
    return match ? match[1] : null;
  });
  if (!id) return;                          // no request in this data

  const href = `/distributions/new?request_id=${id}`;
  if (!await visit(page, href)) return;
  await page.waitForTimeout(400);
  saw("3.3.7 Redundant entry");
  covered.push("request \u2192 distribution");

  const blank = await page.evaluate(() => {
    const partner = document.querySelector("select[name='distribution[partner_id]']");
    const rows = document.querySelectorAll("[id$='_line_items'] tbody tr, .line-item-row");
    const quantities = [...document.querySelectorAll("input[name*='[quantity]']")]
      .filter((i) => i.offsetParent !== null);
    return {
      partnerEmpty: partner ? !partner.value : null,
      rows: rows.length,
      // Every one blank. The form carries an empty template row for adding a line, so "some are
      // blank" is the normal, correct state and only "none carried over" is a failure.
      quantitiesEmpty: quantities.length > 0 && quantities.every((q) => !q.value)
    };
  });

  if (blank.partnerEmpty) {
    record("3.3.7 Redundant entry", href,
      "the partner the request already names is not filled in on the distribution");
  }
  if (blank.quantitiesEmpty) {
    record("3.3.7 Redundant entry", href,
      "the quantities the partner already asked for arrive blank");
  }
}

module.exports = { captureInto, focusNotObscured, draggingHasAnAlternative, consistentHelp, redundantEntry, signIn, visit };

// Requiring this file must not run the audit: `audit-selftest.js` imports the checks
// above and drives them one at a time against a page it has deliberately broken.
if (require.main === module) {
(async () => {
  const browser = await chromium.launch();

  const runs = [
    ["org_admin1@example.com", (p) => !ADMIN(p) && !PARTNER(p)],
    ["verified@example.com", PARTNER],
    ["superadmin@example.com", ADMIN]
  ];

  const helpSpots = [];
  const processes = [];
  let visited = 0, railed = 0;

  for (const [email, wants] of runs) {
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
    const page = await ctx.newPage();
    await signIn(page, email);

    for (const { path } of TARGETS.filter((t) => wants(t.path))) {
      if (!await visit(page, path)) continue;
      visited++;
      await focusNotObscured(page, path);
      await consistentHelp(page, path, helpSpots);
      if (await page.$(".table-rail-track")) { railed++; await draggingHasAnAlternative(page, path); }
    }
    await ctx.close();
  }

  // 3.2.6: the help link's relative position, compared across every page that has one.
  if (helpSpots.length > 1) {
    const byPlace = {};
    helpSpots.forEach((s) => (byPlace[`${s.container}:${s.fromEnd}`] ||= []).push(s.path));
    const places = Object.keys(byPlace);
    if (places.length > 1) {
      const common = places.reduce((a, b) => (byPlace[a].length >= byPlace[b].length ? a : b));
      places.filter((k) => k !== common).forEach((k) => {
        record("3.2.6 Consistent help", byPlace[k].slice(0, 3).join(", "),
          `help is ${k.split(":")[1]} from the end of the <${k.split(":")[0]}> here, and ` +
          `${common.split(":")[1]} from the end on ${byPlace[common].length} other pages`);
      });
    }
  } else if (helpSpots.length === 0) {
    console.log("note: no /help link found on any page, so 3.2.6 does not apply");
  }

  const bankCtx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const bankPage = await bankCtx.newPage();
  await signIn(bankPage, "org_admin1@example.com");
  await redundantEntry(bankPage, processes);
  await bankCtx.close();

  await accessibleAuthentication(browser);
  await browser.close();

  console.log(`WCAG 2.2 · ${visited} screens · ${railed} with a scroll rail · ` +
    `${helpSpots.length} with a help link\n`);

  // A check that looked at nothing has not passed, whatever its silence suggests.
  const blind = Object.entries(EXAMINED).filter(([, n]) => n === 0);
  blind.forEach(([check]) => record(check, "the whole run", "EXAMINED NOTHING — this check is not testing anything"));
  console.log("examined: " + Object.entries(EXAMINED)
    .map(([c, n]) => `${c.split(" ")[0]}\u00d7${n}`).join("  ") + "\n");

  // What 3.3.7 covered, printed whether or not anything failed. It used to print only in the
  // all-clear branch, so it disappeared exactly when the output was worth reading -- and the line
  // it replaced claimed the criterion passed with no check behind it at all.
  console.log(processes.length
    ? `3.3.7 checked ${processes.length} multi-step process(es): ${processes.join(", ")}`
    : "3.3.7 NOT CHECKED: no multi-step process was reachable in this data");

  if (!findings.length) {
    console.log("2.4.11, 2.5.7, 3.2.6 and 3.3.8: no failures");
  } else {
    const byCriterion = {};
    findings.forEach((f) => (byCriterion[f.criterion] ||= []).push(f));
    for (const [criterion, list] of Object.entries(byCriterion)) {
      console.log(`${criterion} — ${list.length} finding(s)`);
      // Every page that fails, because "and 3 more like these" is exactly the information needed
      // to know whether a fix is complete.
      const seen = new Set();
      list.forEach((f) => {
        const key = `${f.where} ${f.detail}`;
        if (seen.has(key)) return;
        seen.add(key);
        console.log(`  ${f.where.padEnd(38)} ${f.detail}`);
      });
    }
  }
  process.exit(findings.length ? 1 : 0);
})();
}
