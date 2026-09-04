# Every GET route that renders an HTML screen, with a real record id substituted for :id.
#
# The companion to route-sweep.js. It exists because bin/design/sweep.js walks a hardcoded list
# of 56 paths, and a list goes stale silently: the three historical trend pages were added to
# the nav, never added to the list, and sat unmigrated with no <h1> for the length of the
# migration without either audit noticing.
require "json"

org = Organization.first
partner = org&.partners&.first

# One real record per controller, so :id resolves to something that exists.
IDS = {
  "items" => org&.items&.first, "kits" => org&.kits&.first,
  "donations" => org&.donations&.first, "purchases" => org&.purchases&.first,
  "distributions" => org&.distributions&.first, "requests" => org&.requests&.first,
  "transfers" => org&.transfers&.first, "audits" => org&.audits&.first,
  "adjustments" => org&.adjustments&.first, "vendors" => org&.vendors&.first,
  "partners" => partner, "storage_locations" => org&.storage_locations&.first,
  "donation_sites" => org&.donation_sites&.first, "manufacturers" => Manufacturer.first,
  "product_drives" => org&.product_drives&.first,
  "product_drive_participants" => org&.product_drive_participants&.first,
  "item_categories" => org&.item_categories&.first,
  "barcode_items" => org&.barcode_items&.first,
  "broadcast_announcements" => BroadcastAnnouncement.first,
  "partner_groups" => org&.partner_groups&.first,
  "users" => org&.users&.first, "partner_users" => partner&.users&.first,
  "admin/organizations" => org, "admin/users" => User.first,
  "admin/partners" => Partner.first, "admin/base_items" => BaseItem.first,
  "admin/barcode_items" => BarcodeItem.first,
  "admin/broadcast_announcements" => BroadcastAnnouncement.first,
  "admin/questions" => Question.first, "admin/account_requests" => AccountRequest.first,
  "admin/ndbn_members" => NDBNMember.first,
  "partners/children" => Partners::Child.first, "partners/families" => Partners::Family.first,
  "partners/requests" => partner&.requests&.first,
  "partners/distributions" => org&.distributions&.first,
  "events" => Event.where(organization_id: org&.id).first
}.compact.transform_values(&:id)

# Not screens: file downloads, exports, PDFs, one-shot state changes, and Devise's plumbing.
#
# **Matched on the action name alone, so it has to be a name no screen anywhere uses.** `inventory`
# was on this list to skip `storage_locations#inventory`, which is a partial -- and it took
# `items#inventory` with it, which is a full screen with an `<h1>`, a shell, and a place in the item
# catalogue's tab strip. Every audit built on this file was therefore blind to it, which is the same
# fault as a hardcoded page list wearing a different hat. Anything controller-specific goes in
# SKIP_PAIR below.
SKIP_ACTION = /\A(destroy|deactivate|reactivate|restore|print|print_picklist|print_unfulfilled|
                  export|download|upload_csv|csv|pdf|font|calendar|schedule_ics|resource_ids|
                  switch_to_role|passthru|failure|cancel|itemized_breakdown|find)\z/x

# Not screens, and named by controller because the action name is used elsewhere for one that is.
SKIP_PAIR = %w[storage_locations#inventory].freeze
SKIP_PATH = %r{\.csv|\.pdf|/print|active_storage|attachments|action_mailbox|
               /users/(sign_in|sign_up|password|confirmation|unlock|auth)}x

targets, seen = [], {}
Rails.application.routes.routes.each do |r|
  next unless r.verb.to_s.include?("GET")
  controller, action = r.defaults[:controller], r.defaults[:action]
  # Not "devise/": those routes ARE the auth screens. The app has a users/invitations_controller
  # and a users/passwords_controller, so the list looked covered -- but devise_for overrides only
  # sessions and omniauth_callbacks, and Devise's own controllers serve the rest. Skipping them
  # meant the sweep never visited the invitation pages, which rendered with no layout at all.
  next if controller.nil? || controller.start_with?("rails/", "turbo/", "active_storage/")
  next if action.to_s.match?(SKIP_ACTION)
  next if SKIP_PAIR.include?("#{controller}##{action}")

  path = r.path.spec.to_s.sub("(.:format)", "")
  next if path.include?("*") || path.match?(SKIP_PATH)

  # **A named segment resolves against the model it names, not against the controller.**
  # `/partners/:partner_id/users` belongs to `partner_users`, so `IDS[controller]` is a *user*
  # id -- and the old `gsub(/:[a-z_]*id/, id)` put it in the `:partner_id` slot, producing
  # `/partners/10/users`. There is no partner 10, so it 404'd, and every browser audit reported it
  # as "not reached" and moved on. That screen -- the partner's user table -- was invisible to all
  # of them, which is how it kept a status column drawn differently from the bank's and three
  # inline row buttons in two weights while `table-audit.js` reported the app clean.
  #
  # `:partner_id` -> `IDS["partners"]`, `:id` -> the controller's own record. Skipped entirely when
  # either is missing, because a guessed id is a 404 wearing a screen's name.
  if path.include?(":")
    resolved = true
    path = path.gsub(/:([a-z_]+)_id/) do
      parent = IDS[Regexp.last_match(1).pluralize]
      resolved &&= !parent.nil?
      parent.to_s
    end
    if path.include?(":id")
      own = IDS[controller]
      resolved &&= !own.nil?
      path = path.sub(":id", own.to_s)
    end
    next unless resolved
    next if path.include?(":")
  end
  next if seen[path]
  seen[path] = true
  targets << {path: path, controller: controller, action: action}
end

puts JSON.generate(targets)
