# Reports which controllers render on the design system and which still render on AdminLTE.
migrated = []
legacy = []
Dir.glob("app/controllers/**/*_controller.rb").each do |f|
  src = File.read(f)
  next if f.include?("application_controller") || src.include?("< ActionController::API")
  name = f.sub("app/controllers/", "").sub("_controller.rb", "")
  if src.match?(/layout\s+["']essentials_/)
    migrated << name
  else
    legacy << name
  end
end
views = Dir.glob("app/views/**/*.html.erb")
tw = views.count { |v| File.read(v).match?(/class="[^"]*\b(rounded-2xl|data-table|text-slate-|bg-brand-|essentials_)/) }
puts "controllers on design system: #{migrated.size} / #{migrated.size + legacy.size}"
puts "views with design-system markup: #{tw} / #{views.size}"
puts
puts "MIGRATED: #{migrated.sort.join(", ")}" if ARGV[0] == "-v"
puts
puts "REMAINING (#{legacy.size}):"
legacy.sort.each_slice(4) { |s| puts "  " + s.join(", ") }
