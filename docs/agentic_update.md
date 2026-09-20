# Sweeping user-guide updates with an AI agent

This describes the process used in September 2026 to bring the bank user guide
(`docs/user_guide/bank/`) up to date: documenting a batch of merged feature
PRs, then walking every page of the guide to refresh text, screenshots and
annotations, and finally splitting the result into reviewable pull requests.
It was done with Claude Code driving a local checkout, the running dev app and
the Playwright MCP plugin, but the steps are the same for a person or any other
agent. The goal of writing it down is that the next sweep is faster and lands
in the same style.

The reusable pieces live in [`docs/utils/`](utils/):

- [`utils/screenshots/`](utils/screenshots/README.md): spec-driven Playwright helper for annotated screenshots.
- [`utils/check_guide_images.sh`](utils/check_guide_images.sh): missing and orphaned image check.

## 1. Set up

- Check out a working branch from `main`, e.g. `guide-updates`. Everything is
  committed here first; PR branches are carved out at the end (section 6).
- Reset the local database to seed data (`bin/rails db:reset` or `bin/setup`)
  so screenshots show the Pawnee Diaper Bank sample data that the rest of the
  guide uses. Start the app with `bin/start`.
- Log-ins used throughout: `org_admin1@example.com` (bank admin),
  `user_1@example.com` (bank user), `verified@example.com` (partner). All
  passwords are `password!`.
- Preview the guide as readers see it: `cd docs && bundle exec jekyll serve
  --livereload`, then open http://localhost:4000/user_guide/bank/. Jekyll picks
  up markdown edits immediately, which makes it easy to check relative links
  and image paths.
- If the agent is Claude Code, the Playwright MCP plugin is what takes the
  screenshots. It can only read files inside the repository; `.playwright-mcp/`
  (untracked) is a convenient place for specs and generated snippets.

## 2. Scope the feature work

For each merged app PR that needs documenting:

1. Read the PR description and diff (`gh pr view N`, `gh pr diff N`). Note the
   user-visible change: new fields, renamed statuses, new buttons, new emails,
   new settings.
2. Find where the guide already talks about that area:
   `grep -rn -i "audit" docs/user_guide/bank/*.md`. Features usually touch more
   than one page (a setting on the organization page plus the form it affects
   plus the partner-side view). List all of them.
3. Open the feature in the running app and click through it before writing
   anything. Take quick unannotated exploratory captures to look at; do not
   spend time annotating until the text is settled.
4. Write the text, then the annotated screenshots (section 4), then commit
   with a message naming the PR: `User guide: document request limits on
   Items (#5386)`. One commit per feature keeps the later PR split trivial.

Things that came up and how they were handled:

- If the app's behaviour looks wrong or a label is confusing, that is an app
  issue, not a docs issue. Document what the app does and raise the app
  problem separately rather than describing what it "should" do.
