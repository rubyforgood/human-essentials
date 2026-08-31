// Every button and menu item in the app, with the glyph it carries, checked against the lexicon.
//
// design.md said how to *mark up* an icon -- `aria-hidden` beside a label, `aria-label` when alone,
// a button and never an anchor -- and never said **which glyph means what**. Seven disagreements
// fell through that gap, the loudest being `/donation_sites`: **Import with an arrow leaving a tray
// and Export with one entering it**, two directional words over two arrows pointing the other way.
//
// A static grep cannot do this. Buttons come from four helpers, a partial, two menus and a dozen
// hand-rolled `button_tag`s, and half are conditional on a role or a count -- so what a page shows
// is only knowable once it is rendered with real data.
//
// Four checks:
//   1. one label, one glyph  -- comparing *triggers* with triggers; a menu trigger's trailing
//                               chevron is the disclosure, not the action, and is discounted
//   2. a form's own actions carry no glyph
//   3. no arrow pointing against its own word (the in/out pairs, checked by name)
//   4. every glyph in use is in design.md's lexicon, so a new one-off has to be added on purpose
//
// Check 1's opposite -- one glyph on many labels -- is *reported and not failed*: twenty-five "New
// X" buttons sharing `bi-plus-lg` is the lexicon working, not breaking.
//
// Run against a seeded development server: bin/start, then `pw bin/design/icon-audit.js`.
// `--list` prints the whole label -> glyph table rather than only the disagreements.
const { chromium } = require("playwright");
const fs = require("fs");
const nodePath = require("path");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const LIST = process.argv.includes("--list");
const LEXICON = JSON.parse(fs.readFileSync(nodePath.join(__dirname, "icon-lexicon.json"), "utf8"));

// bin/design/route-targets.rb writes this: every GET route that renders a screen, with a real id.
const TARGETS = JSON.parse(fs.readFileSync(process.env.TARGETS || "/tmp/targets.json", "utf8"));

const PARTNER = (p) => (p.startsWith("/partners/") && !/^\/partners\/\d+/.test(p)) || p === "/partners/profile";
const ADMIN = (p) => p.startsWith("/admin");

// Which arrow a name draws, and which way it points. Read off the glyphs themselves -- rasterised
// from the font at 80px -- rather than inferred from the name, since the names are the thing that
// misled the app in the first place.
const DIRECTION = {
  "bi-upload": "out", "bi-download": "in",
  "bi-box-arrow-up": "out", "bi-box-arrow-in-down": "in",
  "bi-box-arrow-right": "out", "bi-box-arrow-in-right": "in",
  "bi-file-earmark-arrow-up": "out", "bi-file-earmark-arrow-down": "in"
};
// The words that are themselves directional, and which way they point.
const WORD = [
  [/\bimports?\b/i, "in"], [/\bexports?\b/i, "out"],
  [/\buploads?\b/i, "out"], [/\bdownloads?\b/i, "in"]
];

async function signIn(page, email) {
  await page.goto(`${BASE}/users/sign_in`, { waitUntil: "domcontentloaded" });
  await page.fill("#user_email", email);
  await page.fill("#user_password", "password!");
  await page.click("input[type=submit], button[type=submit]");
  await page.waitForLoadState("networkidle");
}

