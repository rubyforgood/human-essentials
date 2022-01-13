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

  def create_new_purchase
    within purchases_section do
      click_link "New Purchase"
    end
  end

  def filter_to_date_range(range_name)
    select_date_filter_range range_name
    click_on "Filter"
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

  def has_organization_logo?
    has_selector? org_logo_selector
  end

  def organization_logo_filepath
    find(org_logo_selector).native[:src]
  end

  def recent_donation_links
    within donations_section do
      all(".donation a").map(&:text)
    end
  end

  def recent_purchase_links
    within purchases_section do
      all(".purchase a").map(&:text)
    end
  end

  def select_date_filter_range(range_name)
    find("#filters_date_range").click
    within ".ranges" do
      find("li[data-range-key='#{range_name}']").click
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

  private

  def donations_section
    find "#donations"
  end

  def org_logo_selector
    ".organization-logo"
  end

  def purchases_section
    find "#purchases"
  end
end
