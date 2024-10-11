require_relative "organization_page"

class OrganizationDashboardPage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "dashboard"
  end

  def create_new_donation
    within donations_section do
      click_link "New Donation"
    end
  end

  def has_add_donation_site_call_to_action?
    has_selector? "#org-stats-call-to-action-donation-sites"
  end

  def has_add_inventory_call_to_action?
    has_selector? "#org-stats-call-to-action-inventory"
  end

  def has_add_partner_call_to_action?
    has_selector? "#org-stats-call-to-action-partners"
  end

  def has_add_storage_location_call_to_action?
    has_selector? "#org-stats-call-to-action-storage-locations"
  end

  def has_getting_started_guide?
    has_selector? "#getting-started-guide"
  end

  def has_low_inventory_section?
    has_selector? low_inventory_selector
  end

  def has_manufacturers_section?
    has_selector? manufacturers_section_selector
  end

  def has_organization_logo?
    has_selector? org_logo_selector
  end

  def has_outstanding_section?
    has_selector? outstanding_selector
  end

  def manufacturers_total_donations
    within manufacturers_section do
      parse_formatted_integer find(".total_received_donations").text
    end
  end

  def num_manufacturers_donated
    within manufacturers_section do
      # the span contains something like "1 Manufacturer" or "28 Manufacturers"
      # Strip out the number
      find(".num_manufacturers_donated").text.match(/^\d+/).to_s.to_i
    end
  end

  def organization_logo_filepath
    find(org_logo_selector).native[:src]
  end

  def recent_donation_links
    within donations_section do
      all(".donation a").map(&:text)
    end
  end

  def top_manufacturer_donation_links
    within manufacturers_section do
      all(".manufacturer a").map(&:text)
    end
  end

  def summary_section
    find "#summary"
  end

  def total_donations
    within donations_section do
      parse_formatted_integer find(".total_received_donations").text
    end
  end

  def total_inventory
    within summary_section do
      parse_formatted_integer find(".total_inventory").text
    end
  end

  def low_inventory_section
    find low_inventory_selector
  end

  def low_inventories
    within low_inventory_section do
      all("tbody > tr").map(&:text)
    end
  end

  def outstanding_section
    find outstanding_selector
  end

  def outstanding_requests
    within outstanding_section do
      all("tbody > tr")
    end
  end

  def outstanding_requests_link
    within outstanding_section do
      find(".card-footer a")
    end
  end

  def has_partner_approvals_section?
    has_selector? "#partner_approvals.card"
  end

  def partner_approvals_section
    find "#partner_approvals.card"
  end

  private

  def low_inventory_selector
    "#low_inventory"
  end

  def donations_section
    find "#donations"
  end

  def manufacturers_section
    find manufacturers_section_selector
  end

  def manufacturers_section_selector
    "#manufacturers"
  end

  def org_logo_selector
    ".organization-logo"
  end

  def outstanding_selector
    "#outstanding"
  end
end