async function collect(page, path) {
  const res = await page.goto(BASE + path, { waitUntil: "domcontentloaded", timeout: 25000 });
  if (!res || res.status() >= 400) return [];
  await page.waitForTimeout(80);

  return page.evaluate(() => {
    // A design system button is the one carrying BUTTON_BASE. Row actions and the kebab are
    // `size-7` / `size-[2.375rem]` squares built from the same base, so they come along too.
    const isButton = (el) =>
      el.classList.contains("inline-flex") && el.classList.contains("rounded-lg");

    // A form's own submit, as opposed to a `button_to` row action -- which is also a submit inside
    // a form, and is not a form action. The difference that holds: a real form has a field in it.
    const isFormSubmit = (el) => {
      if (el.type !== "submit") return false;
      const form = el.closest("form");
      if (!form) return false;
      return !!form.querySelector("input:not([type=hidden]), select, textarea");
    };

    // Where it sits, because a page action and a form action answer to different rules.
    const placeOf = (el) => {
      if (isFormSubmit(el)) return "submit";
      if (el.getAttribute("role") === "menuitem") return "menu";
      if (el.closest('[data-page-header="actions"]')) return "header";
      if (el.closest("[data-row-actions], [data-row-actions-panel]")) return "row-menu";
      if (el.closest("tbody")) return "row";
      if (el.closest("dialog")) return "dialog";
      if (el.closest("nav")) return "nav";
      return "body";
    };

    // Menu items live behind a kebab. Since row actions collapsed into one, most of an index
    // page's Edit and Delete are `role="menuitem"` rather than buttons -- so an audit reading only
    // buttons would have stopped seeing exactly the glyphs it most needs to compare.
    const out = [];
    for (const el of document.querySelectorAll("a, button, input[type=submit], span[aria-disabled], [role=menuitem]")) {
      if (!isButton(el) && el.getAttribute("role") !== "menuitem" && el.type !== "submit") continue;
      const icons = [...el.querySelectorAll("i")]
        .flatMap((i) => [...i.classList])
        .filter((c) => c.startsWith("bi-"));
      const clone = el.cloneNode(true);
      clone.querySelectorAll(".sr-only").forEach((n) => n.remove());
      const label = (clone.textContent || el.value || "").replace(/\s+/g, " ").trim();
      out.push({
        label: label || el.getAttribute("aria-label") || "",
        iconOnly: !label && !!icons.length,
        icons,
        place: placeOf(el),
        // A menu trigger's chevron says "there is more behind this", not what the action is.
        menuTrigger: el.hasAttribute("aria-expanded") || el.getAttribute("aria-haspopup") === "menu"
      });
    }
    return out;
  });
}

