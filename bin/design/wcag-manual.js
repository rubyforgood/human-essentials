// The WCAG criteria axe cannot check, checked by driving the browser.
//
// axe is static: it inspects a rendered tree. These need something to happen first -- a key
// pressed, a viewport resized, a stylesheet overridden. Each check below names the criterion it
// covers so a failure is traceable to the standard rather than to an opinion.
//
// Run: pw bin/design/wcag-manual.js          the expensive checks over a sample, the cheap ones over
//                                            every screen. ~40s.
//      pw bin/design/wcag-manual.js --all     every check over every screen, in all three roles.
//
// **Why there are two scopes rather than one.** Reflow, 200% zoom, text spacing and a full tab
// traverse each resize the viewport two or three times, so they cost seconds per page where a title
// or a `lang` attribute costs milliseconds. A check nobody runs because it takes minutes is worth
// less than one that runs in the inner loop, so the default samples them -- and `--all` exists
// because sampling is *least* defensible for exactly these checks: reflow and text-spacing failures
// come from one page's content, a wide table or a long unbroken string, so eight pages say almost
// nothing about the other hundred and forty. Widening the cheap checks took 2.4.2 from "0 failures
// on 8 pages" to 14 on 92, which is the same lesson arriving early.
const { chromium } = require("playwright");
const { signIn, targets } = require("./targets");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";

// The expensive checks -- reflow, zoom, text spacing, a full tab traverse -- resize the viewport
// several times per page, so they run over a representative sample rather than the whole app: one
// dashboard, two index tables, a long form, a settings page, a hub and a calendar.
//
// **The cheap per-page checks do not sample.** A page title, a `lang` attribute and a skip link
// cost one evaluate each, and 2.4.2 is partly a question about *uniqueness* -- which eight pages
// cannot answer about a hundred and fifty. Those run over every screen `route-targets.rb` knows
// about; see BROAD below.
const PAGES = [
  ["dashboard", "/dashboard"],
  ["distributions", "/distributions"],
  ["new distribution", "/distributions/new"],
  ["items", "/items"],
  ["partners", "/partners"],
  ["organization settings", "/manage/edit"],
  ["reports hub", "/reports"],
  ["pick ups", "/distributions/schedule"]
];

// Every screen, for the checks that cost nothing.
const ALL = process.argv.includes("--all");

const PARTNER = (p) => (p.startsWith("/partners/") && !/^\/partners\/\d+/.test(p)) || p === "/partners/profile";
const ADMIN = (p) => p.startsWith("/admin");
const ROLES = [
  ["org_admin1@example.com", (p) => !ADMIN(p) && !PARTNER(p)],
  ["verified@example.com", PARTNER],
  ["superadmin@example.com", ADMIN]
];

// From the seam, which regenerates the list rather than returning nothing.
//
// This used to read /tmp/targets.json in a try/catch and fall back to `null`, which made the cheap
// per-page checks run over **zero** screens when the file was absent -- leaving the eight-page
// sample and a summary line that looked like a pass. Narrowing scope on a missing file is the
// failure this suite exists to catch, and it was in the suite.
//
// It costs the property named in the comment above -- running with no `route-targets.rb` -- and
// that property was protecting a case that does not arise: every audit here already needs the Rails
// server up, because it drives it.
const BROAD = targets();


const fails = [];
// The sink is swappable so `audit-selftest.js` can run one check in isolation and see exactly
// what it reported. The audit's own runs push into `fails` exactly as before.
let sink = (criterion, page, detail) => fails.push({ criterion, page, detail });
const record = (...args) => sink(...args);
const captureInto = (fn) => { sink = fn; };

