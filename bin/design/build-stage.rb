#!/usr/bin/env ruby
# frozen_string_literal: true

# Assembles one stage of docs/review-plan.md as a local branch off `main`.
#
# **Why this exists rather than a set of pushed branches.** Branches that are not pushed do not
# survive; this working tree has been rolled back eight times. A script committed to `design`
# reproduces the stages on demand, from the same inputs, however many times `main` moves underneath
# them.
#
# **Why each stage names a source commit rather than taking the branch tip.** The tip has every
# later stage's *removals* baked into it. Its `Gemfile` carries Propshaft and no Sass, Bootstrap or
# Sprockets -- so assembling stage 1 from the tip would land stage 4 inside it and unstyle every
# screen not yet converted. The state each stage needs is the one the branch was in when that stage
# was finished, and those states are real commits that were tested at the time.
#
#     ruby bin/design/build-stage.rb 0          # build it
#     ruby bin/design/build-stage.rb 0 --check  # just report what it would contain
#     ruby bin/design/build-stage.rb --list
#
# It never pushes and never opens anything.

require "shellwords"

ROOT = File.expand_path("../..", __dir__)
def git(*args) = `git -C #{ROOT} #{args.map { |a| Shellwords.escape(a) }.join(" ")} 2>&1`

def git!(*args)
  out = git(*args)
  abort "git #{args.join(" ")} failed:\n#{out}" unless $?.success?
  out
end

# `source` is the commit whose tree that stage should be taken from. `HEAD` where the stage's files
# have no later-stage removals in them; a named commit where they do.
#
# `COEXIST` is the commit before Bootstrap and Sass were removed: it has bootstrap, sass-rails,
# sprockets *and* tailwindcss-rails in one Gemfile with all twenty .scss files present. It is what
# stage 1 needs and what the tip cannot give.
COEXIST = "cda053539"

STAGES = {
  "0" => {
    branch: "design-stage-0-url-scheme",
    title: "Reject non-http(s) URLs, and stop rendering them as links",
    source: "HEAD",
    paths: %w[
      app/models/concerns/http_url_validatable.rb
      app/models/organization.rb
      app/models/broadcast_announcement.rb
      app/models/account_request.rb
      app/helpers/application_helper.rb
      spec/models/concerns/http_url_validatable_spec.rb
      spec/helpers/safe_http_url_helper_spec.rb
    ],
    note: "The validation, and the render guard as a helper -- but NOT the two announcement " \
          "views. Those are vulnerable on main and the migration rewrote them completely " \
          "(essentials_status_pill, essentials_row_icon_link), so the one-line guard cannot be " \
          "extracted from them by checkout. Patching them on main is two hand-written lines and " \
          "is not this script's job. The validation alone stops any new bad row, and there are " \
          "none today. See docs/review-plan.md, stage 0 -- and settle the disclosure question " \
          "before this is opened anywhere public."
  },
  "1" => {
    branch: "design-stage-1-foundation",
    title: "The design system foundation: Tailwind alongside Sprockets",
    source: COEXIST,
    paths: %w[
      docs/architecture/
      design.md
      app/assets/
      config/importmap.rb
      config/initializers/assets.rb
      config/initializers/simple_form_essentials.rb
      app/views/layouts/
      app/views/shared/essentials/
      app/helpers/essentials_ui_helper.rb
      app/javascript/
      spec/assets/asset_resolution_spec.rb
      spec/system/essentials_shell_spec.rb
    ],
    # Composed, not taken. `main` still has bootstrap, sass-rails and sprockets, so stage 1's
    # Gemfile is main's plus one line -- and taking COEXIST's instead would drag Rails back to
    # 8.0.2.1 against main's 8.1.3.1. `Gemfile.lock` then falls out of `bundle install`.
    gems: ['gem "tailwindcss-rails", "~> 4.6"'],
    # Files `main` already has that this stage is allowed to change. Everything else it touches
    # must be *new*; an overwrite is a behaviour change hiding inside a foundation stage.
    overwrite: %w[
      app/assets/config/manifest.js
      app/assets/stylesheets/custom.scss
      config/application.rb
      config/initializers/assets.rb
      docs/architecture/decisions/0009-stick-with-adminlte-for-app-design.md
    ],
    # `config/application.rb` cannot be taken whole: COEXIST's also switches the Devise layouts to
    # essentials_auth, which is a later stage. Only the compressor line belongs here.
    insert: {
      "config/application.rb" => {
        after: "    config.active_support.to_time_preserves_timezone = :zone " \
               "# New default starting in Rails 8.1\n",
        text: [
          "",
          "    # sassc-rails defaults config.assets.css_compressor to :sass, and libsass cannot",
          "    # parse the CSS that Tailwind v4 emits (@layer, @property, oklch(), color-mix()) --",
          "    # it dies with \"Internal Error: Not enough space\" the first time anything asks",
          "    # Sprockets for tailwind.css. Nothing is lost by turning it off: the Tailwind CLI",
          "    # already minifies its own output, and production has had this compressor commented",
          "    # out for years, so only the test environment was ever applying it.",
          "    config.assets.css_compressor = nil"
        ].join("\n") + "\n"
      }
    },
    # The Tailwind build is generated. `main`'s .gitignore does not cover it, so without this the
    # stage commits a 120KB artifact.
    ignore: ["/app/assets/builds/*.css"],
    note: "Views, assets and config from #{COEXIST}, not from the tip: the tip's Gemfile has " \
          "Propshaft and no Sass, and the tip's layouts have the old stack already removed."
  }
}.freeze

