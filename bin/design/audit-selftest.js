// Tests the audits, by breaking a page on purpose and by leaving it alone on purpose.
//
// Over two days, five checks in the WCAG audits reported failures the app did not have. Every one
// of them had been "verified" the usual way -- plant the defect it is meant to catch, watch it
// fire -- and every one of them passed that test, because **a check that fires when it should not
// still fires when it should**. Planting a defect proves a check *can* report. It says nothing
// about whether it reports the right thing.
//
// So each check here gets two controls:
//
//   POSITIVE   the page is broken in the way the criterion is about. The check must report.
//              Catches a check that examines nothing -- 3.3.7 was named in an audit's header and
//              printed in its pass line with no implementation behind it at all.
//
//   NEGATIVE   the page is changed in a way that is *not* a violation. The check must stay silent.
//              This is the one that was missing, and it would have caught all five:
//
//                2.5.7   a table that barely overflows, so the thumb fills the track
//                2.5.7   a region already scrolled to its maximum by an earlier check
//                3.2.6   the same navigation on a page with five times the content
//                1.4.12  a page whose labels are `sr-only`, clipped by design
//                2.4.7   a link whose focus ring is transitioned rather than instant
//
// The mutations are injected into a live page rather than written to app files: reversible, fast,
// and they cannot be left behind in a working tree.
//
// Usage: pw bin/design/audit-selftest.js
const { chromium } = require("playwright");
const nodePath = require("path");

const manual = require(nodePath.join(__dirname, "wcag-manual.js"));
const wcag22 = require(nodePath.join(__dirname, "wcag22-audit.js"));
const { signIn } = require("./targets");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";

// A page with a wide table, a scroll rail and the full app shell: everything these checks look at.
const RAILED = "/distributions";


/*
 * Guarantee the structures the checks look for, rather than hoping the page has them.
 *
 * The controls first ran against a development database with a session's worth of data in it, where
 * `/distributions` overflows and grows a scroll rail. On a freshly seeded database it does not, so
 * `.table-rail-track` was null and half the controls threw -- which in CI would have been a red
 * build about nothing. **A self-test that depends on how much data happens to exist is not a test.**
 *
 * Widening the table is honest here: these controls exercise the *checks*, not the app's content,
 * and the rail they need is built by the app's own controller reacting to a real overflow.
 */
async function ensureRail(page) {
  await page.evaluate(() => {
    const region = document.querySelector(".table-scroll");
    if (!region) return;
    const table = region.querySelector("table");
    table.style.width = `${region.clientWidth + 600}px`;
    window.dispatchEvent(new Event("resize"));
  });
  await page.waitForSelector(".table-rail-track", { timeout: 5000 });
  await page.waitForTimeout(200);
}

async function settle(page, path) {
  await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForLoadState("load", { timeout: 15000 }).catch(() => {});
  await page.waitForTimeout(400);
}

/*
 * Each control names the check it exercises, the page to run it on, what to do to that page, and
 * whether the check is expected to report afterwards.
 *
 * `run` receives the page and must call the check. Findings are captured rather than printed: both
 * audits expose `captureInto` for this.
 */
