#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Given a diff, which audits could it have moved?
#
# This exists because of a specific failure. A change removed fifty keyboard tab stops and altered
# two control sizes, and the audits re-run afterwards were chosen from memory -- so `keyboard-audit`,
# `wcag22-audit`, `row-actions-audit`, `tooltip-audit`, `wcag-audit`, `icon-audit` and `table-audit`
# were all skipped, every one of them a check that measures exactly what had just changed. Earlier
# the same day a real defect was found sitting in a *passing-looking* audit's output, unread.
#
# **A checklist would not fix this.** A checklist is memory written down: complete on the day it is
# written and silently wrong the day an audit is added. So the rule is not "remember the list" but
# *omission is impossible by construction*:
#
#   1. This script enumerates `bin/design/*.{js,rb,py}` itself. It never carries a list of audits.
#   2. Each of those files must either declare what it reads, or be named below as not an audit,
#      with a reason. A file that is neither **fails the run**. A new audit cannot be forgotten --
#      it can only be declared or explicitly excused.
#   3. It prints what it considered and did *not* select, because "three audits to run" and "three
#      audits, having considered thirty" are different claims.
#
# The declaration lives in the audit itself, near the top, so it cannot drift from what it describes:
#
#     # AUDIT-READS: RENDER
#     // AUDIT-READS: VIEWS, DOCS
#
# Deliberately coarse. A browser audit driving real pages is affected by anything in the render
# path, and pretending otherwise would give a precise answer that is wrong. Over-selecting costs a
# run; under-selecting is the thing this exists to prevent.
#
#     ruby bin/design/which-audits.rb              # the last commit, plus anything uncommitted
#     ruby bin/design/which-audits.rb HEAD~3       # a range you name
#     ruby bin/design/which-audits.rb --staged     # what you are about to commit
#
# Exit codes: 0 nothing to run, 1 audits selected, 2 a file is neither declared nor excused.

ROOT = File.expand_path("../..", __dir__)

# Named bundles, so a one-line declaration can say "anything that changes what a page renders"
# without every audit restating the render path and getting it subtly different.
BUNDLES = {
  # Everything that can change the HTML a screen produces. Controllers are here because the ivars
  # a view reads are set there; `config/initializers` because simple_form rewrites every input.
  "RENDER" => %w[app/views/ app/helpers/ app/javascript/ app/assets/ app/controllers/
    app/models/ config/routes.rb config/initializers/ config/importmap.rb],
  "VIEWS" => %w[app/views/],
  "RUBY" => %w[app/ lib/ config/],
  "CSS" => %w[app/assets/],
  "ROUTES" => %w[config/routes.rb app/controllers/],
  "DOCS" => %w[design.md docs/ README.md CONTRIBUTING.md bin/design/README.md],
  "AUDITS" => %w[bin/design/]
}.freeze

# Not audits. Each says why, because "it is not in the list" is exactly the silence this script
# exists to remove: an unexplained absence reads the same as an oversight.
NOT_AN_AUDIT = {
  "targets.js" => "the seam every browser audit imports: screens, roles, sign-in",
  "route-targets.rb" => "generates the target list that targets.js caches",
  "state.rb" => "regenerates the change log's Current state table; gated by its own --check",
  "status.rb" => "a report, not a check: which controllers render on a design system layout",
  "audit.js" => "a one-off page inspector for a human, documented as an exception in README.md",
  "which-audits.rb" => "this script"
}.freeze

def matches?(patterns, path)
  patterns.any? do |pattern|
    if pattern.end_with?("/")
      path.start_with?(pattern)
    else
      path == pattern || File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
    end
  end
end

def declaration_for(file)
  # Only the head of the file: a declaration at line 400 is not one a reader would find.
  head = File.foreach(file).first(60).join
  return nil unless (m = head.match(/AUDIT-READS:[ \t]*(.+)$/))

  m[1].split(",").map(&:strip).reject(&:empty?)
end