# Removals that belong to a later stage. If one of these shows up in an early stage, the source
# commit is wrong -- this is the check that would have caught assembling stage 1 from the tip.
LATER_STAGE_MARKERS = {
  "Gemfile" => {
    absent: %w[propshaft],
    present: %w[sprockets sass-rails bootstrap]
  }
}.freeze

def report(stage)
  files = git("diff", "--name-only", "origin/main...#{stage[:source]}", "--", *stage[:paths])
    .split("\n").reject(&:empty?)
  puts "  source:  #{stage[:source]}"
  puts "  files:   #{files.size}"
  files.first(10).each { |f| puts "    #{f}" }
  puts "    ... and #{files.size - 10} more" if files.size > 10
  files
end

# A file the stage *adds* is safe to take from a historical commit. A file that also exists on
# `main` and has moved there since is not: the historical copy silently reverts main's work.
#
# `Gemfile.lock` is the case that proved it. Taken from cda053539 it pins Rails 8.0.2.1 while main
# is on 8.1.3.1, so the stage downgraded Rails and then could not load main's db/schema.rb, which
# declares Schema[8.1]. 878 of 1753 examples failed and none of it was the design system.
#
# Those files have to be composed -- main's current version plus this stage's additions -- by hand.
def check_stale_shared_files(stage)
  files = git("diff", "--name-only", "origin/main...#{stage[:source]}", "--", *stage[:paths])
    .split("\n").reject(&:empty?)

  files.filter_map do |file|
    next unless system("git -C #{ROOT} cat-file -e origin/main:#{file} 2>/dev/null")

    moved = git("log", "--oneline", "#{stage[:source]}..origin/main", "--", file)
      .split("\n").reject(&:empty?)
    [file, moved.size] unless moved.empty?
  end
end

# What this stage's copy of a file will actually say -- which is not always the source commit's
# copy. A composed file is main's version plus the stage's additions, and checking the source
# commit's instead would have been checking a file the stage does not use.
def stage_content(stage, file)
  if stage[:gems] && file == "Gemfile"
    main = git("show", "origin/main:Gemfile")
    return nil unless $?.success?
    compose_gemfile(main, stage[:gems])
  elsif stage[:paths].any? { |p| file == p || file.start_with?(p) }
    content = git("show", "#{stage[:source]}:#{file}")
    $?.success? ? content : nil
  end
end

# Appended at the end, which is safe here: main's Gemfile closes its last block on the final line.
def compose_gemfile(main, gems)
  "#{main.rstrip}\n\n# Added by docs/review-plan.md stage 1: Tailwind alongside the existing\n" \
    "# Sprockets pipeline. Nothing is removed at this stage.\n#{gems.join("\n")}\n"
