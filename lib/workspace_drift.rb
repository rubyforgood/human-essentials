# What a rolled-back working tree looks like, so `bin/workspace-check` and `bin/workspace-restore`
# agree on it rather than each having their own idea.
#
# The distinction that matters, and that the first cut of these scripts got wrong: **untracked is
# not resurrected.** A file HEAD does not have is either
#
#   - work in progress, which has never been committed and must not be deleted, or
#   - a file some commit *deleted*, which something has put back -- and which a plain
#     `git checkout .` will not remove, so the app goes on rendering it.
#
# Git can tell them apart: the second has history on its path and the first does not.
require "shellwords"
require "open3"
require "tmpdir"

module WorkspaceDrift
  module_function

  def git(*args) = Open3.capture2("git", *args).first

  def head = git("rev-parse", "--short=9", "HEAD").strip

  def head_subject = git("log", "-1", "--format=%s").strip

  # Tracked files that differ from HEAD.
  def changed
    git("status", "--porcelain").lines.map(&:chomp).reject { |l| l.start_with?("??") }
  end

  # `-uall` so an untracked *directory* is listed as its files rather than as "dir/", which is what
  # made the first version offer to delete `.githooks/` whole.
  def untracked
    git("status", "--porcelain", "-uall").lines.map(&:chomp)
      .select { |l| l.start_with?("??") }.map { |l| l[3..] }
  end

  # Present on disk, absent from HEAD, and known to have existed: a commit removed it and something
  # brought it back.
  def resurrected
    untracked.select { |path| git("log", "--oneline", "-1", "--", path).strip != "" }
  end

  # Present on disk and in no commit at all: somebody's work.
  def new_work
    untracked - resurrected
  end

  # How many tracked files on disk differ from a given commit.
  def drift_from(ref) = git("diff", "--name-only", ref).lines.size

  # Which commit the files on disk look most like, and by how much.
  #
  # Not an *exact* tree match, which was the first version and answered "looks like work in
  # progress" on the one occasion it mattered: one stray untracked file defeats equality, and there
  # is always one. Closeness is the signal -- after the last rollback the tree was **6 files** from
  # its target and **412** from HEAD, which is not a judgement call.
  #
  # Opt-in, because it costs a `git diff` per commit -- 0.12s each, and the last rollback landed 215
  # commits back, so a default that scanned would take half a minute to tell you something the drift
  # count already told you.
  def closest_ancestor(limit: 400)
    git("rev-list", "--max-count=#{limit}", "HEAD").lines.map(&:chomp)
      .map { |commit| [commit, drift_from(commit)] }.min_by(&:last)
  end

  # A rollback rather than an edit. Magnitude alone is enough and needs no scan: nobody hand-edits
  # fifty files without noticing, and a file that a commit deleted does not come back on its own.
  def rollback?(changed_count = changed.size, back_count = resurrected.size)
    changed_count >= 50 || back_count.positive?
  end
end