// 1.4.10 Reflow at 320px, and 1.4.4 Resize text at 200% (which is the same page at half width).
//
// NOT measured with documentElement.scrollWidth. That counts the content of a clipped scroll
// container, so a data table inside `overflow-x: auto` reports hundreds of pixels of page overflow
// that no user can scroll to. Chased that for a while: `html { overflow-x: hidden }` did not change
// it, which is the tell. body.scrollWidth and an actual scroll attempt agree with each other and
// with the screen.
//
// Data tables are exempt from 1.4.10 anyway -- the criterion excludes content requiring
// two-dimensional layout -- so what matters is whether the *page* scrolls sideways, not the table.
async function horizontalOverflow(page, label, width, criterion) {
  await page.setViewportSize({ width, height: 800 });
  await page.waitForTimeout(300);

  // Swipe, do not call scrollTo. The three obvious measurements each answer a different question
  // and two of them are wrong:
  //
  //   documentElement.scrollWidth  counts content clipped inside a scroll container. A data table
  //                                in `.table-scroll` makes it report ~1140px on a 320px screen.
  //   body.scrollWidth             stays at the viewport width even when the page does scroll.
  //   window.scrollTo(9999, 0)     gets past `overflow-x: clip` on the root, which a finger
  //                                cannot. This used to be measured, stored in `scrolled`, and
  //                                then never read -- and when it was finally read it reported
  //                                four pages that no user can actually scroll.
  //
  // What is left is to swipe and see whether the page moved, which is the question the criterion
  // is asking. Data tables are exempt from 1.4.10 anyway: it excludes content that requires
  // two-dimensional layout, so the table may scroll inside its own container.
  const anchor = await page.evaluate(() => {
    const h = document.querySelector("main h1, h1");
    return h ? { y: Math.round(h.getBoundingClientRect().top + 8), left: Math.round(h.getBoundingClientRect().left) } : null;
  });
  let moved = 0;
  if (anchor) {
    await page.mouse.move(Math.round(width / 2), Math.max(anchor.y, 90));
    await page.mouse.wheel(900, 0);
    await page.waitForTimeout(250);
    moved = await page.evaluate((before) => {
      const h = document.querySelector("main h1, h1");
      const d = h ? before - Math.round(h.getBoundingClientRect().left) : window.scrollX;
      window.scrollTo(0, 0);
      return d;
    }, anchor.left);
  }

  const outside = await page.evaluate(() => {
    const vw = document.documentElement.clientWidth;
    return [...document.querySelectorAll("main *")]
      .filter((el) => el.getBoundingClientRect().right > vw + 2)
      // Anything inside a horizontal scroller is reachable, which is what the criterion asks.
      // Determined by computed style rather than a class list, so a scroller nobody named still
      // counts -- the Trix toolbar row is one.
      .filter((el) => {
        for (let a = el.parentElement; a && a !== document.body; a = a.parentElement) {
          const ox = getComputedStyle(a).overflowX;
          if (ox === "auto" || ox === "scroll" || ox === "hidden" || ox === "clip") return false;
        }
        return true;
      })
      .slice(0, 3)
      .map((el) => `${el.tagName.toLowerCase()}.${(el.className || "").toString().split(" ")[0]}`);
  });

  if (moved > 2 || outside.length) {
    const parts = [];
    if (moved > 2) parts.push(`swipes ${moved}px sideways`);
    if (outside.length) parts.push("outside any scroller: " + outside.join(", "));
    record(criterion, label, `${parts.join("; ")} at ${width}px`);
  }
  await page.setViewportSize({ width: 1280, height: 900 });
}

const reflow = (page, label) => horizontalOverflow(page, label, 320, "1.4.10 Reflow");
const zoom = (page, label) => horizontalOverflow(page, label, 640, "1.4.4 Resize text");

// 1.4.12 Text spacing: applying the required spacing must not clip content.
async function textSpacing(page, label) {
  /*
   * 1.4.12 asks that applying the required spacing causes **no loss of content or functionality**.
   * The loss is the point, so this measures twice: what is already clipped before the override, and
   * what is clipped after. Only the difference is a finding.
   *
   * Measuring once reported `sr-only` labels on the two partner request forms -- 1px wide with
   * `overflow: hidden`, which is the visually-hidden technique doing exactly its job. They are
   * clipped before and after, no content is lost, and their text reaches a screen reader in full.
   * A one-shot check cannot tell that apart from a heading that stopped fitting.
   */
  const clippedNow = () => page.evaluate(() =>
    [...document.querySelectorAll("main button, main a, main h1, main h2, main label")]
      .filter((el) => el.scrollWidth > el.clientWidth + 2 && getComputedStyle(el).overflow === "hidden")
      .map((el) => `${el.tagName}:${el.textContent.trim().slice(0, 30)}`));

  const before = new Set(await clippedNow());
  await page.addStyleTag({
    content: `* { line-height: 1.5 !important; letter-spacing: 0.12em !important;
                  word-spacing: 0.16em !important; }
              p { margin-bottom: 2em !important; }`
  });
  await page.waitForTimeout(250);
  const after = (await clippedNow()).filter((el) => !before.has(el));

  if (after.length) {
    record("1.4.12 Text spacing", label,
      `clipped only once the spacing is applied: ${after.slice(0, 3).join(" | ")}`);
  }
}