const SKIP_LABEL = /^More actions for /; // named after the row, so every one is unique by design

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await ctx.newPage();

  // label + kind -> glyph set -> where it was seen
  const seen = new Map();
  const record = (b, path) => {
    if (!b.label || SKIP_LABEL.test(b.label)) return;
    // A menu trigger's chevron is the disclosure affordance, not the action's glyph.
    const icons = b.menuTrigger ? b.icons.filter((i) => i !== "bi-chevron-down") : b.icons;
    const kind = b.place === "submit" ? "submit" : "trigger";
    const key = b.label.toLowerCase() + " :: " + kind;
    if (!seen.has(key)) seen.set(key, { label: b.label, kind, iconOnly: b.iconOnly, variants: new Map() });
    const vkey = icons.join(" ") || "(none)";
    const v = seen.get(key).variants;
    if (!v.has(vkey)) v.set(vkey, { icons, where: [] });
    const w = v.get(vkey).where;
    if (!w.includes(`${path} [${b.place}]`)) w.push(`${path} [${b.place}]`);
  };

  const runs = [
    ["org_admin1@example.com", (p) => !ADMIN(p) && !PARTNER(p)],
    ["verified@example.com", PARTNER],
    ["superadmin@example.com", ADMIN]
  ];

  let visited = 0;
  for (const [email, wants] of runs) {
    await signIn(page, email);
    for (const t of TARGETS) {
      if (!wants(t.path)) continue;
      let found;
      try { found = await collect(page, t.path); } catch { continue; }
      if (!found.length) continue;
      visited++;
      for (const b of found) record(b, t.path);
    }
  }
  await browser.close();

  const rows = [...seen.values()].sort((a, b) => a.label.localeCompare(b.label));

  // The raw table, so a count quoted in design.md can be re-measured rather than recalled.
  fs.writeFileSync("/tmp/icon-audit.json", JSON.stringify(rows.map((r) => ({
    label: r.label, kind: r.kind,
    variants: [...r.variants].map(([k, v]) => ({ icons: v.icons, key: k, where: v.where }))
  })), null, 1));

  if (LIST) {
    for (const r of rows) {
      for (const [vk, v] of r.variants) {
        console.log(`${r.label.slice(0, 33).padEnd(34)} ${r.kind.padEnd(8)} ${vk.padEnd(26)} ${v.where.length} page(s)`);
      }
    }
  }

  const excused = (label) => (LEXICON.exceptions || []).find((e) => e.label === label);

  // 1. One label, one glyph -- triggers against triggers.
  const split = rows.filter((r) => r.variants.size > 1 && !excused(r.label));

  // 2. A generic form verb carries no glyph.
  //
  // Not "a form action carries no glyph", which was the first draft and was wrong twice over: it
  // flagged the filter bar's `Filter` and the import dialog's `Import CSV`, both of which name a
  // real action and both of which share their glyph with the same action elsewhere. The line is
  // between a word that names what happens and a word that only says "commit this form".
  const GENERIC = new Set(LEXICON.generic_verbs.labels);
  const decorated = rows.filter((r) => !r.iconOnly && GENERIC.has(r.label.toLowerCase()) &&
    [...r.variants].some(([k]) => k !== "(none)") && !excused(r.label));

  // 3. An arrow pointing against its own word.
  const contradictions = [];
  for (const r of rows) {
    const word = WORD.find(([re]) => re.test(r.label));
    if (!word) continue;
    for (const [, v] of r.variants) {
      for (const icon of v.icons) {
        if (DIRECTION[icon] && DIRECTION[icon] !== word[1]) {
          contradictions.push(`"${r.label}" means ${word[1]}, ${icon} points ${DIRECTION[icon]}  ${v.where.join(", ")}`);
        }
      }
    }
  }

  // 4. Every glyph in use is in the lexicon.
  const known = new Set(Object.values(LEXICON.glyphs).concat(LEXICON.structural || []));
  const unknown = new Map();
  for (const r of rows) {
    for (const [, v] of r.variants) {
      for (const icon of v.icons) {
        if (known.has(icon)) continue;
        if (!unknown.has(icon)) unknown.set(icon, new Set());
        unknown.get(icon).add(r.label);
      }
    }
  }

  // Reported, never failed: one glyph across many labels is the lexicon working.
  const byIcon = new Map();
  for (const r of rows) {
    for (const [vk] of r.variants) {
      if (vk === "(none)") continue;
      if (!byIcon.has(vk)) byIcon.set(vk, new Set());
      byIcon.get(vk).add(r.label);
    }
  }

  console.log(`\n${visited} pages, ${rows.length} distinct label/kind pairs`);

  console.log(`\n-- 1. one label, more than one glyph (${split.length}) --`);
  for (const r of split) {
    console.log(`  ${r.label}  [${r.kind}]`);
    for (const [vk, v] of r.variants) console.log(`      ${vk.padEnd(24)} ${v.where.join(", ")}`);
  }

  console.log(`\n-- 2. a generic form verb wearing a glyph (${decorated.length}) --`);
  for (const r of decorated) {
    for (const [vk, v] of r.variants) {
      if (vk !== "(none)") console.log(`  ${r.label.padEnd(30)} ${vk.padEnd(22)} ${v.where.join(", ")}`);
    }
  }

  console.log(`\n-- 3. arrow against its word (${contradictions.length}) --`);
  for (const c of contradictions) console.log("  " + c);

  console.log(`\n-- 4. glyph not in the lexicon (${unknown.size}) --`);
  for (const [icon, labels] of unknown) console.log(`  ${icon.padEnd(28)} ${[...labels].join(" / ")}`);

  console.log(`\n-- reported only: one glyph, many labels (${[...byIcon].filter(([, l]) => l.size > 1).length}) --`);
  for (const [icon, labels] of byIcon) {
    if (labels.size > 1) console.log(`  ${icon.padEnd(28)} ${[...labels].slice(0, 8).join(" / ")}${labels.size > 8 ? ` (+${labels.size - 8})` : ""}`);
  }

  if ((LEXICON.exceptions || []).length) {
    console.log(`\n-- excused, with a reason (${LEXICON.exceptions.length}) --`);
    for (const e of LEXICON.exceptions) console.log(`  ${e.label.padEnd(28)} ${e.reason}`);
  }

  const failures = split.length + decorated.length + contradictions.length + unknown.size;
  console.log(`\n${failures ? failures + " finding(s)" : "no findings"}`);
  process.exitCode = failures ? 1 : 0;
})();
