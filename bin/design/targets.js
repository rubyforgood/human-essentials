// Which screens exist, who can see them, and how to sign in.
//
// **This is the seam between the audits and the application.** Everything above it is a rule about
// design -- is this control named, is this focus ring visible. Everything below it is Rails: how to
// ask the router for a list of screens, and what the sign-in form looks like. An audit that reaches
// past this file to talk to the app directly is an audit that cannot be pointed at another app.
//
// It replaces three things that were copied by hand across the suite: **21 copies of `signIn`**,
// seven of the role predicates, and six of the targets-file read. Four of the `signIn` copies had
// drifted -- one did not sign out first, so a second role silently reused the first one's session;
// one waited on `networkidle`, which times out on the slowest screens in this app and has already
// caused two audits to give up mid-run and report what they had as though it were the whole app.
//
// **Why a generated file rather than each audit shelling out to Rails.** The file is the contract:
// a list of `{path, controller, action}`. Any framework can produce it -- `urls.py`, `route:list
// --json`, a walk of an app directory -- and no audit needs to know which one did. Shelling out
// would put `bin/rails` in twenty files and cost a Rails boot each time.
//
// Staleness is the obvious objection to a generated file, so it regenerates itself: if the file is
// missing, or older than `config/routes.rb`, it is rebuilt before it is read.
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const BASE = process.env.BASE_URL || "http://127.0.0.1:3000";
const PASSWORD = process.env.SEED_PASSWORD || "password!";

const TARGETS_FILE = process.env.TARGETS || "/tmp/targets.json";
const ROOT = path.resolve(__dirname, "../..");
// The one Rails-shaped line in this file. Override it and the rest works unchanged.
const GENERATE = process.env.TARGETS_CMD ||
  "bin/rails runner bin/design/route-targets.rb";
const ROUTES_FILE = path.join(ROOT, "config/routes.rb");

function stale() {
  if (!fs.existsSync(TARGETS_FILE)) return true;
  if (!fs.existsSync(ROUTES_FILE)) return false;
  return fs.statSync(TARGETS_FILE).mtimeMs < fs.statSync(ROUTES_FILE).mtimeMs;
}

let cached = null;

// Every screen the router knows about, with a real record id substituted for `:id`.
function targets() {
  if (cached) return cached;
  if (stale()) {
    process.stderr.write("targets.json is missing or older than config/routes.rb; regenerating\n");
    fs.writeFileSync(TARGETS_FILE, execSync(GENERATE, { cwd: ROOT, maxBuffer: 32 * 1024 * 1024 }));
  }
  cached = JSON.parse(fs.readFileSync(TARGETS_FILE, "utf8"));
  return cached;
}

/*
 * Who can see what.
 *
 * `/partners/...` is the partner portal, except `/partners/12`, which is a bank user looking at a
 * partner record -- the two live under one prefix and are different applications.
 */
const PARTNER = (p) => (p.startsWith("/partners/") && !/^\/partners\/\d+/.test(p)) || p === "/partners/profile";
const ADMIN = (p) => p.startsWith("/admin");
const BANK = (p) => !ADMIN(p) && !PARTNER(p);

// The three passes an audit makes if it wants to see the whole app.
const RUNS = [
  ["org_admin1@example.com", BANK],
  ["verified@example.com", PARTNER],
  ["superadmin@example.com", ADMIN]
];

/*
 * Sign in as somebody.
 *
 * **Signs out first**, because these run several roles through one browser context and a stale
 * session means the second role silently audits the first role's pages.
 *
 * Fields are found by `name`, not by `id`: the ids come from Devise's form builder and change if
 * the form is ever rebuilt, and one copy of this function was already selecting on `#user_email`
 * while another used the name.
 *
 * Waits for the URL to stop being the sign-in page rather than for `networkidle`, which never
 * settles on the slowest screens here.
 */
async function signIn(page, email, password = PASSWORD) {
  await page.goto(BASE + "/users/sign_out", { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.goto(BASE + "/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.fill('input[name="user[email]"]', email);
  await page.fill('input[name="user[password]"]', password);
  await page.click('form[action="/users/sign_in"] button[type="submit"], input[type=submit]');
  await page.waitForURL((u) => !u.pathname.includes("/sign_in"), { timeout: 60000 });
}

/*
 * Go to a screen and wait for it to be usable.
 *
 * `domcontentloaded` plus `load`, never `networkidle`: three form pages in this app take longer
 * than the 30-second idle timeout, and an audit that gives up on a page reports it as clean.
 * Returns null for anything that did not load, so a caller can tell "not checked" from "fine".
 *
 * **Returns where it landed, not where it was asked to go.** Redirects are common here and the
 * distinction has mattered three times: `/` and `/dashboard` are one page, `kits#show` redirects to
 * its allocations, and `/partners/1/approve_application` redirects to `/partners` *with a flash
 * bar* -- which the tab-set audit read as the same strip sitting 72px lower on a second tab. An
 * audit that groups or counts pages should key on `landed`.
 */
async function visit(page, urlPath, { timeout = 60000 } = {}) {
  const res = await page.goto(BASE + urlPath, { waitUntil: "domcontentloaded", timeout })
    .catch(() => null);
  if (!res || res.status() >= 400) return null;
  await page.waitForLoadState("load", { timeout: 15000 }).catch(() => {});
  await page.waitForTimeout(120);
  res.landed = new URL(page.url()).pathname;
  return res;
}

module.exports = { BASE, PASSWORD, targets, signIn, visit, RUNS, PARTNER, ADMIN, BANK };
