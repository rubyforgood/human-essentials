require_relative "organization_page"

class OrganizationDashboardPage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "dashboard"
  end

  def create_new_distribution
    within distributions_section do
      click_link "New Distribution"
    end
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

  def product_drive_total_donations
    within product_drives_section do
      parse_formatted_integer find(".total_received_donations").text
    end
  end

  def product_drive_total_money_raised
    within product_drives_section do
      parse_formatted_currency find(".total_money_raised").text
    end
  end

  def filter_to_date_range(range_name, custom_dates = nil)
    select_date_filter_range range_name

    if custom_dates.present?
      fill_in :filters_date_range, with: ""
      fill_in :filters_date_range, with: custom_dates
      page.find(:xpath, "//*[contains(text(),'- Dashboard')]").click
    end

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

  def has_product_drives_section?
    has_selector? product_drives_selector
  end

  def has_distributions_section?
    has_selector? distributions_section_selector
  end

  def has_getting_started_guide?
    has_selector? "#getting-started-guide"
  end

  def has_manufacturers_section?
    has_selector? manufacturers_section_selector
  end

  def has_organization_logo?
    has_selector? org_logo_selector
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

  def recent_product_drive_donation_links
    within product_drives_section do
      all(".donation a").map(&:text)
    end
  end

  def recent_distribution_links
    within distributions_section do
      all(".distribution a").map(&:text)
    end
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

  def recent_purchase_links
    within purchases_section do
      all(".purchase a").map(&:text)
    end
  end

  def select_date_filter_range(range_name)
    find("#filters_date_range").click

    if range_name
      within ".container__predefined-ranges" do
        find("button", text: range_name).click
      end
    end
  end

  def summary_section
    find "#summary"
  end

  def total_distributed
    within distributions_section do
      parse_formatted_integer find(".total_distributed").text
    end
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

  def product_drives_section
    find product_drives_selector
  end

  def product_drives_selector
    "#product_drives"
  end

  def distributions_section_selector
    "#distributions"
  end

  def distributions_section
    find distributions_section_selector
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

  def purchases_section
    find "#purchases"
  end
end
