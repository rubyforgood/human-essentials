# Landing this branch: a staged review plan

`design` is **602 commits and 1,051 files** ahead of `main` (+89,606 / −24,093). `CONTRIBUTING.md`
asks contributors to *"keep your PRs limited to one particular issue"*. One pull request of this
size would not be reviewed; it would be approved on trust or left to rot, and both are worse than
not opening it.

This is the plan for landing it in pieces that can actually be read, in an order where **`main`
works after every one**.

## What the diff is actually made of

Measured 2026-09-09 against `origin/main`.

| Area | Files | Lines |
| --- | --- | --- |
| Documentation (`docs/`, `design.md`, `CLAUDE.md`, README, CONTRIBUTING) | 86 | +36,393 |
| Views (`app/views`, all) | 456 | +12,493 / −14,306 |
| Specs | 183 | +8,101 / −2,108 |
| Audit suite (`bin/design`) | 41 | +8,247 |
| Assets, `Gemfile`, importmap | 33 | +5,128 / −1,139 |
| JavaScript | 50 | +3,528 / −3,569 |
| Layouts and `shared/essentials` components | 51 | +1,975 / −1,267 |
| Helpers | 15 | +1,909 / −263 |
| Controllers, models, services, queries | 87 | +1,142 / −239 |
| `db/`, `config/` | 22 | +724 / −562 |

**41% of the added lines are documentation**, which is read rather than executed and can be
reviewed on its own terms.

Of the 602 commits, **221 are "Fill in the change log hash"** bookkeeping and 5 are merges, leaving
**376 substantive**. Reviewers should read *diffs per stage*, not the commit sequence; each stage
should be squashed or rebased to a readable set before it is opened.

## The constraint that dictates the order

`main` has **20 Sass files** and the `sass-rails` + `sprockets` + `bootstrap` gems. **Propshaft
compiles no Sass** (ADR 0012). So the pipeline switch cannot come before the view migration: the
moment Propshaft lands, every `.scss` stops compiling and every unmigrated screen loses its
styling.

The branch's own history is the proof that a staged order works. Tailwind entered at **commit 2 of
602**, alongside Sprockets; Sass and Bootstrap left at **22**; Propshaft replaced Sprockets at
**114**. Tailwind and the old stack coexisted for the whole middle of the migration, which is
exactly what makes area-by-area PRs possible.

## Stage 0 — the security fix, and a question before it

**This does not belong in the migration at all.** `Organization#url`,
`BroadcastAnnouncement#link` and `AccountRequest#organization_website` validate with
`URI::DEFAULT_PARSER.make_regexp` and no scheme argument, which accepts `javascript:`; two views on
`main` render `link_to broadcast_announcement.link, broadcast_announcement.link`. **The
vulnerability is live on `main` today**, independent of anything on this branch.

**Built and verified against `main` on 2026-09-09**, seven files: the `HttpUrlValidatable` concern,
the three models, `safe_http_url` in `ApplicationHelper`, and two specs. 41 examples, rubocop clean,
**brakeman 0 warnings**, and `javascript:alert(1)` rejected where `http://` is accepted. Reproduce
it with `ruby bin/design/build-stage.rb 0`.

**What it does not contain, and this is the third thing building the plan corrected.** The two
views that render `BroadcastAnnouncement#link` are the widest exposure and are vulnerable on `main`
— they were the reason for including a render guard at all. They cannot be extracted: the migration
rewrote them completely, into `essentials_status_pill`, `essentials_row_icon_link` and
`essentials_row_icon_action`, so taking the file drags the migration into a security PR. The check
for that caught it — **8 design-system references in a stage that must not have any**.

So stage 0 stops every *new* bad row, and there are **0** bad rows today across all three fields.
`main`'s two render sites stay as they are until the announcements area is converted. If the
maintainers want them guarded sooner, that is a two-line hand-written patch against `main`, not an
extract from this branch, and it is deliberately not in the script.

