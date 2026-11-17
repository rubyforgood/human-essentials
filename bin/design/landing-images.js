// Retakes the two pictures the landing page uses, from the running app.
//
//   app/assets/images/landing/share.png          the picture a shared link shows (og:image), 1200x630
//   app/assets/images/landing/app-request.webp   the product screen under "How it works", 1600x1000
//
// Neither is drawn at request time, so both go stale quietly: the share picture when the headline
// or the directories change, the product screen when the request page does. Run this then, look
// at both files, and commit them.
//
// Usage: pw bin/design/landing-images.js                         both
//        pw bin/design/landing-images.js share                   one of them
//        REQUEST_PATH=/requests/269 pw bin/design/landing-images.js request
//
// The product screen is a real page of the seeded demo bank, signed in as its admin, with one
// change: the seeds fill a request's comment with lorem ipsum, and COMMENT replaces it. Nothing
// else is touched, so what the picture shows is what the app does. Without REQUEST_PATH it takes
// the first request in the list; pick one with several items so the table is worth showing.
//
// Needs `cwebp` on the path for the product screen (brew install webp).
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

async function request(browser) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 2 });
  const page = await context.newPage();
  await signIn(page, BANK_ADMIN);
  let target = process.env.REQUEST_PATH;
  if (!target) {
    await page.goto(BASE + "/requests", { waitUntil: "networkidle" });
    target = await page.evaluate(() => {
      const link = [...document.querySelectorAll("a[href]")].find((a) => /^\/requests\/\d+$/.test(new URL(a.href).pathname));
      return link && new URL(link.href).pathname;
    });
    if (!target) throw new Error("No request found in /requests. Seed the database, or pass REQUEST_PATH.");
  }
  await page.goto(BASE + target, { waitUntil: "networkidle" });
  await page.addStyleTag({ content: HIDE_DEV_BADGES });
  const swapped = await page.evaluate((comment) => {
    const term = [...document.querySelectorAll("dt")].find((dt) => dt.textContent.trim() === "Comments");
    const value = term && term.nextElementSibling;
    if (!value) return false;
    value.textContent = comment;
    return true;
  }, COMMENT);
  if (!swapped) throw new Error(`${target} has no Comments field. The request page changed: update this script.`);
  await page.evaluate(() => document.fonts.ready);

  const png = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "landing-")), "request.png");
  await page.screenshot({ path: png });
  execFileSync("cwebp", ["-quiet", "-q", "82", "-resize", "1600", "1000", png, "-o", path.join(OUT, "app-request.webp")]);
  await context.close();
  console.log(`wrote app-request.webp from ${target}`);
}

(async () => {
  const browser = await chromium.launch();
  try {
    if (!only || only === "share") await share(browser);
    if (!only || only === "request") await request(browser);
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