end

def check_markers(stage)
  problems = []
  LATER_STAGE_MARKERS.each do |file, rules|
    content = stage_content(stage, file)
    next unless content

    rules[:absent].each { |t| problems << "#{file} contains #{t}, which belongs to a later stage" if content.include?(t) }
    rules[:present].each { |t| problems << "#{file} is missing #{t}, which this stage must keep" unless content.include?(t) }
  end
  problems
end

if ARGV.include?("--list") || ARGV.empty?
  puts "Stages in docs/review-plan.md that this can build:"
  STAGES.each { |n, s| puts format("  %-3s %-34s %s", n, s[:branch], s[:title]) }
  puts
  puts "Not yet scripted: 2 (audit suite), 3a-3o (per area), 4 (retire the old stack), 5 (docs)."
  exit 0
end

number = ARGV.first
stage = STAGES[number] or abort "no stage #{number}. `--list` shows what there is."

puts "Stage #{number}: #{stage[:title]}"
files = report(stage)
abort "\nNothing to build: no files differ from main." if files.empty?

problems = check_markers(stage)
unless problems.empty?
  warn "\nThis stage's source commit carries a later stage's changes:"
  problems.each { |p| warn "  #{p}" }
  warn "\nPick a source commit from before those landed. See docs/review-plan.md."
  exit 2
end
puts "  markers: no later-stage removals present"

stale = check_stale_shared_files(stage)
unless stale.empty?
  warn "\n#{stale.size} file(s) exist on main and have moved there since #{stage[:source]}."
  warn "Taking the historical copy would revert main's work:"
  stale.first(12).each { |file, n| warn format("  %-42s %d commit(s) behind main", file, n) }
  warn "  ... and #{stale.size - 12} more" if stale.size > 12
  warn "\nCompose these by hand from main's current version plus this stage's additions."
  warn "Gemfile.lock is the one that bites: a historical copy pins an older Rails, and the stage"
  warn "then cannot load main's schema. See docs/review-plan.md."
  exit 3
end

exit 0 if ARGV.include?("--check")

current = git!("rev-parse", "--abbrev-ref", "HEAD").strip
# Resolve the source to a SHA *before* switching branches. `HEAD` means "the branch I am on now",
# and after `checkout -b` off main that is the new empty stage branch -- so the files this stage
# adds would not exist to check out. Cost: three "pathspec did not match" errors and a branch with
# nothing in it.
source_sha = git!("rev-parse", stage[:source]).strip
abort "working tree is dirty; commit or stash first" unless git("status", "--porcelain").split("\n").reject { |l| l.start_with?("??") }.empty?

git("branch", "-D", stage[:branch])
git!("checkout", "-q", "-b", stage[:branch], "origin/main")
git!("checkout", source_sha, "--", *stage[:paths])

# Hand-composed insertions: a file where only part of the source commit's change belongs to this
# stage. COEXIST's config/application.rb also switches the Devise layouts, which is a later stage.
stage[:insert]&.each do |file, rule|
  path = File.join(ROOT, file)
  content = File.read(path)
  abort "cannot insert into #{file}: anchor not found" unless content.include?(rule[:after])
  File.write(path, content.sub(rule[:after], rule[:after] + rule[:text]))
  git!("add", "--", file)
  puts "  #{file}: composed from main's, plus #{rule[:text].lines.size} line(s)"
end

# Generated files main's .gitignore does not cover. Without this the stage commits the 120KB
# Tailwind build as though it were source.
if stage[:ignore]
  path = File.join(ROOT, ".gitignore")
  File.write(path, "#{File.read(path).rstrip}\n\n# Generated by tailwindcss-rails.\n#{stage[:ignore].join("\n")}\n")
  stage[:ignore].each { |pattern| Dir.glob(File.join(ROOT, pattern.delete_prefix("/"))).each { |f| File.delete(f) } }
  git!("add", "--", ".gitignore")
  puts "  .gitignore: #{stage[:ignore].size} generated pattern(s)"