**Verifying a stage costs a `bundle install` each way.** `main`'s lockfile wants `sprockets`,
`terser` and `execjs`, which this branch removed, so the gems have to be installed to run the
stage's specs and reinstalled to come back. Budget for it; do not skip the verification because of
it.

**The question, which is not mine to answer**: there is no `SECURITY.md` and no disclosure channel
in `CONTRIBUTING.md`. Opening a public pull request titled "fix stored XSS" tells everyone watching
about a live vulnerability in an app used by 200+ non-profits, before any deploy. The alternatives
are a private report to the maintainers first, or a PR whose title and body describe it as input
validation hardening without a working exploit. **Decide this before the branch is pushed.**

## Stages

Each is a branch off `main`, opened when the previous is merged. Sizes are the diff a reviewer
sees, not the commit count.

| # | Branch | What it is | Files | Risk |
| --- | --- | --- | --- | --- |
| 0 | `url-scheme-validation` | The three validations + specs. No UI. | ~6 | None to the UI; fixes a live hole |
| 1 | `design-system-foundation` | ADRs 0010 and 0011, the 0009 supersession, `design.md`, Tailwind **alongside** Sprockets, tokens, `application.css`, `shared/essentials/*`, `EssentialsUiHelper`, the new layouts and the Stimulus controllers they need. Nothing renders on it yet. | ~135 | Low — adds an unused stylesheet and unused partials |
| 2 | `design-audit-suite` | `bin/design/*` and the `audit-selftest` workflow. Tooling only. | ~45 | None to the app |
| 3a–3o | `design-<area>` | One per area: dashboard, items, donations, purchases, distributions, transfers, adjustments, audits, storage locations, partners, requests, reports, organization/users, admin, partner portal. Each flips its controllers to `essentials_app` and converts its views and specs. | 15–60 each | **The real review**, and the reason for the whole exercise |
| 4 | `retire-bootstrap-adminlte` | ADR 0012, then remove Bootstrap, AdminLTE, jQuery, Sass; Sprockets → Propshaft. Only possible once no view needs Sass. | ~60 | High, but mechanical by then |
| 5 | `design-docs` | `onboarding.md`, `migration-map.md`, `domain-model.md`, the change log. | ~20 | None |

Stages 3a–3o are independent of each other once 1 is merged, so they can be opened in parallel and
reviewed by different people.

### The ADRs are not a separate first stage, and trying it is how I found out

The first draft of this plan opened with `adr-design-decisions`: the ADRs alone, no code, the
reasoning available to argue with before anything was built. It was an attractive stage and it does
not exist.

Built against `main`, it failed its own link check. **ADR 0010 links to `design.md`**, which is not
on `main` — it arrives with the foundation. Dropping 0010 to fix that broke a second link, because
**0010 and 0011 reference each other**. The three new ADRs and the spec they describe are one
reviewable unit whether or not that is convenient, so they are stage 1, and ADR 0012 travels with
the Propshaft change it describes in stage 4.

The check that caught it is four lines of shell — resolve every relative `.md` link in the staged
files against the files that stage actually contains — and it is worth running on any
documentation-carrying stage before it is opened.

### Build each stage from the branch's history, not from its tip

The obvious way to assemble stage 1 is `git checkout design -- <foundation paths>`. That is wrong,
and quietly so. The tip's `Gemfile` has **Propshaft, and no Sass, Bootstrap or Sprockets** — stage 4's
removals are baked into it. Taking it would land stage 4 inside stage 1 and unstyle every screen
that has not been converted yet. The same is true of `app/assets/stylesheets/`, where the tip has
deleted the twenty `.scss` files that stage 1 must keep.

The state each stage needs is the one the branch was actually in when that stage was finished, and
it exists in the history. Bootstrap and Sass were removed at `3efdd73a2`; the commit before it,
`cda053539`, has `bootstrap`, `sass-rails`, `sprockets` **and** `tailwindcss-rails` in the same
`Gemfile`, with all twenty `.scss` files present. That is stage 1's coexistence state, and it is a
tree that was tested rather than a combination invented at assembly time.

