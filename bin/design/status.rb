# Reports which controllers render on the design system and which still render on AdminLTE.
# Resolves inheritance: a controller with no `layout` of its own uses its parent's.
sources = {}
Dir.glob("app/controllers/**/*_controller.rb").each do |f|
  src = File.read(f)
  next unless (m = src.match(/class\s+([A-Za-z:]+Controller)\s*<\s*([A-Za-z:]+)/))
  sources[m[1]] = {parent: m[2], layout: src[/layout\s+["':]([\w\/]+)/, 1], name: f.sub("app/controllers/", "").sub("_controller.rb", "")}
end

def layout_for(name, sources, seen = [])
  entry = sources[name]
  return nil if entry.nil? || seen.include?(name)
  return entry[:layout] if entry[:layout]
  # Devise subclasses get their layout from config/application.rb.
  return "essentials_auth" if entry[:parent].start_with?("Devise::")
  layout_for(entry[:parent], sources, seen + [name])
end

migrated, legacy = [], []
sources.each do |klass, entry|
  next if entry[:name] == "application"
  layout = layout_for(klass, sources)
  (layout.to_s.start_with?("essentials_") ? migrated : legacy) << entry[:name]
end

# **Two questions, and only the first one has a reliable answer.**
#
# "Does this view carry design system markup?" was the question here, and it was wrong six times
# out of six. Every file it named as unmigrated was migrated: three were bare `f.input` -- the
# *finished* state, because `config.default_wrapper = :essentials` means the wrapper supplies
# every class -- and the other three carried a data-table cell class, a Stimulus controller, or a
# helper call whose argument was a variable rather than a symbol.
#
# The pattern had already been widened once, for 51 pages. Widening it again recovered 17 more, and
# then three more, and the last three would have needed a fourth pass. **That is the shape of a
# check that cannot be finished**: the design system's vocabulary grows with every component, so a
# positive-marker test is always one component behind, and every miss reports finished work as
# outstanding.
#
# So the primary measure is inverted. **The legacy vocabulary is closed** -- Bootstrap and AdminLTE
# were deleted by ADR 0011 and cannot gain new words -- so "does this view still use the old
# system?" is a question with a stable answer, and it is the question "is the migration done?"
# actually means. `docs/migration-map.md` enumerates the vocabulary; this is that list.
LEGACY = Regexp.union(
  %r{class="[^"]*\bbtn\b}, %r{class="[^"]*\bbtn-},
  # `card-surface` is *ours*, and `\bcard\b` matched the "card" in it -- the boundary sits before
  # the hyphen -- so three migrated pages were reported as legacy. Bootstrap's suffixes are
  # enumerated and anything else after `card-` is not Bootstrap's.
  %r{class="[^"]*\bcard(?:-(?:body|header|footer|title|text|deck|columns|img(?:-top|-bottom)?))?(?![-\w])},
  %r{class="[^"]*\bform-(group|control|inline|horizontal)\b},
  %r{class="[^"]*\bcontrol-label\b},
  %r{class="[^"]*\bcol-(xs|sm|md|lg)-\d},
  %r{class="[^"]*\bfa[srb]?\b}, %r{class="[^"]*\bfa-},
  %r{class="[^"]*\btable-(striped|bordered|hover)\b},
  %r{class="[^"]*\bd-(none|block|flex|inline)},
  %r{class="[^"]*\blabel label-}, %r{class="[^"]*\bbadge badge-},
  %r{class="[^"]*\binput-group-text\b},
  %r{class="[^"]*\bcallout callout-},
  %r{class="[^"]*\bhelp-block\b},
  %r{data-bs-}, %r{data-widget=},
  %r{fa_icon\s}
)

# Kept as a coverage indicator, not as a verdict -- see above for why it cannot be one. A view with
# no positive marker is not necessarily unmigrated; a four-line table row may have nothing to mark.
DESIGN_SYSTEM = Regexp.union(
  %r{rounded-2xl|data-table|text-slate-|bg-brand-|essentials_|shared/essentials/},
  %r{px-4 py-6}, %r{Essentials\w*Helper}, %r{link-brand},
  %r{cell-actions|class="quantity"|class="notes"|class="percent"|pin-col|chart-box},
  %r{data-controller="}, %r{\b\w+\.(input|input_field|association)\s}
)

# Mailers are HTML email -- table layouts and inline styles, deliberately not the design system.
# static/ renders with `layout false` and its own stylesheet (see docs/migration-map.md).
EXEMPT = %r{app/views/\w*mailer\w*/|app/views/layouts/mailer|app/views/users/mailer/|app/views/static/}

# Gem and framework partials, and the components themselves, which cannot carry a marker for the
# system they *are*. Named rather than silently dropped: an unexplained exclusion reads the same as
# an oversight.
STRUCTURAL = %r{app/views/kaminari/|app/views/active_storage/|app/views/layouts/action_text/|app/views/shared/essentials/}

all = Dir.glob("app/views/**/*.html.erb").reject { |v| v.match?(EXEMPT) }
structural, views = all.partition { |v| v.match?(STRUCTURAL) }

legacy_views = views.select { |v| File.read(v).match?(LEGACY) }
marked = views.count { |v| File.read(v).match?(DESIGN_SYSTEM) }

puts "controllers on design system: #{migrated.size} / #{migrated.size + legacy.size}"
puts "views still using the old system: #{legacy_views.size} of #{views.size}"
puts "views carrying a positive marker: #{marked} of #{views.size} (indicator only -- a small"
puts "  partial can be fully migrated and have nothing to mark)"
puts "  #{structural.size} more are structural: gem, framework, or the components themselves"
puts
puts "REMAINING CONTROLLERS (#{legacy.size}):"
legacy.sort.each_slice(4) { |s| puts "  " + s.join(", ") }
puts
if legacy_views.empty?
  puts "No view carries Bootstrap or AdminLTE markup."
else
  puts "VIEWS STILL ON THE OLD SYSTEM (#{legacy_views.size}):"
  legacy_views.sort.each { |v| puts "  #{v.sub("app/views/", "")}" }
end