// 2.1.1 Keyboard and 2.4.7 Focus visible: every interactive element must be reachable by Tab and
// must show focus when it has it.
async function keyboard(page, label) {
  const result = await page.evaluate(() => {
    const interactive = [...document.querySelectorAll(
      "main a[href], main button:not([disabled]), main input:not([type=hidden]):not([disabled]), main select:not([disabled]), main textarea:not([disabled])"
    )].filter((el) => el.offsetParent !== null);
    // tabindex="-1" is correct in three cases, and reporting them is noise:
    //   - a roving-tabindex group: ARIA tabs and toolbars keep one tab stop and use arrow keys
    //   - the original <select> that select2 hides behind its own focusable proxy
    //   - anything inside a closed dialog
    const rovingRole = (el) => ["tab", "menuitem", "radio", "option"].includes(el.getAttribute("role")) ||
      el.closest('[role="toolbar"], [role="tablist"], [role="menu"]') !== null;
    const select2Proxied = (el) => el.tagName === "SELECT" && el.nextElementSibling &&
      /select2/.test(el.nextElementSibling.className || "");
    const unreachable = interactive
      .filter((el) => el.tabIndex < 0 && !rovingRole(el) && !select2Proxied(el))
      .map((el) => `${el.tagName.toLowerCase()}: ${(el.textContent || el.name || "").trim().slice(0, 24)}`);
    return { count: interactive.length, unreachable: unreachable.slice(0, 3) };
  });
  if (result.unreachable.length) {
    record("2.1.1 Keyboard", label, `not reachable by Tab: ${result.unreachable.join(" | ")}`);
  }

  /*
   * Focus the first few and confirm a visible focus indicator.
   *
   * **Two frames between focusing and measuring.** Reading `getComputedStyle` in the same
   * synchronous block as `el.focus()` catches the style mid-recalc where a transition is involved:
   * the privacy policy's links animate their outline, and a same-tick read returned `solid 0px`
   * for a link that does have one -- reported as a failure for a page that had just been fixed.
   * One frame applies `:focus-visible`, the second lets a transition reach a measurable width.
   */
  const noIndicator = await page.evaluate(async () => {
    const frame = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
    const els = [...document.querySelectorAll("main a[href], main button:not([disabled])")]
      .filter((el) => el.offsetParent !== null).slice(0, 8);
    const bad = [];
    for (const el of els) {
      el.focus();
      await frame();
      const s = getComputedStyle(el);
      const hasOutline = s.outlineStyle !== "none" && parseFloat(s.outlineWidth) > 0;
      const hasRing = s.boxShadow !== "none";
      if (!hasOutline && !hasRing) bad.push((el.textContent || "").trim().slice(0, 24));
    }
    return bad;
  });
  if (noIndicator.length) {
    record("2.4.7 Focus visible", label, `no focus indicator: ${noIndicator.join(" | ")}`);
  }
}

