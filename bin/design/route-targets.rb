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
SKIP_ACTION = /\A(destroy|deactivate|reactivate|restore|print|print_picklist|print_unfulfilled|
                  export|download|upload_csv|csv|pdf|font|calendar|schedule_ics|resource_ids|
                  switch_to_role|passthru|failure|cancel|itemized_breakdown|inventory|find)\z/x
SKIP_PATH = %r{\.csv|\.pdf|/print|active_storage|attachments|action_mailbox|
               /users/(sign_in|sign_up|password|confirmation|unlock|auth)}x

targets, seen = [], {}
Rails.application.routes.routes.each do |r|
  next unless r.verb.to_s.include?("GET")
  controller, action = r.defaults[:controller], r.defaults[:action]
  next if controller.nil? || controller.start_with?("rails/", "turbo/", "active_storage/", "devise/")
  next if action.to_s.match?(SKIP_ACTION)

  path = r.path.spec.to_s.sub("(.:format)", "")
  next if path.include?("*") || path.match?(SKIP_PATH)

  if path.include?(":")
    id = IDS[controller] or next
    path = path.gsub(/:[a-z_]*id/, id.to_s)
    next if path.include?(":")
  end
  next if seen[path]
  seen[path] = true
  targets << {path: path, controller: controller, action: action}
end

puts JSON.generate(targets)
