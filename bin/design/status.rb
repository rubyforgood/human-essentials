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

# A view counts as migrated if it carries design system markup OR renders a design system
# partial. The pattern used to be `essentials_` with an underscore, which matches the helpers
# but not `render "shared/essentials/page_header"` -- so a page built entirely out of the
# components, which is the ideal, was counted as unmigrated. That understated the total by 51
# pages, including every new/edit wrapper in the app.
DESIGN_SYSTEM = %r{rounded-2xl|data-table|text-slate-|bg-brand-|essentials_|shared/essentials/}

# Mailers are HTML email -- table layouts and inline styles, deliberately not the design system.
# static/ renders with `layout false` and its own stylesheet (see docs/migration-map.md).
EXEMPT = %r{app/views/\w*mailer\w*/|app/views/layouts/mailer|app/views/users/mailer/|app/views/static/}

views = Dir.glob("app/views/**/*.html.erb").reject { |v| v.match?(EXEMPT) }
tw = views.count { |v| File.read(v).match?(DESIGN_SYSTEM) }
puts "controllers on design system: #{migrated.size} / #{migrated.size + legacy.size}"
puts "views with design-system markup: #{tw} / #{views.size}"
puts
puts "REMAINING (#{legacy.size}):"
legacy.sort.each_slice(4) { |s| puts "  " + s.join(", ") }