// 2.4.1 Bypass blocks: the skip link must exist, take focus, and move focus to the main content.
async function skipLink(page, label) {
  /*
   * A page with autofocus has already moved focus into its form, so the first Tab lands on the
   * next field rather than the skip link. That is the autofocus doing its job, not a missing skip
   * link, so focus goes back to the top of the document before testing.
   *
   * **`blur()` is not enough**, which is what this used to do. Blurring clears the active element
   * but leaves the *sequential focus navigation starting point* where it was, so Tab carried on
   * from the autofocused field regardless -- and five form pages were reported as having no skip
   * link while rendering one as their first tab stop. Focusing the root element moves the starting
   * point with it.
   */
  await page.evaluate(() => {
    document.documentElement.tabIndex = -1;
    document.documentElement.focus();
  });
  await page.keyboard.press("Tab");
  const state = await page.evaluate(() => {
    const el = document.activeElement;
    return { text: (el.textContent || "").trim(), href: el.getAttribute && el.getAttribute("href") };
  });
  if (!/skip/i.test(state.text)) {
    /*
     * 2.4.1 asks for a way past "blocks of content that are repeated on multiple Web pages". A
     * standalone page whose entire repeated header is three links has no block to bypass, and a
     * skip link over it is noise -- the first thing a keyboard user would meet is an offer to skip
     * almost nothing. So the requirement is scaled to what there is to skip.
     *
     * A threshold rather than a list of excused pages: an exclusion list is how an audit quietly
     * stops covering things. The app shell puts thirteen controls ahead of `main` and is well over
     * the line; `/privacypolicy` puts three and is under it.
     */
    const ahead = await page.evaluate(() => {
      const main = document.querySelector("main, #main-content");
      if (!main) return Infinity;
      return [...document.querySelectorAll(
        "a[href], button, input, select, textarea, [tabindex]:not([tabindex='-1'])"
      )].filter((e) => main.compareDocumentPosition(e) & Node.DOCUMENT_POSITION_PRECEDING).length;
    });
    if (ahead > 5) {
      record("2.4.1 Bypass blocks", label,
        `first tab stop is "${state.text.slice(0, 30)}", not a skip link, with ${ahead} controls before main`);
    }
    return;
  }
  await page.keyboard.press("Enter");
  /*
   * Poll, rather than read once after a fixed pause.
   *
   * The assertion is "focus ends up in main", and on the slowest screen in the app -- the new
   * distribution form -- something focusable arrives after the skip link has already moved focus,
   * so a single read 150ms later caught the intermediate state about one run in three. Reproduced
   * by hand three times in a row without failing, which is what a flaky check looks like from the
   * outside. Waiting for the condition is the fix; a longer fixed pause is only a slower guess.
   */
  const landed = await page.waitForFunction(() => {
    const el = document.activeElement;
    if (el && (el.id === "main-content" || el.closest("main"))) return el.id || "inside main";
    return false;
  }, null, { timeout: 3000 }).then((h) => h.jsonValue()).catch(() => page.evaluate(() => {
    const el = document.activeElement;
    return el.id || (el.closest("main") ? "inside main" : el.tagName);
  }));
  if (!/main/i.test(landed)) {
    record("2.4.1 Bypass blocks", label, `skip link moved focus to "${landed}", not the main content`);
  }
}

module.exports = { captureInto, reflow, zoom, textSpacing, keyboard, skipLink, horizontalOverflow, signIn };

