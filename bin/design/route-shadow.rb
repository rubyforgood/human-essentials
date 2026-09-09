#!/usr/bin/env ruby
# AUDIT-READS: ROUTES, public/
#
# Files in `public/` that shadow a route.
#
# Rails serves static files from `public/` *before* the router sees the request, so
# `public/vendors.csv` answers `GET /vendors.csv` and the controller never runs. Nothing warns
# about it: the response is a 200 with plausible-looking content.
#
# This exists because of a specific afternoon. A request spec for a CSV export failed with three
# unfiltered rows and the wrong headers, while the controller, the view model, the concern, the
# model, the factory and the spec were all byte-identical to before the change being investigated.
# The cause was `public/product_drive_participants.csv` -- untracked debris left behind by a
# workspace rollback, shadowing `/product_drive_participants.csv`. It cost an hour, and the whole
# time it looked like damage from the merge in progress.
#
# `bin/workspace-restore` removes files a commit deleted and deliberately leaves untracked files
# alone, which is the right call -- it cannot know which of them you meant to keep. This is the
# check that makes the consequence visible.
#
#     bin/rails runner bin/design/route-shadow.rb
#
# Exit codes: 0 nothing shadows a route, 1 something does.

# `(.:format)` is stripped so `/vendors(.:format)` matches a file called `vendors.csv`: the
# extension is what makes the static file win, and the route is the same route either way.
ROUTE_PATHS = Rails.application.routes.routes
  .map { |r| r.path.spec.to_s.sub("(.:format)", "") }
  .to_set

# Extensions a browser will ask for at a path the app also answers. A `.png` or a `.js` is not in
# this list because nothing here routes those, and listing everything would report the favicon.
SERVED = %w[csv html json pdf xml txt].freeze

shadows = []
checked = 0

Rails.public_path.glob("*").sort.each do |path|
  next if File.directory?(path)

  name = File.basename(path)
  ext = File.extname(name).delete_prefix(".")
  next unless SERVED.include?(ext)

  checked += 1
  stem = "/#{File.basename(name, ".#{ext}")}"
  next unless ROUTE_PATHS.include?(stem)

  tracked = system("git -C #{Rails.root} ls-files --error-unmatch #{path} > /dev/null 2>&1")
  shadows << {file: "public/#{name}", route: stem, tracked: tracked}
end

# The count is printed either way. A check that examined nothing reports no findings, which reads
# exactly like a check that examined everything and found nothing.
puts "#{checked} file(s) in public/ could answer a route; #{ROUTE_PATHS.size} route paths"
puts

if shadows.empty?
  puts "Nothing in public/ shadows a route."
  exit 0
end

puts "#{shadows.size} file(s) shadow a route -- Rails serves these instead of the controller:"
shadows.each do |s|
  origin = s[:tracked] ? "tracked, so somebody added it on purpose" : "UNTRACKED -- likely debris"
  puts format("  %-46s shadows %-28s (%s)", s[:file], s[:route], origin)
end
puts
puts "An untracked one is usually rollback or scratch debris and can be deleted. A tracked one is"
puts "a decision somebody made: either the route is dead, or the file should be named differently"
puts "-- the import templates here all end in `_template.csv` for exactly this reason."
exit 1
