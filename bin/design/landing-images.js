// Retakes the pictures the landing page uses, from the running app.
//
//   app/assets/images/landing/share.png             the picture a shared link shows (og:image), 1200x630
//   app/assets/images/landing/app-donation.webp     the five screens of the tour under "How it works",
//                           app-inventory.webp      1600x1000 each, one for each step
//                           app-request.webp
//                           app-distribution.webp
//                           app-reports.webp
//
// None is drawn at request time, so each goes stale quietly: the share picture when the headline
// or the directories change, a screen when its page does. Run this then, look at the files, and
// commit them.
//
// Usage: pw bin/design/landing-images.js                         all six
//        pw bin/design/landing-images.js share                   one of them, by name
//        REQUEST_PATH=/requests/269 pw bin/design/landing-images.js request
//
// Each screen is a real page of the seeded demo bank, signed in as its admin. Two things on them
// are changed before the picture is taken, and nothing else, so what a picture shows is what the
// app does:
//
//   request     the seeds fill a request's comment with lorem ipsum; COMMENT replaces it
//   inventory   the seeds leave a storage location's address as the word "Unknown"; it is blanked
//
// Without its *_PATH variable a screen takes the first record in its list, and the seeds are
// random, so pick records worth showing -- a request and a donation with several items. The
// committed pictures were taken with DONATION_PATH=/donations/13, INVENTORY_PATH=/storage_locations/2,
// REQUEST_PATH=/requests/269 and DISTRIBUTION_PATH=/distributions/1 on the author's database;
// those numbers mean nothing on another one.
//
// Needs `cwebp` on the path for the screens (brew install webp).
const { chromium } = require("playwright");
const { execFileSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { BASE, signIn } = require("./targets");

const OUT = path.join(__dirname, "..", "..", "app", "assets", "images", "landing");
const BANK_ADMIN = "org_admin1@example.com";
const COMMENT = process.env.COMMENT || "Running low on size 4 before Saturday's clinic.";
const only = process.argv[2];

// rack-mini-profiler and Bullet draw over the page in development only.
const HIDE_DEV_BADGES = ".profiler-results, #rack-mini-profiler, #bullet-footer { display: none !important }";

async function share(browser) {
  const context = await browser.newContext({ viewport: { width: 1200, height: 630 }, reducedMotion: "reduce" });
  const page = await context.newPage();
  await page.goto(BASE + "/", { waitUntil: "networkidle" });
  // The hero, without what only makes sense on the page itself: nothing here can be clicked.
  await page.addStyleTag({
    content: `${HIDE_DEV_BADGES}
      .nav-links, .nav-actions, .hero-cta, .assoc, .finder, .map-fig figcaption, main > :not(.top), .footer, .skip { display: none !important }
      .night.top { min-height: 630px }
      .hero-in { grid-template-columns: minmax(0, 5fr) minmax(0, 7fr) !important; align-items: center; padding-block: 2.5rem 0 !important }
      .hero h1 { font-size: 3.5rem !important }
      .map-fig { margin-right: -1rem !important }`
  });
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: path.join(OUT, "share.png"), clip: { x: 0, y: 0, width: 1200, height: 630 } });
  await context.close();
  console.log("wrote share.png");
}

// name, the list a record is chosen from, what a record's path looks like, and what to tidy.
const SCREENS = [
  { name: "donation", list: "/donations", record: /^\/donations\/\d+$/ },
  { name: "inventory", list: "/storage_locations", record: /^\/storage_locations\/\d+$/, tidy: blankUnknownAddress },
  { name: "request", list: "/requests", record: /^\/requests\/\d+$/, tidy: replaceComment },
  { name: "distribution", list: "/distributions", record: /^\/distributions\/\d+$/ },
  { name: "reports", path: "/reports" }
];

async function replaceComment(page, target) {
  const swapped = await page.evaluate((comment) => {
    const term = [...document.querySelectorAll("dt")].find((dt) => dt.textContent.trim() === "Comments");
    const value = term && term.nextElementSibling;
    if (!value) return false;
    value.textContent = comment;
    return true;
  }, COMMENT);
  if (!swapped) throw new Error(`${target} has no Comments field. The request page changed: update this script.`);
}

// No error when there is nothing to blank: a location with a real address is the better picture.
async function blankUnknownAddress(page) {
  await page.evaluate(() => {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.filter((node) => node.nodeValue.trim() === "Unknown").forEach((node) => { node.nodeValue = ""; });
  });
}

async function screen(page, { name, list, record, path: fixed, tidy }) {
  let target = fixed || process.env[`${name.toUpperCase()}_PATH`];
  if (!target) {
    await page.goto(BASE + list, { waitUntil: "networkidle" });
    target = await page.evaluate((source) => {
      const pattern = new RegExp(source);
      const link = [...document.querySelectorAll("a[href]")].find((a) => pattern.test(new URL(a.href).pathname));
      return link && new URL(link.href).pathname;
    }, record.source);
    if (!target) throw new Error(`Nothing found in ${list}. Seed the database, or pass ${name.toUpperCase()}_PATH.`);
  }
  await page.goto(BASE + target, { waitUntil: "networkidle" });
  await page.addStyleTag({ content: HIDE_DEV_BADGES });
  if (tidy) await tidy(page, target);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(500);

  const png = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "landing-")), `${name}.png`);
  await page.screenshot({ path: png });
  execFileSync("cwebp", ["-quiet", "-q", "82", "-resize", "1600", "1000", png, "-o", path.join(OUT, `app-${name}.webp`)]);
  console.log(`wrote app-${name}.webp from ${target}`);
}

async function screens(browser, wanted) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 2 });
  const page = await context.newPage();
  await signIn(page, BANK_ADMIN);
  for (const each of wanted) await screen(page, each);
  await context.close();
}

(async () => {
  const browser = await chromium.launch();
  try {
    const wanted = SCREENS.filter((each) => !only || only === each.name);
    if (only && only !== "share" && !wanted.length) {
      throw new Error(`No picture called "${only}". Choose from: share, ${SCREENS.map((each) => each.name).join(", ")}.`);
    }
    if (!only || only === "share") await share(browser);
    if (wanted.length) await screens(browser, wanted);
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