def expand(tokens, file)
  tokens.flat_map do |token|
    if BUNDLES.key?(token)
      BUNDLES[token]
    elsif token.match?(%r{\A[\w./*{}\[\]-]+\z})
      [token]
    else
      abort "#{file}: AUDIT-READS names #{token.inspect}, which is neither a bundle " \
            "(#{BUNDLES.keys.join(", ")}) nor a path pattern"
    end
  end
end

# --- what changed ------------------------------------------------------------------------------

# **The default is the last commit, not the branch.** Against `main` on a long-lived branch this
# selected all 30 audits from 1,096 changed files -- true, and useless: an answer of "run
# everything" is one nobody runs, which is the same outcome as not asking. The question worth
# answering mechanically is "I just changed this; what did I break the reading of?"
arg = ARGV.first
diff =
  if arg == "--staged"
    "git -C #{ROOT} diff --cached --name-only"
  elsif arg
    "git -C #{ROOT} diff --name-only #{arg}...HEAD"
  else
    "git -C #{ROOT} diff --name-only HEAD~1...HEAD"
  end

changed = `#{diff}`.split("\n").map(&:strip).reject(&:empty?)
# Uncommitted work counts: the usual moment to ask this question is before committing.
changed |= `git -C #{ROOT} status --porcelain`.split("\n").map { |l| l[3..].to_s.strip }.reject(&:empty?)

if changed.empty?
  puts "nothing changed against that reference, and nothing uncommitted -- no audits to run"
  exit 0
end

# --- every audit must account for itself -------------------------------------------------------

files = Dir[File.join(ROOT, "bin/design/*.{js,rb,py}")].sort
undeclared = []
audits = {}

files.each do |file|
  name = File.basename(file)
  next if NOT_AN_AUDIT.key?(name)

  tokens = declaration_for(file)
  if tokens.nil?
    undeclared << name
    next
  end
  audits[name] = expand(tokens, name)
end

unless undeclared.empty?
  warn "#{undeclared.size} file(s) in bin/design declare no AUDIT-READS and are not listed as " \
       "NOT_AN_AUDIT:"
  undeclared.each { |n| warn "    #{n}" }
  warn ""
  warn "Add `AUDIT-READS: <bundles or globs>` near the top, or name it in NOT_AN_AUDIT with a"
  warn "reason. This check is the only thing between a new audit and being quietly left out of"
  warn "every future selection."
  exit 2
end

# --- select ------------------------------------------------------------------------------------

selected = {}
audits.each do |name, patterns|
  hits = changed.select { |path| matches?(patterns, path) }
  selected[name] = hits unless hits.empty?
end

puts "#{changed.size} changed file(s); #{audits.size} audit(s) considered, " \
     "#{NOT_AN_AUDIT.size} file(s) excused as not audits"
puts

if selected.empty?
  puts "None of them read anything that changed."
  exit 0
end

puts "Run these #{selected.size}:"
selected.sort_by { |name, hits| [-hits.size, name] }.each do |name, hits|
  runner = if name.end_with?(".js")
    "pw"
  elsif name.end_with?(".py")
    "python3"
  else
    "ruby"
  end
  puts format("  %-34s matched %d: %s", "#{runner} bin/design/#{name}", hits.size, hits.first(3).join(", "))
end

quiet = audits.keys - selected.keys
unless quiet.empty?
  puts
  puts "Not selected (#{quiet.size}), nothing they read changed:"
  puts "  #{quiet.sort.join(", ")}"
end

# One line to paste, because a list of thirty commands is a list nobody runs one at a time -- and
# "it was too much effort to run them" is indistinguishable in the end from "I forgot".
puts
puts "All of them, sequentially, output per audit in /tmp:"
puts
puts "  for a in #{selected.keys.sort.join(" ")}; do \\"
puts "    case $a in *.js) r=pw;; *.py) r=python3;; *) r=ruby;; esac; \\"
puts "    echo \"== $a\"; $r bin/design/$a > /tmp/aud-$a.txt 2>&1; tail -4 /tmp/aud-$a.txt; done"

# **Expect this to say "most of them" for anything on the render path, and do not treat that as the
# tool being unhelpful.** A browser audit renders real pages, so a changed view or Stimulus
# controller can move any of them, and that is the honest answer. It is also precisely the answer
# intuition does not give: asked the same question by hand about a change to one view and one
# controller, I picked six and the truthful number was twenty-eight.
exit 1
