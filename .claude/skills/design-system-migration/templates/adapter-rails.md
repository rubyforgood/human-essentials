# Adapter: Rails, Devise, Tailwind

One worked example of `adapter.md`, taken from a real suite of **34 audit scripts covering 155
screens**. Everything here is copied from something that runs, not designed for this document.

**What this is not.** It is not evidence that the *interface* generalises. It is a sample of one
stack, and `adapter.md` above describes the shape it fits; whether that shape survives contact with
Django or Next.js is unknown until somebody tries. Read this as "here is how one team did it",
not as a specification.

## The seam is a module, and it is small

```js
module.exports = { BASE, PASSWORD, targets, signIn, visit, RUNS, PARTNER, ADMIN, BANK };
```

Nine exports, ~120 lines. Every audit that imports it stops knowing what framework the app is.

## Route enumeration

**One Rails-shaped line, behind an environment variable:**

```js
const GENERATE = process.env.TARGETS_CMD ||
  "bin/rails runner bin/design/route-targets.rb";
```

Override `TARGETS_CMD` and the rest of the suite works unchanged. That is the whole framework
coupling for route discovery.

The Ruby side walks `Rails.application.routes.routes`, keeps GET routes that render HTML, and
substitutes a real record id for each dynamic segment. Three faults it acquired, all worth stealing
as tests:

- **Skip non-screens by `controller#action`, never by action name.** A filter for one controller's
  internal endpoint hid a full screen on another, and every audit inherited the gap.
- **Resolve each named segment against the model it names.** `/parents/:parent_id/children` scoped
  by the *controller's* record put a child's id in the parent's slot: a 404 that every audit logged
  as "not reached" while a whole unmigrated screen sat behind it.
- **Some screens are addressed by query parameter.** Keep a short explicit map. A guessing scheme
  invents plausible URLs for screens it got wrong, which is worse than not reaching them.

## Caching the list

Regenerate when the cache is older than **anything that determines its contents** — the route file
*and the generator*. Checking only the route file meant editing the generator left a cache that
looked fresh, and two audits reported different answers about one tree.

## Sign in

Devise, and **this is the part still hardcoded** in the source project:

```js
await page.goto(BASE + "/users/sign_out");          // always, first
await page.goto(BASE + "/users/sign_in");
await page.fill('input[name="user[email]"]', email);
await page.fill('input[name="user[password]"]', password);
await page.click('form[action="/users/sign_in"] button[type="submit"], input[type=submit]');
await page.waitForURL((u) => !u.pathname.includes("/sign_in"), { timeout: 60000 });
```

Four details that were each a bug first:

- **Sign out before signing in.** One copy did not, so a second role silently audited the first
  role's pages.
- **Wait for the URL to stop being the sign-in page**, not `networkidle` — three form pages never
  reach idle, and an audit that times out reports what it has as though it were everything.
- **Scope the submit selector to the form.** A bare `button[type=submit]` matches the sign-out
  button hidden inside a closed account menu, and the click waits 30 seconds for it to become
  visible.
- The sign-in values belong in `adapter.md`'s JSON. They are not, here, and that is a gap rather
  than a design.

## Roles

Predicates over the path, one per audience:

```js
const PARTNER = (p) => (p.startsWith("/partners/") && !/^\/partners\/\d+/.test(p)) ||
                       p === "/partners/profile";
const ADMIN   = (p) => p.startsWith("/admin");
const BANK    = (p) => !ADMIN(p) && !PARTNER(p);
const RUNS = [["bank@example.com", BANK], ["partner@example.com", PARTNER],
              ["admin@example.com", ADMIN]];
```

The awkward case earns its comment: `/partners/12` is a *bank* user looking at a partner record,
while `/partners/requests` is the partner portal. Two applications under one prefix.

## Visiting

```js
async function visit(page, urlPath, { timeout = 60000 } = {}) {
  const res = await page.goto(BASE + urlPath, { waitUntil: "domcontentloaded", timeout })
    .catch(() => null);
  if (!res || res.status() >= 400) return null;      // "not checked" is not "fine"
  await page.waitForLoadState("load", { timeout: 3000 }).catch(() => {});
  res.landed = new URL(page.url()).pathname;          // redirects matter
  return res;
}
```

**Return null rather than throwing**, so a caller can tell "did not load" from "loaded and was
fine" — and then *count the nulls*, because a skipped page and a clean page otherwise produce the
same summary line.

**Record where it landed.** Redirects mattered three times in one project: two paths that are one
screen, a show page that redirects to a sub-resource, and an approve action that redirects back to
an index *with a flash bar*, which one audit read as a second, differently-positioned strip.

## The honest part: a seam nobody adopts is not a seam

Measured in the source project on 2026-09-04, well after the seam was introduced:

| | |
| --- | --- |
| Browser audits using the seam | **7** |
| Audits shelling out to the generator directly | **13** |
| Files still carrying their own `signIn` | **16** (at least two byte-identical) |

The change log for the commit that introduced it said it was "replacing 21 hand-copied `signIn`
functions". It was not: it made 21 *replaceable* and converted seven. The distinction is invisible
until somebody counts, and the row has been corrected.

So the lesson to carry, which is worth more than the code above: **introducing the seam is the
easy tenth of the work.** Budget for the migration of every existing caller, or accept that you have
added a ninth way of doing something and removed none. If you cannot migrate them all at once, put
a check in the audit suite that fails on a new private `signIn`, so the number can only go down.
