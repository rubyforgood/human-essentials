# Adapter

The one place that knows what framework this app is. Everything else is about design.

## Sign in

```json
{
  "base_url": "http://127.0.0.1:3000",
  "sign_in_path": "/users/sign_in",
  "identifier_selector": "input[name='user[email]']",
  "secret_selector": "input[name='user[password]']",
  "credential": "..."
}
```

Sign **out** before signing in. Several roles through one browser context means a stale session
silently audits the previous role's pages.

Wait for the URL to stop being the sign-in page. Not `networkidle` — it never settles on a page with
a long poll, and an audit that times out reports what it has as though it were everything.

## Enumerate routes

A command printing every screen as JSON:

```json
[{"path": "/items", "controller": "items", "action": "index"}]
```

| Framework | Command |
| --- | --- |
| Rails | `rails runner route-targets.rb` |
| Django | read `urls.py` |
| Laravel | `artisan route:list --json` |
| Next.js | walk the app directory |

Substitute a real record id for `:id`. Skip genuine non-screens — downloads, exports, one-shot state
changes — **by `controller#action`, never by action name alone.** A bare-name filter meant for one
controller will hide a real screen on another, and every audit inherits it.

Regenerate the list when it is older than the route definitions. A stale list is the failure this
whole arrangement exists to prevent.

## Roles

One predicate per audience, so an audit can visit each screen as somebody who can see it.
