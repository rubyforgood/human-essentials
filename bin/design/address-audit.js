// Checks that every screen collecting an address asks for it the same way.
//
// Seven screens collect one, and before this they did it in five different shapes: `state` was a
// 52-option select on the organization form and a free text box on the partner profile; `zip_code`
// was a string on one row and an *integer* on the next, which renders as `type="number"` and drops
// the leading zero on every ZIP in New England; the same box was labelled "Street", "Street
// address" and "Address (line 1)"; and **not one of the 17 inputs carried `autocomplete`**.
//
// Five assertions, per address field:
//
//   1. AUTOCOMPLETE  it has the right token for its role -- WCAG 1.3.5 Identify Input Purpose (AA).
//   2. STATE         a state is chosen from a list, never typed.
//   3. ZIP           a ZIP is text with a numeric inputmode, never `type="number"`.
//   4. LABEL         the label is the one word the app uses for that part of an address.
//   5. NAMED         it has an accessible name at all, from a label or an aria-label.
//
// Roles are read off the field's *name* rather than a list of screens, so a form that adds an
// address field is audited the day it is written. That is the lesson from `tooltip-audit.js`, which
// carried a hardcoded page list and reported zero while there were fourteen.
//
// Usage: bin/rails runner bin/design/route-targets.rb > /tmp/targets.json && pw bin/design/address-audit.js
const { chromium } = require("playwright");
const fs = require("fs");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const TARGETS = JSON.parse(fs.readFileSync(process.env.TARGETS || "/tmp/targets.json", "utf8"));

const PARTNER = (p) => (p.startsWith("/partners/") && !/^\/partners\/\d+/.test(p)) || p === "/partners/profile";
const ADMIN = (p) => p.startsWith("/admin");
const RUNS = [
  ["org_admin1@example.com", (p) => !ADMIN(p) && !PARTNER(p)],
  ["verified@example.com", PARTNER],
  ["superadmin@example.com", ADMIN]
];

// What the app calls each part of an address, and the token a browser fills it from. The single
// source of truth is `AddressHelper::ADDRESS_FIELDS`; this is the same table, and the spec
// `spec/helpers/address_helper_spec.rb` pins that they agree, so this file cannot drift silently.
const ROLES = {
  street: { label: "Street address", token: "street-address" },
  line1: { label: "Address line 1", token: "address-line1" },
  line2: { label: "Address line 2", token: "address-line2" },
  city: { label: "City", token: "address-level2" },
  state: { label: "State", token: "address-level1" },
  zip: { label: "ZIP code", token: "postal-code" },
  // A single box holding the whole thing. Still an address, still gets a token; whether it *should*
  // be one box is a separate question that this audit deliberately does not decide.
  whole: { label: "Address", token: "street-address" }
};

async function signIn(page, email) {
  await page.goto(`${BASE}/users/sign_in`, { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", process.env.SEED_PASSWORD || "password!");
  await page.click("input[type=submit], button[type=submit]");
  await page.waitForLoadState("networkidle").catch(() => {});
}

const COLLECT = () => [...document.querySelectorAll("main input, main select, main textarea")]
  .filter((el) => el.type !== "hidden")
  .map((el) => {
    const key = (el.name || el.id || "").toLowerCase();
    // Read the role off the field name. Order matters: `program_address1` must match line1 before
    // the bare `address` rule claims it, and `zips_served` is a list of ZIPs rather than this
    // record's own, so it is not an address field and gets no token.
    let role = null;
    if (/zips_served|zip_codes_served/.test(key)) role = null;
    else if (/address_?1\b|address\[1\]|addressline1/.test(key)) role = "line1";
    else if (/address_?2\b|address\[2\]|addressline2/.test(key)) role = "line2";
    else if (/\bstreet\b/.test(key)) role = "street";
    else if (/\bcity\b/.test(key)) role = "city";
    else if (/\bstate\b/.test(key) && !/united_states/.test(key)) role = "state";
    else if (/zip|postal/.test(key)) role = "zip";
    else if (/address/.test(key) && !/email/.test(key)) role = "whole";
    if (!role) return null;

    return {
      name: el.name || el.id, role,
      tag: el.tagName.toLowerCase(), type: el.type,
      options: el.tagName === "SELECT" ? el.options.length : null,
      label: (el.labels?.[0]?.textContent || "").replace(/\s+/g, " ").replace(/\s*\*$/, "").trim(),
      aria: el.getAttribute("aria-label") || "",
      autocomplete: el.getAttribute("autocomplete") || "",
      inputmode: el.getAttribute("inputmode") || ""
    };
  })
  .filter(Boolean);

(async () => {
  const browser = await chromium.launch();
  let fields = 0;
  const findings = [];
  const thirdParty = [];

  for (const [email, wants] of RUNS) {
    const ctx = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
    const page = await ctx.newPage();
    await signIn(page, email);

    for (const { path } of TARGETS.filter((t) => wants(t.path))) {
      await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 60000 }).catch(() => {});
      await page.waitForTimeout(120);
      const found = await page.evaluate(COLLECT).catch(() => []);
      if (!found.length) continue;

      const bad = [];
      for (const f of found) {
        fields++;
        const want = ROLES[f.role];
        const named = f.label || f.aria;

        if (!named) bad.push(`${f.name} has no accessible name`);
        // `off` is a declaration, not an omission: this address belongs to someone other than the
        // person filling the form in, so autofilling it would put the wrong address in the record.
        // WCAG 1.3.5 asks for a token on fields collecting the *user's own* information. Counted
        // and printed rather than waved through, so the exemption stays visible.
        if (f.autocomplete === "off") {
          thirdParty.push(`${path}: ${f.name}`);
        } else if (f.autocomplete !== want.token) {
          bad.push(`${f.name} autocomplete=${f.autocomplete || "(none)"}, wanted ${want.token}`);
        }
        if (f.role === "state" && f.tag !== "select") {
          bad.push(`${f.name} is a ${f.tag}, not a list of states`);
        }
        if (f.role === "zip" && f.type === "number") {
          bad.push(`${f.name} is type=number, which loses a leading zero and refuses ZIP+4`);
        }
        if (f.role === "zip" && f.type !== "number" && f.inputmode !== "numeric") {
          bad.push(`${f.name} has no numeric inputmode`);
        }
        // The words for the part are the app's; a screen may put a qualifier in front of them.
        //
        // "Guardian ZIP code" on the family form is right -- it says *whose* -- so this is not an
        // equality check. What it does catch is the same part spelled differently from one screen
        // to the next, which is what "Zip code", "Zipcode" and "ZIP code" were: the qualifier is
        // free, the part is not.
        if (named && !named.endsWith(want.label)) {
          bad.push(`${f.name} is labelled "${named}", which does not end in the app's "${want.label}"`);
        }
      }

      const unique = [...new Set(bad)];
      console.log(`  ${unique.length ? "FAIL" : "ok  "} ${path.padEnd(38)} ${found.length} address field(s)`);
      unique.forEach((b) => { console.log(`       ${b}`); findings.push(`${path}: ${b}`); });
    }
    await ctx.close();
  }
  await browser.close();

  if (thirdParty.length) {
    console.log("\nautocomplete=off -- somebody else's address, so the browser must not fill it:");
    [...new Set(thirdParty)].forEach((t) => console.log(`  ${t}`));
  }

  console.log(`\n${fields} address fields, ${findings.length} finding(s).`);
  process.exit(findings.length ? 1 : 0);
})();