- Behaviour that only applies to migrated data ("banks that existed before X
  have both switches on") tends to get deleted in review. Prefer describing
  the current behaviour.
- Emails: the mailer preview pages (`/rails/mailers`) are the easiest way to
  screenshot an email consistently.

## 3. Build the burn-down list

Before the sweep, inventory the guide so progress is visible and nothing is
skipped:

```sh
ls docs/user_guide/bank/*.md | wc -l                 # pages
grep -rhoE '\]\(images/[^)]+' docs/user_guide/bank/*.md | sort -u | wc -l   # image references
docs/utils/check_guide_images.sh                      # broken refs, orphans
```

Keep the list somewhere both you and the agent can see (a markdown table in
the conversation, a scratch file, a dashboard). Each row is a page with a
status and a one-line note. The order that worked: Getting Started, Everyday
Essentials, Partners, Inventory, Community, Reports, User and Account
Management. Getting Started overlaps with everything else, so doing it first
means later pages can link to it.

Also list the merged PRs from section 2 as rows so the two kinds of work are
tracked in the same place.

## 4. The per-page review loop

For every page:

1. **Read the page** end to end, and open each screen it describes in the
   running app side by side.
2. **Compare text to UI.** Button labels, menu names, column headers, tab
   names, status words and field names must match the app exactly, including
   capitalisation and quotes. Numbered steps must match the numbered
   annotations in the image below them. Watch for features that have been
   removed or renamed since the page was written.
3. **Fix links.** Relative links between pages (`[Partners](partners.md)`) and
   anchors. The Jekyll preview catches most of these.
4. **Re-shoot every annotated screenshot** on the page rather than deciding
   image by image whether it is stale. Uniform width, crop and annotation
   style across a page matters more than saving a few captures. Keep the same
   filename so the markdown does not need to change; retire an image only by
   deleting it and its reference together.
5. **Look at each image** after it is written. The helper reports where it
   drew boxes, which catches a selector that matched nothing, but only your
   eyes catch a box on the wrong button, a stale flash message or an
   unexpected dev toolbar.
6. **Commit per page or per small group of pages** with a message like
   `User guide: refresh Partners screenshots and fix invite steps`. Frequent
   small commits made the PR split at the end cheap.

Screenshot conventions and the spec format are in
[`utils/screenshots/README.md`](utils/screenshots/README.md). In short:
1400px wide, content cropped from x=250 unless the sidebar is the subject,
red 3px boxes with red numerals matching the text, nothing boxed that the app
already highlights.

State that had to be toggled for screenshots (put it back afterwards):

```sh
bin/rails runner 'Organization.find_by!(name: "Pawnee Diaper Bank").update!(bank_is_set_up: false)'  # Getting Started prompt
bin/rails runner 'Partner.find_by!(name: "Pawnee Middle School").update!(status: :awaiting_review)'  # approval buttons
```

## 5. Verify before splitting

- `docs/utils/check_guide_images.sh` reports nothing missing.
- Jekyll preview: click through every page once, looking for broken images
  and links.
- `git diff --stat main` shows only `docs/` (and any gem changes you meant to
  make for the docs site).
- Spot check a handful of right-aligned annotations (buttons in card headers,
  table action columns). Those are the ones that drift when something is wrong
  with the capture flow.

## 6. Split into pull requests

Reviewers cannot usefully review one PR with several hundred image changes.
The split that worked, as a stacked chain where each PR's base is the previous
branch:

| # | Contents | Why separate |
| --- | --- | --- |
| 1 | Tooling fixes (e.g. gems so Jekyll runs on the current Ruby) | Zero-risk, merge first |
| 2 | Typos and broken links | Mechanical, easy to approve |
| 3..8 | One PR per documented feature PR | Reviewer is often the feature's author |
| 9 | Previously undocumented features found during the sweep | Needs a real read |
| 10..13 | Screenshot refresh, one PR per guide section | Big but skimmable |

Rules that were requested for these PRs:

- Cross-link: each feature-doc PR says "Documents #NNNN" and links back, and
  a comment on the app PR links to the docs PR.
- Anything with significant generated prose is opened as a **draft** so the
  maintainer can rewrite before asking others to review. Mechanical PRs
  (gems, typos, links) can be opened ready.
- Each PR body lists the pages touched and notes what a reviewer should look
  at (e.g. "check the numbered steps against the image").

Mechanics. Local branches were named `pr/NN-topic` and pushed as
`guide/NN-topic` so the remote names sort together:

```sh
git checkout -b pr/03-request-limits main
git cherry-pick <feature commit shas>
git push -u origin pr/03-request-limits:refs/heads/guide/03-request-limits
gh pr create --draft --base guide/02-typos-links --head guide/03-request-limits --title "..." --body-file body.md
```

Screenshot-section PRs are made the same way with `git checkout
guide-updates -- docs/user_guide/bank/images/partners` on a branch based on
the previous PR branch, then one commit. Check at the end that the tip of the
last PR branch has the same tree as the working branch:
`git diff --stat pr/13-... guide-updates` should be empty.

## 7. Respond to review

Review comments on screenshot PRs are mostly "this box is off" or "this image
does not show what the text says". The loop:

1. Reproduce the problem locally (open the image, compare with the app).
   Often one comment reveals a systematic cause; in September 2026 a single
   ordering bug in the capture helper had shifted every right-aligned box, so
   every annotated image was re-taken, not only the flagged ones.
2. Fix on the working branch, commit, then add a commit to the affected PR
   branch (`git checkout guide-updates -- <paths>`), and rebase the branches
   above it: `git rebase --onto pr/12-... <old pr/12 tip> pr/13-...`.
3. Push with a lease against the SHA you fetched, never with a bare force:

   ```sh
   git fetch origin
   git ls-remote origin refs/heads/guide/12-inventory      # note the sha
   git push origin --force-with-lease=refs/heads/guide/12-inventory:<sha> pr/12-inventory:refs/heads/guide/12-inventory
   ```

   The maintainer may apply suggestions on GitHub directly; a bare `--force`
   once overwrote one of those commits and it had to be recovered from the
   reflog.
4. Reply on every thread with what changed and the commit, or with the reason
   for not changing it (for example, not boxing something the app already
   highlights in red). Use `gh api repos/OWNER/REPO/pulls/N/comments/ID/replies -f body=...`
   to answer inline threads.

## 8. Checklist for the agent prompt

When kicking off the next sweep, the prompt that worked contained:

- the list of merged PR numbers to document;
- that the local environment is reset and may be used freely (including
  restarting services);
- "make a burn-down list and walk the whole guide, including fresh screenshots
  and annotations";
- "commit locally as you go so we can split into PRs later";
- pointers to this document and `docs/utils/`.

Things to say up front if you care about them, because they were asked for
mid-way last time: draft status for generated PRs, cross-links to the app
PRs, and any formatting rule for commit messages.
