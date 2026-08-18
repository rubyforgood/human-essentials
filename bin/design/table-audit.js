// Audits every index table for two things design.md already settles:
//   - row actions use one visual weight (`:ghost`), and
//   - badges mark the exception rather than every row.
//
// Static tools cannot answer either. `status.rb` asks whether a view contains design system
// markup, and a table can be fully migrated while still calling a legacy helper that renders a
// filled button; the variant only becomes visible once the classes are on the element.
//
// Run against a seeded development server: bin/start, then `pw bin/design/table-audit.js`.
const { chromium } = require("playwright");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";

const AS_ORG_ADMIN = ["/partners", "/items", "/distributions", "/donations", "/purchases",
  "/vendors", "/storage_locations", "/transfers", "/requests", "/donation_sites",
  "/manufacturers", "/product_drives", "/barcode_items", "/audits", "/adjustments", "/kits",
  "/users", "/product_drive_participants", "/broadcast_announcements"];

const AS_SUPER_ADMIN = ["/admin/organizations", "/admin/users", "/admin/base_items",
  "/admin/barcode_items", "/admin/partners", "/admin/broadcast_announcements",
  "/admin/account_requests", "/admin/questions"];

async function signIn(page, email) {
  await page.goto(`${BASE}/users/sign_in`);
  await page.fill("#user_email", email);
  await page.fill("#user_password", "password!");
  await page.click("input[type=submit], button[type=submit]");
  await page.waitForLoadState("networkidle");
}

async function auditPage(page, path) {
  const res = await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 20000 });
  if (!res || res.status() >= 400) return { path, note: `HTTP ${res && res.status()}` };

  return {
    path,
    ...(await page.evaluate(() => {
      // The variant is only recoverable from the classes the helper emitted.
      const weight = (el) =>
        el.className.includes("border-slate-300") ? "secondary"
        : el.className.includes("bg-brand-600") ? "primary"
        : el.className.includes("bg-rose-600") ? "danger"
        : "ghost";

      const rows = [...document.querySelectorAll("table.data-table tbody tr")];
      const weights = new Set();
      let maxActions = 0, badgedRows = 0, badges = 0;

      rows.forEach((tr) => {
        const cells = tr.querySelectorAll("td");
        if (!cells.length) return;
        const actions = [...cells[cells.length - 1].querySelectorAll("a, button")]
          .filter((el) => el.className.includes("rounded-lg"));
        maxActions = Math.max(maxActions, actions.length);
        actions.forEach((el) => weights.add(weight(el)));

        const rowBadges = tr.querySelectorAll(".rounded-full").length;
        badges += rowBadges;
        if (rowBadges) badgedRows += 1;
      });

      return {
        rows: rows.length,
        maxActions,
        weights: [...weights].sort(),
        badgedRows,
        badges,
        // A filter strip built from the badge palette: a control that looks like a state.
        filterChips: document.querySelectorAll("#partner-status li").length
      };
    }))
  };
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewportSize: { width: 1600, height: 1000 } });
  const results = [];

  for (const [email, paths] of [["org_admin1@example.com", AS_ORG_ADMIN],
                                ["superadmin@example.com", AS_SUPER_ADMIN]]) {
    await signIn(page, email);
    for (const path of paths) {
      try {
        results.push(await auditPage(page, path));
      } catch (e) {
        results.push({ path, note: e.message.slice(0, 60) });
      }
    }
  }

  console.table(results);

  const mixed = results.filter((r) => r.weights && r.weights.length > 1);
  const loud = results.filter((r) => r.weights && r.weights.some((w) => w === "primary" || w === "danger"));
  const everyRow = results.filter((r) => r.rows > 0 && r.badgedRows === r.rows);

  console.log(`\ntables audited:            ${results.filter((r) => !r.note).length}`);
  console.log(`more than one weight:      ${mixed.length}  ${mixed.map((r) => r.path).join(" ")}`);
  console.log(`filled button in a row:    ${loud.length}  ${loud.map((r) => r.path).join(" ")}`);
  console.log(`badge on every row:        ${everyRow.length}  ${everyRow.map((r) => r.path).join(" ")}`);

  await browser.close();
  process.exit(mixed.length || loud.length ? 1 : 0);
})();
