# Navigation model for the Ruby for Good design system shell (layouts/essentials_app).
#
# The sidebar is data, not markup: each group is rendered by layouts/_essentials_nav_group
# and each item by layouts/_essentials_nav_link, so ordering, role gating and active-state
# logic live in one testable place instead of being spread across 300 lines of ERB.
#
# Ordering is by task frequency, not alphabetical. Dashboard is ungrouped and first;
# settings is pinned to the bottom. See design.md, "App shell".
module EssentialsNavHelper
  # `icon` is optional and belongs to the top level only -- a standalone rail item or a group
  # header. Items nested inside a group have none: icons on both levels give the eye two
  # columns of glyphs to scan, and stop marking anything out.
  NavItem = Data.define(:label, :path, :active_on, :icon) do
    def initialize(label:, path:, active_on:, icon: nil) = super

    def active?(controller_path)
      active_on.include?(controller_path)
    end
  end

  NavGroup = Data.define(:label, :icon, :items)

  # The single item above the groups.
  def essentials_nav_dashboard
    NavItem.new(label: "Dashboard", path: dashboard_path, active_on: %w[dashboard], icon: "bi-speedometer2")
  end

  # The reports hub. One rail entry for fifteen reports, which used to be a group holding as
  # many destinations as the other three groups combined.
  #
  # `active_on` lists every controller that renders a report, so the entry stays highlighted
  # while you are inside one -- otherwise the rail would say you are nowhere.
  def essentials_nav_reports
    NavItem.new(
      label: "Reports",
      path: reports_path,
      active_on: %w[reports reports/annual_reports distributions_by_county events
        historical_trends/distributions historical_trends/donations historical_trends/purchases],
      icon: "bi-graph-up"
    )
  end

  # The item pinned to the bottom of the rail, below its own divider.
  # Organization settings are admin-only, so org users get no pinned item at all.
  def essentials_nav_settings
    return nil unless can_administrate?

    NavItem.new(label: "My organization", path: organization_path, active_on: %w[organizations], icon: "bi-building")
  end

  # The middle of the rail. Groups with no visible items render nothing -- no orphan label.
  def essentials_nav_groups
    [
      NavGroup.new(
        label: "Operations",
        icon: "bi-box-seam",
        items: [
          NavItem.new(label: "Donations", path: donations_path, active_on: %w[donations]),
          NavItem.new(label: "Purchases", path: purchases_path, active_on: %w[purchases]),
          NavItem.new(label: "Requests", path: requests_path, active_on: %w[requests]),
          NavItem.new(label: "Distributions", path: distributions_path, active_on: %w[distributions]),
          NavItem.new(label: "Pick ups & deliveries", path: schedule_distributions_path, active_on: %w[distributions/schedule])
        ]
      ),
      NavGroup.new(
        label: "Inventory",
        icon: "bi-boxes",
        items: [
          NavItem.new(label: "Items & inventory", path: items_path, active_on: %w[items]),
          NavItem.new(label: "Kits", path: kits_path, active_on: %w[kits]),
          NavItem.new(label: "Storage locations", path: storage_locations_path, active_on: %w[storage_locations]),
          NavItem.new(label: "Transfers", path: transfers_path, active_on: %w[transfers]),
          NavItem.new(label: "Inventory adjustments", path: adjustments_path, active_on: %w[adjustments]),
          (NavItem.new(label: "Inventory audit", path: audits_path, active_on: %w[audits]) if can_administrate?),
          NavItem.new(label: "Barcode items", path: barcode_items_path, active_on: %w[barcode_items])
        ].compact
      ),
      NavGroup.new(
        label: "Network",
        icon: "bi-people",
        items: [
          NavItem.new(label: "Partner agencies", path: partners_path, active_on: %w[partners]),
          NavItem.new(label: "Partner announcements", path: broadcast_announcements_path, active_on: %w[broadcast_announcements]),
          NavItem.new(label: "Donation sites", path: donation_sites_path, active_on: %w[donation_sites]),
          NavItem.new(label: "Product drives", path: product_drives_path, active_on: %w[product_drives]),
          NavItem.new(label: "Product drive participants", path: product_drive_participants_path, active_on: %w[product_drive_participants]),
          NavItem.new(label: "Manufacturers", path: manufacturers_path, active_on: %w[manufacturers]),
          NavItem.new(label: "Vendors", path: vendors_path, active_on: %w[vendors])
        ]
      )
    ].reject { |group| group.items.empty? }
  end

  # --- Super admin ----------------------------------------------------------
  #
  # The admin area is a separate app in everything but routing: none of the bank navigation
  # applies to it, and a super admin standing in /admin needs the admin destinations. Flat,
  # because there are nine of them.
  def essentials_admin_nav_items
    [
      NavItem.new(label: "Admin dashboard", path: admin_dashboard_path, active_on: %w[admin], icon: "bi-speedometer2"),
      NavItem.new(label: "Account requests", path: admin_account_requests_path, active_on: %w[admin/account_requests], icon: "bi-envelope-paper"),
      NavItem.new(label: "Organizations", path: admin_organizations_path, active_on: %w[admin/organizations], icon: "bi-buildings"),
      NavItem.new(label: "NDBN member upload", path: admin_ndbn_members_path, active_on: %w[admin/ndbn_members], icon: "bi-upload"),
      NavItem.new(label: "Partners", path: admin_partners_path, active_on: %w[admin/partners], icon: "bi-people"),
      NavItem.new(label: "Users", path: admin_users_path, active_on: %w[admin/users], icon: "bi-person-gear"),
      NavItem.new(label: "Base items", path: admin_base_items_path, active_on: %w[admin/base_items], icon: "bi-box-seam"),
      NavItem.new(label: "Barcode items", path: admin_barcode_items_path, active_on: %w[admin/barcode_items], icon: "bi-upc-scan"),
      NavItem.new(label: "Announcements", path: admin_broadcast_announcements_path, active_on: %w[admin/broadcast_announcements], icon: "bi-megaphone"),
      NavItem.new(label: "FAQ", path: admin_questions_path, active_on: %w[admin/questions], icon: "bi-question-lg")
    ]
  end

  # Is the user standing in the admin area? The admin rail replaces the bank rail there
  # rather than sitting beside it -- two full navigations in one sidebar is not navigation.
  def essentials_admin_area?
    params[:controller].to_s.start_with?("admin")
  end

  # --- Partner portal -------------------------------------------------------
  #
  # The partner rail is short enough to stay flat: seven destinations at most, so there is
  # nothing to collapse and no group labels to add. Partners see their own vocabulary
  # ("Essentials requests", not "Requests") -- that is deliberate and is carried over from
  # the AdminLTE rail unchanged.
  def essentials_partner_nav_items
    items = [
      NavItem.new(label: "Dashboard", path: partner_user_root_path, active_on: %w[partners/dashboards], icon: "bi-speedometer2"),
      NavItem.new(label: "My profile", path: partners_profile_path, active_on: %w[partners/profiles], icon: "bi-person-badge"),
      NavItem.new(label: "Essentials requests", path: partners_requests_path, active_on: %w[partners/requests partners/family_requests partners/individuals_requests], icon: "bi-clipboard-check"),
      NavItem.new(label: "Distributions", path: partners_distributions_path, active_on: %w[partners/distributions], icon: "bi-truck")
    ]

    if current_partner&.profile&.enable_child_based_requests?
      items << NavItem.new(label: "Families", path: partners_families_path, active_on: %w[partners/families], icon: "bi-house-heart")
      items << NavItem.new(label: "Children", path: partners_children_path, active_on: %w[partners/children partners/authorized_family_members], icon: "bi-person-arms-up")
    end

    items
  end

  # A group opens on load when it holds the current page, so a user never has to hunt for
  # where they already are.
  def essentials_nav_group_open?(group)
    group.items.any? { |item| item.active?(params[:controller]) }
  end

  def essentials_nav_item_active?(item)
    item.active?(params[:controller])
  end
end
