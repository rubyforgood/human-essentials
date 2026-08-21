# Routes that cannot work: the controller or the action behind them does not exist, or an
# earlier declaration shadows them so they never run.
#
#   bin/rails runner bin/design/dead-routes.rb
#
# Two things make this harder than reading each route's controller and action out of its own
# defaults, and the first version of this script got both wrong:
#
#  1. Another route can handle the request. POST /users looks dead -- UsersController has no
#     create -- but Devise's registration route is declared first and answers it. Only
#     recognize_path knows which route wins, so that is what decides.
#  2. recognize_path runs outside a request, so a route behind a constraint that needs one
#     raises RoutingError. That is not evidence of anything: /partners/donations raised here
#     while being perfectly reachable in a browser, and skipping it hid a dead route for the
#     length of the migration. Fall back to the declared target instead of skipping.
#
# Shadowing is reported separately because it is a different defect with the same symptom.
# /requests/partner_requests was declared and resolved to requests#show with an id of
# "partner_requests", because a second `resources :requests` declared a collection route
# underneath the first one's /requests/:id.
#
# The shadow check is best-effort: paths are deduplicated by verb and path, so when two routes
# claim the same one only the first is examined -- which is the one that wins, so nothing dead
# is missed, but the losing declaration is not named.
SKIP_CONTROLLERS = %w[rails/ turbo/ active_storage/ action_mailbox/ devise/].freeze

# nil when the route works, otherwise the reason it does not.
def why_dead(controller, action)
  return "no controller or action in the route" if controller.nil? || action.nil?
  begin
    klass = "#{controller.camelize}Controller".constantize
  rescue NameError
    return "no such controller"
  end
  return nil if klass.action_methods.include?(action)
  # An action with no method still works if there is a template to render implicitly.
  return nil if Rails.root.glob("app/views/#{controller}/#{action}.*").any?
  "no action, no template"
end

dead = []
shadowed = []
seen = Set.new
checked = 0

Rails.application.routes.routes.each do |route|
  declared_controller = route.defaults[:controller]
  declared_action = route.defaults[:action]
  next if declared_controller.nil? || declared_action.nil?
  next if declared_controller.start_with?(*SKIP_CONTROLLERS)

  spec = route.path.spec.to_s.sub("(.:format)", "")
  next if spec.include?("*")
  verb = route.verb.to_s.split("|").first
  next if verb.empty?

  probe = spec.gsub(/:[a-z_]+/, "1")
  next unless seen.add?([verb, probe])
  checked += 1

  begin
    hit = Rails.application.routes.recognize_path(probe, method: verb)
    controller, action = hit[:controller], hit[:action]
  rescue ActionController::RoutingError
    # Constraint-guarded: judge it on what it declares rather than dropping it.
    controller, action = declared_controller, declared_action
  end

  reason = why_dead(controller, action)
  if reason
    dead << [verb, spec, "#{controller}##{action}", reason]
  elsif controller != declared_controller || action != declared_action
    shadowed << [verb, spec, "#{declared_controller}##{declared_action}", "answered by #{controller}##{action}"]
  end
end

puts "#{checked} routes checked"
puts "\n#{dead.size} dead -- the request would raise"
dead.sort_by { |_, path, _, _| path }.each { |v, p, target, why| puts format("  %-7s %-46s %-42s %s", v, p, target, why) }
puts "\n#{shadowed.size} shadowed -- declared but another route answers first"
shadowed.sort_by { |_, path, _, _| path }.each { |v, p, target, why| puts format("  %-7s %-46s %-42s %s", v, p, target, why) }

exit(1) if dead.any?
