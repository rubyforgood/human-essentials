# Code that exists and cannot run: actions no route reaches, templates nothing renders, helpers
# nothing calls, files nothing links to.
#
#   bin/rails runner bin/design/dead-code.rb
#
# The companion to dead-routes.rb, which asks the opposite question -- routes with no code behind
# them. This asks for code with no route, no render and no caller in front of it.
#
# EVERY CHECK HERE WAS WRONG ON ITS FIRST RUN, and the wrongness always looked like findings.
# The exemptions below are not tidying; each is a class of false positive that was reported,
# investigated and disproved. Read them before adding a check, and add yours the same way.
#
#   * `\b` after a name ending in ? or ! never matches. `foo?(x)` has no word boundary between
#     the ? and the (, so the first helper pass called every predicate in the app dead: 12 of 33.
#   * A method called as `item.active?` is a receiver method, not a helper. Reflection --
#     instance_methods(false) -- knows the difference; scanning `def` lines does not.
#   * `render partial: "partners/profiles/show/#{x}"` names a directory, not a file. Nothing
#     static can say which of its partials are used; reporting them was 24 of the first 46.
#   * Code inside `module Partners` calls `UpdateFamily`, not `Partners::UpdateFamily`.
#   * clock.rb and Rakefile live at the repo root. A glob that starts at app/ reports the three
#     jobs Clockwork schedules as dead.
#   * public/site.webmanifest is the only thing naming the android-chrome icons, and a
#     <script type="module"> in _essentials_head is the only thing importing sinon.
#   * fullcalendar 6 is built on preact and imports it, luxon, and @fullcalendar/core/ itself.
#     Those pins are load-bearing and no static read of our own code can see it.
#   * The design system's own fonts -- Figtree and Bootstrap Icons -- are named only by @font-face
#     in the stylesheet. Drop .css from the glob and the audit recommends deleting the fonts
#     every page depends on.

Rails.application.routes.routes
Rails.application.eager_load!

# app/assets/builds is Tailwind's compiled output -- 165KB of generated CSS that would match
# almost any short string by accident. Read the sources it is built from instead.
SRC = (Dir.glob("{app,lib,config,spec}/**/*.{rb,erb,js,css,jbuilder,rake,yml}") +
       Dir.glob("*.rb") + ["Rakefile"])
  .reject { |f| f.start_with?("app/assets/builds/") }
  .select { |f| File.file?(f) }.to_h { |f| [f, File.read(f)] }

findings = Hash.new { |h, k| h[k] = [] }

# Exclude `Foo::Bar` but not `:a_symbol`. An earlier version put a single `:` in the lookbehind
# and so could not see `before_action :require_admin` -- which is how a method with a
# before_action three lines above its own definition was reported as uncalled.
def pattern_for(name)
  tail = name.end_with?("?", "!") ? "" : '(?![\w?!])'
  /(?<![\w.])(?<!::)#{Regexp.escape(name)}#{tail}/
end

def used_anywhere?(name, except: nil)
  pat = pattern_for(name)
  SRC.any? { |f, src| f != except && src.match?(pat) }
end

# --- 1. Controllers and actions no route reaches ----------------------------------------------
routed = Hash.new { |h, k| h[k] = Set.new }
Rails.application.routes.routes.each do |r|
  c, a = r.defaults[:controller], r.defaults[:action]
  routed[c] << a if c && a
end

# A class whose subclasses are routed is a base class, not dead code: HistoricalTrends::Base
# declares the shared action and each subclass gets the route.
routed_paths = routed.keys.compact.to_set
base_classes = ApplicationController.descendants.select { |k|
  k.descendants.any? { |d| routed_paths.include?(d.controller_path) }
}.to_set