So: for each stage, find the commit at which it was complete, and take that stage's paths from
**there**. Check the result for later stages' removals before opening it — the `Gemfile` and
`app/assets/` are where they hide.

### Historical for what a stage adds; main's for what it shares

The rule above — take a stage's files from the commit where it was finished — is right for files
the branch **adds**. It is wrong for files that also exist on `main` and have moved there since,
and the failure is loud but misleading.

Stage 1 took `Gemfile` and `Gemfile.lock` from `cda053539`. That lockfile pins **Rails 8.0.2.1**;
`main` is on **8.1.3.1**. So the stage quietly downgraded Rails, and then could not load `main`'s
`db/schema.rb`, which declares `Schema[8.1]`. **878 of 1,753 examples failed**, every one of them
reporting something like `undefined method 'address=' for StorageLocation` — nothing whatsoever to
do with the design system, and easy to spend an afternoon on.

So, per file:

| | |
| --- | --- |
| The stage **adds** it | take it from the stage's completion commit |
| It exists on `main` and `main` has changed it since | **compose by hand**: `main`'s current version plus this stage's additions |

For stage 1 that means one line — `gem "tailwindcss-rails", "~> 4.6"` added to `main`'s `Gemfile`,
then `bundle install` to regenerate the lock against `main`'s Rails. Not a checkout.

`build-stage.rb` detects this now and refuses with exit 3, naming each file and how many commits
behind `main` it is. Stage 1 currently reports `Gemfile` 5 behind and `Gemfile.lock` 30.

### And a stage needs its own database, not just its own gems

`RAILS_ENV=test bin/rails db:test:prepare` on the stage branch. The test database persists between
checkouts, so a stage inherits whatever schema the last branch left — which for stage 1 meant
`main`'s models looking for an `address` column this branch had dropped.

## What each stage must prove before it is opened

Not a suggestion — this is what the branch itself was held to, and it is why the merge from `main`
went in cleanly.

0. **Every relative `.md` link resolves against the files that stage contains.** Four lines of
   shell, and it is what disproved the original stage 1.
1. **No later stage's removals are present** — check `Gemfile` and `app/assets/` specifically.
2. **`bundle install`, then `RAILS_ENV=test bin/rails db:test:prepare`** — a stage needs its own
   gems *and* its own schema, and both persist between checkouts.
3. `bundle exec rspec` green, and the *new* specs watched failing first.
3. `bundle exec rubocop` and `bundle exec erb_lint --lint-all` clean.
4. `bundle exec brakeman` — **0 warnings**. Four of the six CI workflows are covered by the design
   suite; brakeman and `factory_bot:lint` are the two that are not, and the stage 0 vulnerability
   is what was hiding in that gap.
5. `RAILS_ENV=test bundle exec rake factory_bot:lint`.
6. From stage 2 onwards: `ruby bin/design/which-audits.rb main` and run what it names.
7. From stage 3 onwards: `pw bin/design/route-sweep.js` — every screen still renders — and
   `python3 bin/design/undefined-classes.py`, which is what catches a half-converted view.

## Known risks

**A reviewer cannot hold 456 changed views in their head.** Mitigation: stages 4a–4o are per area,
and each carries the screenshots already in `docs/mockups/` for the screens it changes.

**Stage 5 is where it can break in production**, because it deletes the fallback. Mitigation: it
lands last, after every area is on the new layout and `status.rb` reports 0 views on the old
system; the branch already reports that.

**The branch will drift while this runs.** Fifteen area PRs reviewed at "within a week or so"
(CONTRIBUTING) is months. `docs/onboarding.md` has the post-merge routine for taking `main` in
repeatedly; expect to run it several times.

**Squashing loses the reasoning.** 376 substantive commits carry the *why* — the measurements, the
rejected alternatives, the defects found. Squash within a stage, never across one, and keep the
change log rows, which are the durable record.
