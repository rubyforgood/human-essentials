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
# Git can tell them apart: the second is byte-for-byte a version git once held at that path.
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

  # **A rollback does not care what `.gitignore` says.** It restores an old tree wholesale, and if
  # HEAD has since started ignoring one of those paths the file lands on disk *and never appears in
  # `git status`*. Not hypothetical: `public/product_drive_participants.csv` came back twice and
  # shadowed a route both times -- Rails serves `public/` before routing -- and the second time it
  # broke a CSV spec while these scripts reported the tree clean.
  #
  # Wholly-ignored directories are expanded, because `--ignored=matching` collapses them to `dir/`
  # and `public/assets/` is one: precompiled output that Rails serves in preference to any route.
  # Bounded, because `tmp/` holds 36,127 files here and not one of them changes what renders.
  DIR_BOUND = 500

  def ignored
    skipped_dirs.clear
    git("status", "--porcelain", "-uall", "--ignored=matching").lines.map(&:chomp)
      .select { |l| l.start_with?("!!") }.map { |l| l[3..] }
      .flat_map { |entry| expand_ignored(entry) }
  end

  def expand_ignored(entry)
    return [entry] if File.file?(entry)
    return [] unless File.directory?(entry)
    files = Dir.glob("#{entry}**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }
    return files if files.size <= DIR_BOUND
    skipped_dirs << [entry, files.size]
    []
  end

  def skipped_dirs = (@skipped_dirs ||= [])

  # Every path any commit ever touched, in one walk. This is what makes the rest cheap: of 212
  # candidates on disk, 4 are paths git has ever heard of.
  #
  # `--full-history`, and *not* `--diff-filter=D`. The obvious query -- "paths some commit deleted"
  # -- misses everything removed by a **merge**, whose deletions a log without `-m` never shows. It
  # found none of the three real cases here and only the false one, which is the whole result
  # inverted.
  def paths_ever_touched
    @paths_ever_touched ||= git("log", "--full-history", "--name-only", "--format=")
      .lines.map(&:chomp).reject(&:empty?).to_set
  end

  # Present on disk, absent from HEAD, and byte-for-byte a version git once held *at that path*.
  #
  # The content test, rather than "the path has history", is what makes widening to ignored files
  # safe. `spec/example_failures.txt` has history and a commit that deleted it, so the cheaper test
  # calls it resurrected -- but rspec rewrites it every run, and deleting a live artifact on the
  # word of the tool that exists to make the tree trustworthy is how that tool loses its nerve.
  # Matching bytes is also the licence to delete: it means git can give the file back.
  def resurrected
    @resurrected ||= begin
      candidates = (untracked + ignored).select { |path| paths_ever_touched.include?(path) }
      candidates.zip(hash_objects(candidates))
        .select { |path, sha| sha && !sha.empty? && held_at?(path, sha) }.map(&:first)
    end
  end

  # Sliced so a long list cannot overflow argv, and it falls back to one call per file when the line
  # count does not match -- an unreadable path would otherwise shift every hash after it onto the
  # wrong file.
  def hash_objects(paths)
    paths.each_slice(300).flat_map do |slice|
      out = git("hash-object", "--", *slice).lines.map(&:chomp)
      (out.size == slice.size) ? out : slice.map { |p| git("hash-object", "--", p).strip }
    end
  end

  # `--full-history` again, because the default simplification reported *no history at all* for
  # `public/product_drive_participants.csv`, whose blob is plainly there at 548db78f6. `--raw` hands
  # back the blob hashes directly, so this is one process per path and no walk in Ruby.
  def held_at?(path, sha)
    git("log", "--full-history", "--max-count=40", "--format=", "--raw", "--abbrev=40", "--", path)
      .scan(/^:\S+ \S+ (\h{40}) (\h{40})/).flatten.include?(sha)
  end

  # Present on disk and in no commit at all: somebody's work. Ignored files are left out -- they are
  # deletion candidates when they match history and nobody's work in progress otherwise, so listing
  # `.env` and six log files as "untracked work" would be noise.
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
