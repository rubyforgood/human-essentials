/*
 * Every form: are required fields marked, and do validation errors reach the field?
 *
 *   BASE_URL=http://127.0.0.1:3000 pw bin/design/form-validation-audit.js
 *   ONLY=/items/new pw bin/design/form-validation-audit.js
 *
 * It visits each `new` form, reads how the required fields are marked, then submits the form
 * empty and reads what came back. Submitting empty is safe: it fails validation, so nothing is
 * created. `novalidate` is set first, because otherwise the browser blocks the submit and the
 * server-side path -- the one that has to work when JavaScript does not -- is never exercised.
 * Whether the browser would have blocked it is reported separately.
 *
 * What it is checking for, and why:
 *
 *   WCAG 3.3.1 Error Identification   the error is described in text, next to the field
 *   WCAG 3.3.2 Labels or Instructions required state is conveyed, not just implied
 *   WCAG 3.3.3 Error Suggestion       the message says what to do
 *   aria-invalid / aria-describedby   the field itself carries its error, so a screen reader
 *                                     hears it on focus rather than only in a summary
 */
const { chromium } = require("playwright");
const { execSync } = require("child_process");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";
const ONLY = process.env.ONLY ? process.env.ONLY.split(",") : null;

const targets = JSON.parse(execSync("bin/rails runner bin/design/route-targets.rb", {
  encoding: "utf8", maxBuffer: 8 << 20, stdio: ["ignore", "pipe", "ignore"],
})).filter((t) => t.action === "new" && (!ONLY || ONLY.includes(t.path)));

