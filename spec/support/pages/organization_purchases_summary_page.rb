require_relative "organization_page"

class OrganizationPurchasesSummaryPage < OrganizationPage
  def org_page_path
    "reports/purchases_summary"
  end

  def create_new_purchase
    within purchases_section do
      click_link "New Purchase"
    end
  end

  def recent_purchase_links
    within purchases_section do
      all(".purchase a").map(&:text)
    end
  end

  def filter_to_date_range(range_name, custom_dates = nil)
    select_date_filter_range range_name

    if custom_dates.present?
      fill_in :filters_date_range, with: ""
      fill_in :filters_date_range, with: custom_dates
      # clicking on page to ensure date picker closes
      page.find(:xpath, "//*[contains(text(),'Recent purchases')]").click
    end

    click_on "Filter"
  end

  private

  def select_date_filter_range(range_name)
    find("#filters_date_range").click

    if range_name
      within ".container__predefined-ranges" do
        find("button", text: range_name).click
      end
    end
  end

  def purchases_section
    find "#purchases"
  end
end