ApplicationController.descendants.each do |klass|
  next if klass.abstract? || base_classes.include?(klass)
  # Defined by a gem rather than by us -- DeviseController and its subclasses serve the auth
  # routes and are not this app's to delete.
  source = begin
    Object.const_source_location(klass.name)&.first
  rescue
    nil
  end
  next unless source&.start_with?(Rails.root.to_s)
  name = klass.controller_path
  own = klass.action_methods.select { |m| klass.instance_method(m).owner == klass }
  if routed[name].empty?
    # No route at all reaches this class, whether or not it defines anything of its own.
    findings["controllers no route reaches"] << "#{klass}   (#{own.any? ? own.sort.join(", ") : "empty subclass"})"
  else
    own_src = SRC["app/controllers/#{name}_controller.rb"].to_s
    (own - routed[name].to_a).sort.each do |action|
      # A public method that is not an action -- a params builder, a before_action, a
      # helper_method -- is a visibility smell, not dead code. Ask the controller itself, not
      # the whole app: "is `index` used anywhere?" is true in every codebase ever written, and
      # asking it that way suppressed both real findings.
      next if klass._helper_methods.map(&:to_s).include?(action)
      next if own_src.each_line.any? { |l|
        l.match?(pattern_for(action)) && !l.match?(/^\s*def\s+#{Regexp.escape(action)}/)
      }
      findings["actions no route reaches"] << "#{name}##{action}"
    end
  end
end

# --- 2. Templates and partials ------------------------------------------------------------------
DEVISE_SCOPED = Devise.scoped_views ? %w[sessions passwords registrations invitations confirmations unlocks] : []
GEM_OWNED = %w[kaminari/ active_storage/ action_text/ layouts/action_text/].freeze

Dir.glob("app/views/**/*").select { |f| File.file?(f) }.each do |v|
  rel = v.sub("app/views/", "")
  dir = File.dirname(rel)
  base = File.basename(v)
  next if base.start_with?("_")
  next if dir.start_with?("layouts", "errors", "kaminari", "active_storage")
  next if dir.include?("mailer") || dir.end_with?("_mailer")
  next if dir.start_with?("users/") && DEVISE_SCOPED.include?(dir.split("/").last)
  name = base.sub(/\..*\z/, "")

  klass = "#{dir.camelize}Controller".safe_constantize
  next if klass&.action_methods&.include?(name)
  next if routed[dir].include?(name)
  next if SRC.any? { |f, src| f != v && src.include?("#{dir}/#{name}") }
  next if SRC["app/controllers/#{dir}_controller.rb"].to_s.match?(/render[ (]+[:"']#{Regexp.escape(name)}\b/)
  findings["templates nothing renders"] << rel
end

interpolated = SRC.values.flat_map { |src| src.scan(%r{["'](?:partial:\s*)?([\w/]+)/\#\{}) }.flatten.to_set
partials = Dir.glob("app/views/**/_*").select { |f| File.file?(f) }
  .reject { |p| GEM_OWNED.any? { |g| p.sub("app/views/", "").start_with?(g) } }
unresolvable, partials = partials.partition { |p| interpolated.include?(File.dirname(p.sub("app/views/", ""))) }
partials.each do |p|
  rel = p.sub("app/views/", "")
  dir = File.dirname(rel)
  stem = File.basename(p).sub(/\A_/, "").sub(/\..*\z/, "")
  used = SRC.any? { |f, src|
    next false if f == p
    src.include?("#{dir}/#{stem}") ||
      src.match?(/render[^\n]*["':]#{Regexp.escape(stem)}["'\s,)]/) ||
      src.match?(/render[( ]+@?\w*#{Regexp.escape(stem)}\b/)
  }
  findings["partials nothing renders"] << rel unless used
end

# --- 3. Helper methods -----------------------------------------------------------------------------
Dir.glob("app/helpers/**/*.rb").sort.each do |f|
  mod = f.sub("app/helpers/", "").sub(/\.rb\z/, "").camelize.safe_constantize
  next unless mod.is_a?(Module)
  mod.instance_methods(false).sort.each do |m|
    pat = pattern_for(m.to_s)
    used = SRC.any? { |_g, src|
      src.each_line.any? { |line| line.match?(pat) && !line.match?(/^\s*def\s+#{Regexp.escape(m.to_s)}/) }
    }
    findings["helper methods nothing calls"] << "#{m}   (#{f.sub("app/helpers/", "")})" unless used
  end
end

# --- 4. Ruby objects --------------------------------------------------------------------------------
{
  "services" => "app/services/**/*.rb", "queries" => "app/queries/**/*.rb",
  "jobs" => "app/jobs/**/*.rb", "mailers" => "app/mailers/**/*.rb",
  "events" => "app/events/**/*.rb", "concerns" => "app/**/concerns/**/*.rb"
}.each do |label, glob|
  Dir.glob(glob).sort.each do |f|
    const = f.sub(%r{\Aapp/\w+/}, "").sub(/\.rb\z/, "").camelize
    next unless Object.const_defined?(const)
    short = const.split("::").last
    used = SRC.any? { |g, src|
      next false if g == f || g.start_with?("spec/")
      src.match?(/\b#{Regexp.escape(const)}\b/) || src.match?(/(?<!::)\b#{Regexp.escape(short)}\b/)
    }
    findings["#{label} nothing references"] << const unless used
  rescue NameError
    next
  end
end

# --- 5. JavaScript ------------------------------------------------------------------------------------
Dir.glob("app/javascript/controllers/*_controller.js").sort.each do |f|
  id = File.basename(f).sub("_controller.js", "").tr("_", "-")
  used = SRC.any? { |g, src|
    next false if g == f
    # Both spellings: data-controller="x" in HTML, and "data-controller": "x" or
    # data: {controller: "x"} in a Ruby options hash.
    src.match?(/data-controller["']?[=:]\s*["'][^"']*\b#{Regexp.escape(id)}\b/) ||
      src.match?(/controller:\s*["'][^"']*\b#{Regexp.escape(id)}\b/) ||
      src.match?(/#{Regexp.escape(id)}#/) ||
      src.match?(/#{Regexp.escape(id.tr("-", "_"))}_target/) ||
      src.match?(/#{Regexp.escape(id)}-target/)
  }
  findings["Stimulus controllers nothing mounts"] << id unless used
end

# preact and luxon are fullcalendar's own imports and @fullcalendar/core/ is the subpath pin its
# modules resolve against. Nothing in our code names them; all four are load-bearing.
TRANSITIVE_PINS = %w[preact preact/compat preact/hooks luxon @fullcalendar/core/].freeze
File.read("config/importmap.rb").scan(/^\s*pin\s+["']([^"']+)["']/).flatten.each do |pin|
  next if pin == "application" || pin.start_with?("controllers") || TRANSITIVE_PINS.include?(pin)
  next if SRC.any? { |_f, src| src.match?(/(from|import)[\s(]+["']#{Regexp.escape(pin)}["']/) }
  findings["importmap pins nothing imports"] << pin
end

# --- 6. public/ ------------------------------------------------------------------------------------------
PUB_SRC = SRC.merge(Dir.glob("public/*.{json,xml,webmanifest,html,txt}").to_h { |f| [f, File.read(f)] })
SERVED_BY_RAILS = %w[404.html 422.html 500.html 403.html robots.txt favicon.ico].freeze
Dir.glob("public/**/*").select { |f| File.file?(f) }.each do |f|
  next if f.start_with?("public/assets/", "public/packs")
  next if SERVED_BY_RAILS.include?(File.basename(f))
  next if system("git check-ignore -q #{f}")  # local scratch: design previews and the like
  base = File.basename(f)
  next if PUB_SRC.any? { |_g, s| s.include?(base) || s.include?(f.sub("public", "")) }
  findings["public/ files nothing references"] << f.sub("public/", "")
end

# --- report ------------------------------------------------------------------------------------------------
total = findings.values.sum(&:size)
puts "#{total} finding(s)"
findings.each do |label, items|
  next if items.empty?
  puts "\n== #{label} (#{items.size})"
  items.sort.each { |i| puts "  #{i}" }
end
puts "\n(#{unresolvable.size} partials sit in directories named by an interpolated render, so nothing static can judge them)"
exit(1) if total.positive?