async function signIn(page, email) {
  await page.goto(BASE + "/users/sign_out", { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.goto(BASE + "/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.fill('input[name="user[email]"]', email);
  await page.fill('input[name="user[password]"]', PASSWORD);
  await page.click('form[action="/users/sign_in"] button[type="submit"]');
  await page.waitForURL((u) => !u.pathname.includes("/sign_in"), { timeout: 60000 });
}

// A form in an open <dialog> is the one the reader is looking at, and it is not inside <main> on
// every page. Modal forms had never been audited at all: the runner only visited `new` routes, and
// a modal lives on an index page behind a button.
//
// The lookup is written out in both readers rather than shared: these are handed to
// `page.evaluate`, which serialises the function and drops everything it closed over, so a helper
// from this scope would simply be undefined in the browser.
const readForm = () => {
  const openDialog = [...document.querySelectorAll("dialog")].find((d) => d.open);
  const scope = openDialog || document.querySelector("main") || document.body;
  const form = scope.querySelector("form:not([action*='sign_out'])");
  if (!form) return { noForm: true };
  const fields = [...form.querySelectorAll("input:not([type=hidden]):not([type=submit]):not([type=button]), select, textarea")]
    .filter((f) => f.offsetParent !== null);

  // Is this control's requiredness stated where a user would look for it?
  //
  //   A radio or checkbox belongs to a group, and the group is what is required -- the marker
  //   goes on the <legend>, not on each option. /distributions/new marks "Delivery method *" and
  //   has three radios under it; flagging all three was wrong.
  //
  //   A conditionally required field cannot carry a bare marker truthfully. Product drive
  //   participants need a business name OR a contact name, and say so in words. Prose containing
  //   "required" counts as marked, and correctly has no aria-required, because none of those
  //   fields is required on its own.
  const legendFor = (f) => {
    const fs = f.closest("fieldset");
    return fs ? fs.querySelector("legend") : null;
  };
  const markedFor = (f) => {
    const l = f.labels && f.labels[0];
    if (l && (l.querySelector(".required-marker") || /\brequired\b/i.test(l.textContent))) return true;
    // Any field in a group, not only a radio or checkbox. A conditional pair -- business name or
    // contact name -- states the rule on the legend now, because neither field is required alone
    // and the group is what is. Writing it into both labels made the field's accessible *name*
    // "Phone (phone or email required)", and said it twice.
    const lg = legendFor(f);
    if (lg && (lg.querySelector(".required-marker") || /\brequired\b/i.test(lg.textContent))) return true;
    return false;
  };
  const conditional = (f) => {
    const l = f.labels && f.labels[0];
    if (l && /\brequired\b/i.test(l.textContent) && !l.querySelector(".required-marker")) return true;
    const lg = legendFor(f);
    return !!lg && /\brequired\b/i.test(lg.textContent) && !lg.querySelector(".required-marker");
  };

  const required = fields.filter((f) => f.required || f.getAttribute("aria-required") === "true");
  const markedInLabel = required.filter(markedFor);
  // A marker with no programmatic required is just as wrong -- unless the field is conditionally
  // required, where saying so in words is the only honest option.
  const markedNotRequired = fields.filter((f) =>
    markedFor(f) && !conditional(f) && !(f.required || f.getAttribute("aria-required") === "true"));

  return {
    fields: fields.length,
    required: required.length,
    unmarked: required.length - markedInLabel.length,
    markedNotRequired: markedNotRequired.length,
    // The marker is a red asterisk and nothing else -- there is no legend explaining it any
    // more, so there is nothing to check for. What still has to hold is that it is red rather
    // than inheriting the label colour, and that the browser's dotted underline for
    // `abbr[title]` is off: both were true for a year and neither was.
    hasAsterisk: !!form.querySelector("label .required-marker"),
    markerStyled: [...form.querySelectorAll("label .required-marker")].every((m) => {
      const c = getComputedStyle(m);
      return c.textDecorationLine === "none" && c.color !== getComputedStyle(m.parentElement).color;
    }),
  };
};

const readErrors = () => {
  const openDialog = [...document.querySelectorAll("dialog")].find((d) => d.open);
  const scope = openDialog || document.querySelector("main") || document.body;
  const form = scope.querySelector("form:not([action*='sign_out'])");
  const fields = form ? [...form.querySelectorAll("input:not([type=hidden]), select, textarea")] : [];
  // `.field-error` is the class the wrapper puts on an inline message. This used to look for
  // `p.text-rose-700`, which stopped matching the moment the message went slate behind a glyph --
  // a check keyed to a colour rather than to the thing it is checking for.
  const inline = scope.querySelectorAll("p.field-error, .field_with_errors").length;
  const invalid = fields.filter((f) => f.getAttribute("aria-invalid") === "true").length;
  // The id points at a span inside the error <p>, and `.field-error` is on the <p>, so walk up.
  // This used to test for a `rose` class anywhere in the ancestry -- keyed to the colour, like
  // the `inline` check above, and just as wrong once the message stopped being rose.
  const described = fields.filter((f) => {
    const id = f.getAttribute("aria-describedby");
    if (!id) return false;
    return id.split(/\s+/).some((x) => {
      const e = document.getElementById(x);
      return e && (e.classList.contains("field-error") || e.closest(".field-error"));
    });
  }).length;
  // Not anything inside an open <dialog>. /partners/family_requests/new pre-checks every child, so
  // its submit opens a "You are ordering 2,500 total items. Are you sure?" confirmation rather than
  // posting -- and that was being read as an error summary, which made the form look like it had
  // shown errors and failed to attach them to fields. It had not been submitted at all.
  const summary = [...scope.querySelectorAll("[class*='bg-rose-50'], [role=alert], [data-flash]")]
    .filter((e) => !e.closest("dialog[open]"))
    .map((e) => e.textContent.replace(/\s+/g, " ").trim()).filter(Boolean)[0];
  return {
    url: location.pathname,
    inline, invalid, described,
    summary: summary ? summary.slice(0, 60) : null,
    focused: document.activeElement === document.body ? "body" : document.activeElement.tagName.toLowerCase(),
  };
};

const roleFor = (c) => (c.startsWith("partners/") ? "partner" : c.startsWith("admin") ? "super" : "bank");

/*
 * Modal forms, which the `new`-route sweep above cannot reach: a modal lives on an index page,
 * behind a button, and its <form> is not on a route of its own. Four of them existed and none had
 * ever been audited -- which is how "(phone or email required)" sat in a label, making the field's
 * accessible *name* carry the condition, twice per pair.
 *
 * `open` is how the modal is triggered: either a `dialog#open` action carrying an id, or a link
 * that fetches the form and injects it.
 */
const MODALS = [
  // Triggers verified by opening each one; a modal is not reachable from a route, so there is
  // nothing to derive them from.
  { role: "bank", path: "/donations/new", name: "New product drive participant",
    open: (page) => page.evaluate(() => document.getElementById("new_participant").click()) },
  { role: "bank", path: "/users", name: "Invite a new user",
    open: (page) => page.click("[data-dialog-id-param='add-user-modal']") },
  { role: "bank", path: "/requests", name: "New quantity request",
    open: (page) => page.click("[data-dialog-id-param='new-request']") },
  // /partners, because four of the five pages that carry this modal only render its trigger when
  // the list is empty -- import is for seeding, and Export takes the slot once there is data.
  { role: "bank", path: "/partners", name: "Import from CSV",
    open: (page) => page.click("[data-dialog-id-param='csv-import-modal']") },
];

(async () => {
  const browser = await chromium.launch();
  const users = { super: "superadmin@example.com", bank: "org_admin1@example.com",
                  partner: process.env.PARTNER_EMAIL || "verified@example.com" };
  const rows = [];
  const modalRows = [];
  const unsubmittable = [];

  for (const [role, email] of Object.entries(users)) {
    let page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    // Accept confirms. A row action or a submit carrying data-confirm otherwise has its dialog
    // auto-dismissed, the submit is cancelled, and the form reads as "shows no errors" when it
    // was never submitted -- which is exactly what /audits/new did.
    page.on("dialog", (d) => d.accept().catch(() => {}));
    await signIn(page, email).catch(() => {});
    for (const m of MODALS) {
      if (m.role !== role) continue;
      try {
        await page.goto(BASE + m.path, { waitUntil: "domcontentloaded", timeout: 40000 });
        await page.waitForTimeout(400);
        await m.open(page);
        await page.waitForTimeout(900);
      } catch {
        modalRows.push({ name: m.name, path: m.path, unreachable: true });
        continue;
      }
      const marking = await page.evaluate(readForm);
      if (marking.noForm) { modalRows.push({ name: m.name, path: m.path, unreachable: true }); continue; }
      modalRows.push({ name: m.name, path: m.path, marking });
    }

    for (const t of targets) {
      if (roleFor(t.controller) !== role) continue;
      try {
        const r = await page.goto(BASE + t.path, { waitUntil: "domcontentloaded", timeout: 40000 });
        if (r.status() >= 400 || new URL(page.url()).pathname !== t.path) continue;
      } catch {
        try { await page.close(); } catch {}
        page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
        page.on("dialog", (d) => d.accept().catch(() => {}));
        await signIn(page, email).catch(() => {});
        continue;
      }
      await page.waitForTimeout(250);
      const marking = await page.evaluate(readForm);
      if (marking.noForm) continue;

      // Would the browser have stopped this on its own?
      const nativeBlocks = await page.evaluate(() => {
        const f = document.querySelector("main form:not([action*='sign_out'])");
        return f ? !f.checkValidity() : false;
      });

      await page.evaluate(() => {
        const f = document.querySelector("main form:not([action*='sign_out'])");
        if (f) f.setAttribute("novalidate", "novalidate");
      });
      const submit = await page.$("main form button[type=submit], main form input[type=submit]");
      if (!submit) { rows.push({ path: t.path, marking, nativeBlocks, errors: null }); continue; }

      // A marker that a navigation would destroy, so "the form did not submit" can be told from
      // "the form submitted and came back with nothing". /account_requests/new hides its fields
      // until an account type is chosen, so an empty submit does not leave the page at all.
      await page.evaluate(() => { window.__submitProbe = true; });
      await submit.click().catch(() => {});
      await page.waitForTimeout(1400);
      const neverSubmitted = await page.evaluate(() => window.__submitProbe === true);
      // A submit that opened a confirmation is waiting on the reader, not reporting on itself.
      const awaitingConfirm = await page.evaluate(() =>
        [...document.querySelectorAll("dialog")].some((d) => d.open));
      const errors = await page.evaluate(readErrors);

      // Some forms accept an empty submit -- a partner request with no items is still a request,
      // and /account_requests/new hides its fields until an account type is chosen, so the
      // submit does nothing at all. Neither is "errors are not shown"; there were none to show.
      // Reported separately so a page cannot hide in the wrong column.
      const stillOnForm = errors.url === t.path;
      if (awaitingConfirm) {
        unsubmittable.push([t.path, "the submit opened a confirmation instead"]);
        continue;
      }
      if (neverSubmitted && !errors.inline && !errors.summary) {
        unsubmittable.push([t.path, "the submit never left the page"]);
        continue;
      }
      if (!stillOnForm && !errors.inline) { unsubmittable.push([t.path, `submitted to ${errors.url}`]); continue; }

      rows.push({ path: t.path, marking, nativeBlocks, errors });
    }
    await page.close();
  }

  const problems = [];
  for (const r of rows) {
    const p = [];
    if (r.marking.unmarked) p.push(`${r.marking.unmarked} required field(s) not marked in the label`);
    if (r.marking.markedNotRequired) p.push(`${r.marking.markedNotRequired} field(s) marked required but not required programmatically`);
    if (r.marking.hasAsterisk && !r.marking.markerStyled) p.push("required marker not styled: it inherits the label colour, or keeps the browser's dotted underline");
    if (r.errors) {
      if (!r.errors.inline) p.push("no inline error next to any field" + (r.errors.summary ? " (only a summary)" : " (and no summary either)"));
      if (!r.errors.invalid) p.push("no aria-invalid on any field");
      if (r.errors.inline && !r.errors.described) p.push("errors shown but not linked with aria-describedby");
    }
    if (p.length) problems.push({ path: r.path, problems: p });
  }

  console.log(`${rows.length} form(s) submitted empty and re-rendered with errors to check`);
  console.log(`${modalRows.length} modal form(s) opened and checked\n`);

  // Modals are checked for marking only. An empty submit in a modal either navigates away or posts
  // to an endpoint that redirects with a flash, so there is no re-rendered form to read errors from
  // -- and driving one would be reporting on a page the reader never sees.
  const modalProblems = [];
  for (const r of modalRows) {
    if (r.unreachable) { modalProblems.push([`${r.name} (${r.path})`, "could not be opened"]); continue; }
    const m = r.marking;
    if (m.unmarked) {
      modalProblems.push([`${r.name} (${r.path})`,
        `${m.unmarked} required field(s) with no visible marker — programmatically required, silently`]);
    }
    if (m.markedNotRequired) {
      modalProblems.push([`${r.name} (${r.path})`,
        `${m.markedNotRequired} field(s) marked required that are not`]);
    }
    if (m.hasAsterisk && !m.markerStyled) {
      modalProblems.push([`${r.name} (${r.path})`, "required marker not styled"]);
    }
  }
  if (modalProblems.length) {
    console.log(`== modal forms — ${modalProblems.length} finding(s)`);
    modalProblems.forEach(([who, what]) => console.log(`   ${who.padEnd(52)} ${what}`));
    console.log("");
  }
  const report = () => {
    if (!unsubmittable.length) return;
    // Always printed, including when there are no findings: a form the probe cannot drive is not
    // a form that passed, and hiding that behind a clean result is how a green audit lies.
    console.log(`\n${unsubmittable.length} form(s) an empty submit does not exercise:`);
    unsubmittable.forEach(([p, why]) => console.log("   " + p.padEnd(40) + why));
  };

  if (!problems.length && !modalProblems.length) { console.log("no findings"); report(); await browser.close(); return; }
  if (!problems.length) { report(); await browser.close(); return; }
  const byProblem = {};
  for (const { path, problems: ps } of problems) for (const p of ps) (byProblem[p] ||= []).push(path);
  for (const [p, paths] of Object.entries(byProblem).sort((a, b) => b[1].length - a[1].length)) {
    console.log(`== ${p} — ${paths.length} form(s)`);
    paths.forEach((x) => console.log("   " + x));
    console.log("");
  }
  console.log(`${problems.length} form(s) with findings`);
  report();
  await browser.close();
})();
