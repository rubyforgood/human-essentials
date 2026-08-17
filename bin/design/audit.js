const { chromium } = require("playwright");
(async () => {
  const [path, width] = process.argv.slice(2);
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: parseInt(width||"1400"), height: 1000 } });
  const page = await ctx.newPage();
  await page.goto("http://127.0.0.1:3003/users/sign_in", { waitUntil: "networkidle" });
  await page.fill('input[name="user[email]"]', "org_admin1@example.com");
  await page.fill('input[name="user[password]"]', "password!");
  await Promise.all([page.waitForNavigation({waitUntil:"networkidle"}).catch(()=>{}), page.click('input[type="submit"], button[type="submit"]')]);
  await page.goto("http://127.0.0.1:3003" + path, { waitUntil: "networkidle" });
  await page.waitForTimeout(400);

  const out = await page.evaluate(() => {
    const r = {};
    const side = document.querySelector("#essentials-sidebar");
    if (side) { const b = side.getBoundingClientRect(); r.sidebar = { w: Math.round(b.width), sticky: getComputedStyle(side).position }; }
    const h1 = document.querySelector("h1");
    if (h1) { const s = getComputedStyle(h1); r.h1 = { size: s.fontSize, weight: s.fontWeight, color: s.color }; }
    const card = document.querySelector("main section.rounded-2xl");
    if (card) { const s = getComputedStyle(card); r.card = { radius: s.borderRadius, border: s.borderColor, bg: s.backgroundColor }; }
    const active = document.querySelector('[aria-current="page"]');
    if (active) { const s = getComputedStyle(active); r.activeNav = { bg: s.backgroundColor, color: s.color }; }
    // Bootstrap leakage: any element carrying a class the Tailwind bundle does not define
    const legacy = ["card-body","btn-primary","content-header","container-fluid","form-group","col-md-12","breadcrumb","pull-right","box-body"];
    r.legacyClassesPresent = legacy.filter((c) => document.querySelector("." + CSS.escape(c)));
    // Any icon still using Font Awesome
    r.faIcons = document.querySelectorAll('[class*="fa-"]').length;
    r.biIcons = document.querySelectorAll('[class*="bi-"]').length;
    r.hOrder = [...document.querySelectorAll("h1,h2,h3,h4,h5,h6")].map((h)=>h.tagName);
    return r;
  });
  console.log(JSON.stringify(out, null, 2));
  await browser.close();
})();
