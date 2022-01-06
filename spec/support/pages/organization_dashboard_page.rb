require_relative "organization_page"

class OrganizationDashboardPage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "dashboard"
  end

  def create_new_donation
    within "#donations" do
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

  def has_organization_logo?
    has_selector? org_logo_selector
  end

  def organization_logo_filepath
    find(org_logo_selector).native[:src]
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

  def total_inventory
    within summary_section do
      find(".total_inventory").text.delete(",").to_i
    end
  end

  private

  def org_logo_selector
    ".organization-logo"
  end

  def purchases_section
    find "#purchases"
  end
end