const CONTROLS = [
  // ---- 2.4.11 Focus not obscured -------------------------------------------------------------
  {
    check: "2.4.11", kind: "positive", path: RAILED,
    what: "a fixed bar pinned over the bottom of the window",
    // A real element, not `body::after`: `elementFromPoint` never returns a pseudo-element, so an
    // overlay built that way is invisible to this check and to any check like it. A real sticky
    // bar is a real element, so the control uses one -- and the limitation is worth knowing.
    mutate: async (page) => {
      await page.addStyleTag({ content: "html { scroll-padding-bottom: 0 !important; }" });
      await page.evaluate(() => {
        // A link pinned to the bottom of the window, early in the tab order so it is certainly
        // reached, and a bar over it. Relying on the page's own last row put this at the mercy of
        // how many rows the data happened to have.
        const link = document.createElement("a");
        link.href = "#covered";
        link.textContent = "covered";
        link.style.cssText = "position:fixed;left:20px;bottom:20px;z-index:1;";
        document.body.prepend(link);

        const bar = document.createElement("div");
        bar.style.cssText = "position:fixed;left:0;right:0;bottom:0;height:90px;" +
          "background:#000;z-index:9999;";
        document.body.append(bar);
      });
    },
    run: (page) => wcag22.focusNotObscured(page, "selftest")
  },
  {
    check: "2.4.11", kind: "negative", path: RAILED,
    what: "the page as it ships, scroll rail and frozen columns and all",
    mutate: (page) => ensureRail(page),
    run: (page) => wcag22.focusNotObscured(page, "selftest")
  },

  // ---- 2.5.7 Dragging movements --------------------------------------------------------------
  {
    check: "2.5.7", kind: "positive", path: RAILED,
    what: "the rail's track click handler removed, leaving only the drag",
    // Replacing the track with a clone drops its listeners and keeps the geometry.
    mutate: async (page) => { await ensureRail(page); await page.evaluate(() => {
      const t = document.querySelector(".table-rail-track");
      t.replaceWith(t.cloneNode(true));
    }); },
    run: (page) => wcag22.draggingHasAnAlternative(page, "selftest")
  },
  {
    check: "2.5.7", kind: "negative", path: RAILED,
    what: "a region already scrolled to its maximum, as an earlier check leaves it",
    mutate: async (page) => {
      await ensureRail(page);
      await page.evaluate(() => {
        const r = document.querySelector(".table-scroll");
        r.scrollLeft = r.scrollWidth;
      });
    },
    run: (page) => wcag22.draggingHasAnAlternative(page, "selftest")
  },
  {
    check: "2.5.7", kind: "negative", path: RAILED,
    what: "a table that only just overflows, so the thumb fills almost the whole track",
    mutate: async (page) => {
      await ensureRail(page);
      // Shrink the *table*, not the region. Widening the region pushed the rail's far end off the
      // screen, so the click landed on nothing -- the control was testing the viewport, not the
      // check, and reported a pass as a failure.
      await page.evaluate(() => {
        const r = document.querySelector(".table-scroll");
        const table = r.querySelector("table");
        table.style.width = `${r.clientWidth + 14}px`;
        table.style.minWidth = "0";
        window.dispatchEvent(new Event("resize"));
      });
      await page.waitForTimeout(300);
    },
    run: (page) => wcag22.draggingHasAnAlternative(page, "selftest")
  },

  // ---- 3.2.6 Consistent help -----------------------------------------------------------------
  {
    check: "3.2.6", kind: "positive", path: RAILED,
    what: "an extra focusable after the help link, moving it within its navigation",
    mutate: (page) => page.evaluate(() => {
      const help = [...document.querySelectorAll("a[href]")]
        .find((a) => /^(help|user guide)$/i.test((a.textContent || "").trim()));
      const extra = document.createElement("a");
      extra.href = "#selftest";
      extra.textContent = "selftest";
      help.after(extra);
    }),
    run: async (page, seen) => {
      await wcag22.consistentHelp(page, "mutated", seen);
      return seen;
    },
    // 3.2.6 compares pages, so its finding is produced by the comparison rather than per page.
    compare: true
  },
  {
    check: "3.2.6", kind: "negative", path: RAILED,
    what: "the same navigation on a page carrying five times as much content",
    mutate: (page) => page.evaluate(() => {
      const main = document.querySelector("main");
      for (let i = 0; i < 200; i++) {
        const a = document.createElement("a");
        a.href = "#filler";
        a.textContent = `filler ${i}`;
        main.append(a);
      }
    }),
    run: async (page, seen) => {
      await wcag22.consistentHelp(page, "mutated", seen);
      return seen;
    },
    compare: true
  },

  // ---- 1.4.12 Text spacing -------------------------------------------------------------------
  {
    check: "1.4.12", kind: "positive", path: RAILED,
    what: "a label in a box too small for it once the spacing is applied",
    mutate: (page) => page.evaluate(() => {
      // A dedicated element holding a bare text node. The page's own `h1` wraps its text in a
      // block child, so the heading's `scrollWidth` is that child's border box and does not grow
      // with letter-spacing however much the text does -- a control built on it tested nothing.
      const el = document.createElement("label");
      el.textContent = "A label long enough to stop fitting";
      // `inline-block` first, so it shrinks to its text and can be measured. As a *block* it fills
      // its container, and `scrollWidth` reports the container's width rather than the text's --
      // so sizing the box from that made it far wider than the words and nothing ever clipped.
      el.style.cssText = "display:inline-block;white-space:nowrap;";
      document.querySelector("main").append(el);
      const text = Math.ceil(el.getBoundingClientRect().width);
      // Exactly wide enough now; not wide enough with 0.12em of letter-spacing added.
      el.style.cssText =
        `display:inline-block;white-space:nowrap;overflow:hidden;width:${text + 2}px;`;
    }),
    run: (page) => manual.textSpacing(page, "selftest")
  },
  {
    check: "1.4.12", kind: "negative", path: RAILED,
    what: "a label hidden with the sr-only technique, clipped before and after",
    mutate: (page) => page.evaluate(() => {
      const label = document.createElement("label");
      label.textContent = "Visually hidden label";
      label.style.cssText = "position:absolute;width:1px;height:1px;overflow:hidden;white-space:nowrap;";
      document.querySelector("main").append(label);
    }),
    run: (page) => manual.textSpacing(page, "selftest")
  },

  // ---- 2.4.7 Focus visible -------------------------------------------------------------------
  {
    check: "2.4.7", kind: "positive", path: RAILED,
    what: "every focus indicator suppressed",
    mutate: (page) => page.addStyleTag({ content:
      `*:focus, *:focus-visible { outline: none !important; box-shadow: none !important; }` }),
    run: (page) => manual.keyboard(page, "selftest")
  },
  {
    check: "2.4.7", kind: "negative", path: RAILED,
    what: "a focus ring that transitions in rather than appearing instantly",
    mutate: (page) => page.addStyleTag({ content: `
      main a, main button { transition: outline-width 220ms ease !important; }
      main a:focus-visible, main button:focus-visible {
        outline: 3px solid #4F46E5 !important; outline-offset: 2px !important; }` }),
    run: (page) => manual.keyboard(page, "selftest")
  }
];

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await ctx.newPage();
  await signIn(page, "org_admin1@example.com");

  const wrong = [];
  let ran = 0;

  for (const control of CONTROLS) {
    await settle(page, control.path);

    const reported = [];
    manual.captureInto((criterion, where, detail) => reported.push(`${criterion}: ${detail}`));
    wcag22.captureInto((criterion, where, detail) => reported.push(`${criterion}: ${detail}`));

    /*
     * 3.2.6 compares one page against the others, so a single page cannot fail it. The control
     * gathers the *unmutated* page first and the mutated one second, and the comparison is the
     * same one the audit makes: same place, or not.
     */
    if (control.compare) {
      const seen = [];
      await wcag22.consistentHelp(page, "baseline", seen);
      await control.mutate(page);
      await control.run(page, seen);
      const places = new Set(seen.map((s) => `${s.container}:${s.fromEnd}`));
      if (places.size > 1) reported.push(`3.2.6: help moved (${[...places].join(" vs ")})`);
    } else {
      await control.mutate(page);
      await control.run(page);
    }

    ran++;
    const fired = reported.length > 0;
    const expected = control.kind === "positive";
    const ok = fired === expected;
    console.log(`  ${ok ? "ok  " : "FAIL"} ${control.check.padEnd(7)} ${control.kind.padEnd(8)} ` +
      `${control.what}`);
    if (!ok) {
      wrong.push(control);
      console.log(`       expected ${expected ? "a finding" : "silence"}, got ` +
        (fired ? reported.join(" / ") : "silence"));
    }
  }

  await browser.close();

  const checks = new Set(CONTROLS.map((c) => c.check));
  console.log(`\n${ran} controls over ${checks.size} checks, ${wrong.length} wrong`);
  if (!wrong.length) {
    console.log("every check fires on a real defect and stays quiet on a benign one");
  }
  process.exit(wrong.length ? 1 : 0);
})();