end

# Additive by default. A foundation stage that quietly replaces one of main's files is a behaviour
# change nobody asked to review -- and this caught two: at COEXIST both confirmation_controller.js
# and donations_modal_controller.js had been rewritten from Bootstrap's modal to the native
# <dialog>, and stage 1 migrates no views, so main's `<div class="modal">` would have reached
# `showModal()`, which is not a function on a div.
# The allowlist includes what this script composed a moment ago, or it reverts its own work: the
# first run undid the .gitignore entry the ignore: step had written, and the Tailwind build came
# back as an untracked 120KB artifact.
allowed = Array(stage[:overwrite]) + stage.fetch(:insert, {}).keys +
  (stage[:ignore] ? [".gitignore"] : [])
clobbered = git("diff", "--cached", "--name-only", "--diff-filter=M", "origin/main")
  .split("\n").reject(&:empty?) - allowed
unless clobbered.empty?
  git!("checkout", "origin/main", "--", *clobbered)
  puts "  reverted #{clobbered.size} overwrite(s) of main's files, keeping the stage additive:"
  clobbered.each { |f| puts "      #{f}" }
end

# The composed files, which no checkout can produce. `bundle install` is what writes Gemfile.lock,
# and it has to run here rather than be left to the reader: a stage whose lock still says Rails
# 8.0.2.1 fails 878 examples and blames the design system.
if stage[:gems]
  path = File.join(ROOT, "Gemfile")
  File.write(path, compose_gemfile(File.read(path), stage[:gems]))
  puts "\n  Gemfile: main's, plus #{stage[:gems].size} line(s). Resolving..."
  abort "bundle install failed -- the stage is half-built" unless system("cd #{ROOT} && bundle install --quiet")
  # `main`'s lock does not list this machine's platform, and a gem with a native executable then
  # has none: tailwindcss-ruby raises ExecutableNotFoundException and every page 500s on a missing
  # stylesheet. The design branch carries aarch64-linux for exactly this reason.
  local = Gem::Platform.local.to_s
  unless File.read(File.join(ROOT, "Gemfile.lock")).include?(local)
    puts "  platform: adding #{local}, which main's lock does not list"
    abort "bundle lock failed" unless system("cd #{ROOT} && bundle lock --add-platform #{local} >/dev/null")
    system("cd #{ROOT} && bundle install --quiet")
  end
  locked = git("diff", "--stat", "--", "Gemfile.lock").split("\n").last.to_s.strip
  puts "  Gemfile.lock: #{locked.empty? ? "unchanged" : locked}"
  rails_version = File.read(File.join(ROOT, "Gemfile.lock"))[/^    rails \((\S+)\)/, 1]
  puts "  rails:   #{rails_version} (main is on #{git("show", "origin/main:Gemfile.lock")[/^    rails \((\S+)\)/, 1]})"
end

# **Commit it.** A stage left staged-but-uncommitted is a trap that has now been sprung twice: the
# next `git checkout design` is refused, `-q` swallows the message, and the commit meant for
# `design` lands on the stage branch instead. A built stage is meant to be a reviewable commit
# anyway.
git!("add", "--", "Gemfile", "Gemfile.lock") if stage[:gems]
git!("commit", "-q", "-m", "Stage #{number}: #{stage[:title]}\n\n" \
  "Assembled by bin/design/build-stage.rb from #{stage[:source]} onto origin/main.\n" \
  "Local only -- this script never pushes.\n\n#{stage[:note]}")

puts "\nBuilt #{stage[:branch]} off origin/main as #{git("rev-parse", "--short=9", "HEAD").strip}."
puts "Nothing has been pushed."
puts "Next, in order:"
puts "  rm -rf tmp/cache                       # Sprockets caches the manifest across branches"
puts "  bundle exec rake -f Rakefile tailwindcss:build"
puts "  RAILS_ENV=test bin/rails db:test:prepare   # the test DB still holds the last branch's schema"
puts "Return with: git checkout #{current}"
