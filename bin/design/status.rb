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

views = Dir.glob("app/views/**/*.html.erb")
tw = views.count { |v| File.read(v).match?(/rounded-2xl|data-table|text-slate-|bg-brand-|essentials_/) }
puts "controllers on design system: #{migrated.size} / #{migrated.size + legacy.size}"
puts "views with design-system markup: #{tw} / #{views.size}"
puts
puts "REMAINING (#{legacy.size}):"
legacy.sort.each_slice(4) { |s| puts "  " + s.join(", ") }
