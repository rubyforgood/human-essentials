#!/usr/bin/env ruby
# A ratchet on the audit suite's one seam to the application.
#
#     ruby bin/design/seam-check.rb
#
# `bin/design/targets.js` exists so that no other audit has to know what framework this app is: it
# owns the screen list, the roles, `signIn` and `visit`. Introducing it was the easy tenth of the
# work. **Fifteen audits still carry their own `signIn`**, at least two of them byte-identical, and
# the change log row that announced the seam claimed it was "replacing 21 hand-copied `signIn`
# functions" when it had converted one. A seam nobody adopts is a ninth way of doing something with
# none removed.
#
# Migrating the remaining fifteen is mechanical, touches every audit, and wants its own commit. This
# is the cheap thing that can be done first: **the number can go down and not up.** It is a ratchet,
# not a fix, and it is honest about that.
#
# Why the private copies matter, from faults this project actually had:
#
#   * one did not sign out first, so a second role silently audited the first role's pages
#   * one waited on `networkidle`, which never settles on three form pages here
#   * one used a bare `button[type=submit]`, which matches the sign-out button inside the closed
#     account menu and waits 30 seconds for it to become visible
#
# Each was fixed once, in the seam. A copy is a place for it to come back.
require "pathname"

DESIGN = Pathname.new(__dir__)
SEAM = "targets.js".freeze

# Lower this when you migrate one. Never raise it.
#
# **Zero, as of 2026-09-04.** All fifteen were migrated in one pass, each verified against output
# captured before the change: thirteen byte-identical, and the fourteenth -- `responsive-audit` --
# differing only because it is non-deterministic on its own, which the comparison is what caught.
# The ratchet stays: at zero it is the thing that keeps a new audit from copying `signIn` again.
BASELINE = 0

private_sign_ins = DESIGN.glob("*.js")
  .reject { |f| f.basename.to_s == SEAM }
  # `\b`, or the pattern matches `signInAsAdmin` and `signIn_MIGRATED` too -- which it did, and
  # the control that migrates one by renaming it passed silently as a result.
  .select { |f| f.read.match?(/async function signIn\b/) }
  .map { |f| f.basename.to_s }
  .sort

count = private_sign_ins.size
puts "audits with their own signIn: #{count} (baseline #{BASELINE})"
private_sign_ins.each { |f| puts "    #{f}" }

if count > BASELINE
  added = count - BASELINE
  puts
  puts "#{added} more than the baseline. A new audit should import the seam:"
  puts
  puts "    const T = require(\"./targets\");"
  puts "    for (const [email, wants] of T.RUNS) {"
  puts "      await T.signIn(page, email);"
  puts "      for (const t of T.targets().filter((x) => wants(x.path))) await T.visit(page, t.path);"
  puts "    }"
  puts
  puts "If the copy is genuinely necessary, say why in a comment and raise BASELINE in this file --"
  puts "deliberately, in a commit someone can read."
  exit 1
end

if count < BASELINE
  puts
  puts "#{BASELINE - count} fewer than the baseline. Lower BASELINE in #{__FILE__} to #{count},"
  puts "so the ratchet holds at the new number."
  exit 1
end

puts "no new copies"