// Requiring this file must not run the audit: `audit-selftest.js` imports the checks
// above and drives them one at a time against a page it has deliberately broken.
if (require.main === module) {
(async () => {
  const browser = await chromium.launch();
  const titles = new Map();
  const seenUrls = new Set();
  let expensive = 0, cheap = 0;

  /*
   * One page, and how deeply to look at it. The cheap checks always run; the expensive ones run on
   * the sample, or on everything under `--all`.
   *
   * Splitting *what is checked* from *which pages* is the point: there is one definition of each
   * check, and the scope is an argument. A second script for the thorough run would be a copy, and
   * a copy drifts.
   */
  const inspect = async (page, label, deep) => {
    const res = await page.goto(BASE + label, { waitUntil: "domcontentloaded", timeout: 60000 })
      .catch(() => null);
    /*
     * A page that will not load is reported, not skipped.
     *
     * This used to `return` on any 4xx or 5xx, which means **breaking a page hides it from the
     * audit**: a bad `content_for :title` on `/partners/children/1` produced a 500, the audit
     * skipped it in silence, and the test suite is what caught it. An audit that quietly stops
     * looking at what it cannot load reports its own blind spot as a pass.
     *
     * 404s are excluded because `route-targets.rb` approximates some ids and a few of its guesses
     * genuinely do not exist; a 500 never has an innocent explanation.
     */
    if (!res) { record("did not load", label, "no response"); return; }
    if (res.status() >= 500) { record("server error", label, `HTTP ${res.status()}`); return; }
    if (res.status() >= 400) return;
    /*
     * Wait for `load` before testing anything about focus.
     *
     * `domcontentloaded` plus 150ms is enough to read a title, and not enough to Tab through a page
     * that is still booting: `/distributions/new` is the slowest screen in the app, and a late
     * autofocus arriving after the skip link's Enter made 2.4.1 fail there about one run in three.
     * Reproduced by hand three times in a row and it passed every time, which is the shape of a
     * flaky check rather than a defect. Capped, because `load` never settles on a page holding a
     * long poll -- and `domcontentloaded` has already happened either way.
     */
    await page.waitForLoadState("load", { timeout: 15000 }).catch(() => {});
    await page.waitForTimeout(150);

    // Where it landed, not where it was asked for: `/` redirects to `/dashboard`, and comparing
    // requested paths reported three views of one page as three pages sharing a title.
    const landed = new URL(page.url()).pathname;
    if (seenUrls.has(landed)) return;
    seenUrls.add(landed);

    // 2.4.2 Page titled, and titles distinct enough to tell pages apart.
    const title = await page.title();
    if (!title || title.trim().length < 3) record("2.4.2 Page titled", label, `title is "${title}"`);
    else if (titles.has(title)) record("2.4.2 Page titled", label, `same title as ${titles.get(title)}: "${title}"`);
    else titles.set(title, label);

    // 3.1.1 Language of page.
    const lang = await page.evaluate(() => document.documentElement.getAttribute("lang"));
    if (!lang) record("3.1.1 Language of page", label, "no lang attribute on <html>");

    await skipLink(page, label);
    cheap++;

    if (!deep) { process.stdout.write("."); return; }
    await keyboard(page, label);
    await reflow(page, label);
    await zoom(page, label);
    await textSpacing(page, label);
    expensive++;
    process.stdout.write("#");
  };

  /*
   * One entry per controller action, not per path. `get :admin, to: "admin#dashboard"` gives the
   * same page two URLs with no redirect between them, so the landed-URL check cannot tell they are
   * one page -- and it was reported as two pages sharing a title, which is what a title is *for*.
   * `route-targets.rb` already carries the controller and action.
   */
  const byAction = new Map();
  BROAD.forEach((t) => {
    const key = `${t.controller}#${t.action}`;
    if (!byAction.has(key)) byAction.set(key, t.path);
  });
  const targets = [...byAction.values()];
  const sampled = PAGES.map(([, path]) => path);

  for (const [email, wants] of ROLES) {
    // Without `--all` only the bank admin runs: the sample is all bank pages, and signing in three
    // times to visit nothing would just be slower.
    const mine = ALL ? targets.filter(wants) : (email === ROLES[0][0] ? sampled : []);
    if (!mine.length) continue;

    const page = await browser.newPage({ viewportSize: { width: 1280, height: 900 } });
    await signIn(page, email);

    for (const path of mine) await inspect(page, path, ALL || sampled.includes(path));

    // The cheap pass over the rest, for the default run. Under `--all` there is no rest.
    if (!ALL && email === ROLES[0][0]) {
      for (const path of targets) {
        if (ADMIN(path) || PARTNER(path)) continue;
        await inspect(page, path, false);
      }
    }
    await page.close();
  }
  console.log("\n");

  await browser.close();

  const scope = `${expensive} pages against 1.4.4, 1.4.10, 1.4.12, 2.1.1, 2.4.7 · ` +
    `${cheap} against 2.4.1, 2.4.2, 3.1.1`;
  if (fails.length === 0) {
    console.log(`${scope} — no failures`);
    if (!ALL) console.log("(`--all` runs the expensive checks over every screen, in all three roles)");
    process.exit(0);
  }
  console.log(`${scope}\n`);
  const byCriterion = new Map();
  for (const f of fails) {
    const e = byCriterion.get(f.criterion) || [];
    e.push(f);
    byCriterion.set(f.criterion, e);
  }
  for (const [criterion, items] of byCriterion) {
    console.log(`${criterion} — ${items.length} page(s)`);
    for (const i of items) console.log(`   ${i.page}: ${i.detail}`);
    console.log();
  }
  process.exit(1);
})();
}
