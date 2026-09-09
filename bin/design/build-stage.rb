#!/usr/bin/env ruby
# frozen_string_literal: true

# AUDIT-READS: AUDITS
#
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
      Gemfile
      Gemfile.lock
      app/assets/
      config/importmap.rb
      app/views/layouts/
      app/views/shared/essentials/
      app/helpers/essentials_ui_helper.rb
      app/javascript/
    ],
    note: "Taken from #{COEXIST}, not from the tip: the tip's Gemfile has Propshaft and no Sass."
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

def check_markers(stage)
  problems = []
  LATER_STAGE_MARKERS.each do |file, rules|
    next unless stage[:paths].any? { |p| file == p || file.start_with?(p) }

    content = git("show", "#{stage[:source]}:#{file}")
    next unless $?.success?

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
puts "\nBuilt #{stage[:branch]} off origin/main. Nothing has been pushed."
puts "Return with: git checkout #{current}"
