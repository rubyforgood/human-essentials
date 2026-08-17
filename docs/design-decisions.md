# Design decision log

Running log of UI decisions taken while bringing Human Essentials in line with
[`design.md`](../design.md). One entry per decision that **was not already answered by
`design.md`** — where the system was silent, the entry records what was chosen, what industry
practice it follows, and what was rejected.

`design.md` is the spec; this file is the changelog of how the spec grew. When a decision here
becomes a general rule, promote it into `design.md` and link back to the entry.

Format: date · area · decision · rationale · alternatives rejected.

---

## 2026-08-17 · Skip link markup and styling

**Decision.** Add `<a class="skip-link" href="#main-content">Skip to main content</a>` as the
first element inside `<body>` on the two application shells, targeting a
`<main id="main-content" tabindex="-1">` that wraps the yielded page content. Style it in
`custom.scss`: hidden off-screen at `top: -100%`, revealed at `top: 0` on `:focus`.

**Rationale.** WCAG 2.1 AA 2.4.1 (Bypass Blocks). Both shells put a 250px sidebar of 10–16 nav
links plus a navbar ahead of the page content, so a keyboard or screen-reader user tabs through
the entire navigation on every single page. This is the standard remedy and the first item in
`design.md`'s backlog.

**Alternatives rejected.**
- *Bootstrap's `.sr-only-focusable`* — it exists in the bundled Bootstrap 4 and would have been
  the zero-CSS option, but it reveals itself with `position: static`, which pushes the entire
  page down the moment the link takes focus. Absolute positioning is what GOV.UK, USWDS and the
  WAI skip-link pattern all use, precisely to avoid that reflow.
- *A brand-coloured focus ring.* The obvious pick was `$diaper-color-orange-51` (`#f39c12`), the
  app's warning amber, but it is **2.15:1** against white and fails WCAG 1.4.11 (non-text
  contrast, 3:1). The ring is `$diaper-color-neutral-13` (`#222222`) instead, at 15.9:1. Link
  text is `$diaper-color-blue-26` (`#005384`) at 8.06:1 on white.
- *`z-index` left to chance.* Set explicitly to 2000, above AdminLTE's fixed navbar (~1034) and
  sidebar (~1038), so the revealed link is never painted behind the chrome it exists to bypass.

## 2026-08-17 · No skip link on the authentication layout

**Decision.** `layouts/_devise_shared.html.erb` gets `lang`, the viewport fix and a `<main>`
landmark, but **no** skip link.

**Rationale.** 2.4.1 is about bypassing *blocks of content repeated across pages*. The auth
layout is a logo and a single form — there is nothing ahead of the content to skip, and a skip
link that jumps past nothing is noise for the exact users it is meant to serve. Matches how
Polaris, GOV.UK and USWDS scope skip links to pages with navigation.

## 2026-08-17 · `tabindex="-1"` on the skip target

**Decision.** The `<main>` that the skip link targets carries `tabindex="-1"`.

**Rationale.** Without it, Safari and several older browsers scroll to the fragment but leave
focus on the link, so the next Tab returns the user to the top of the navigation — the skip link
appears to do nothing. `tabindex="-1"` makes the element programmatically focusable without
adding it to the tab order. This is the documented WAI workaround.

## 2026-08-17 · One `<main>` per document

**Decision.** The `<main>` landmark lives in the layout. The two page-level `<main>` elements
that already existed (`partners/dashboards/show`, `partners/distributions/index`) were removed.

**Rationale.** Nested `<main>` is invalid HTML and produces two `main` landmarks, which is worse
for landmark navigation than having none. Putting it in the layout also means every page gets one
for free rather than 422 views each having to remember.

**Note.** `static/index` and `static/privacypolicy` render with `layout false`; they are
standalone documents and keep their own single `<main>`.

## 2026-08-17 · Viewport meta: remove the zoom lock outright

**Decision.** `width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no` becomes
`width=device-width, initial-scale=1` on all three live layouts.

**Rationale.** WCAG 1.4.4 (Resize Text) requires 200% zoom; `user-scalable=no` plus
`maximum-scale=1` blocks pinch-zoom entirely on mobile. This app is used on phones in warehouses
by people reading small numbers off dense tables, so the practical cost is real, not theoretical.
iOS has ignored `user-scalable=no` since Safari 10 anyway, so the attribute was mostly harming
Android users only.

**Alternative rejected.** Raising the cap to `maximum-scale=5` — still an arbitrary ceiling, and
there is no reason for this app to impose one.

## 2026-08-17 · `lang` bound to `I18n.locale`, not hardcoded

**Decision.** `<html lang="<%= I18n.locale %>">` rather than `<html lang="en">`.

**Rationale.** WCAG 3.1.1 (Language of Page). Hardcoding `en` is correct *today* — no locale
switching is wired up anywhere in the app (no `set_locale`, no `default_locale` override), so
every request runs at Rails' `:en` default. But the repo ships `es.yml`, `devise.es.yml` and
`simple_form.es.yml`, so Spanish support is half-built and someone will finish it. Binding to
`I18n.locale` renders `en` today and stays correct the day the switch lands, at zero cost.

**Follow-up noted, not actioned.** Those Spanish translations are currently unreachable. Either
wire up locale selection or delete them; leaving them is a trap for the next contributor.
