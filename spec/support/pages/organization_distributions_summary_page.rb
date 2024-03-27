require_relative "organization_page"

class OrganizationDistributionsSummaryPage < OrganizationPage
  def org_page_path
    "reports/distributions_summary"
  end

  def total_distributed
    within distributions_section do
      parse_formatted_integer find(".total_distributed").text
    end
  end

  def filter_to_date_range(range_name, custom_dates = nil)
    select_date_filter_range range_name

    if custom_dates.present?
      fill_in :filters_date_range, with: ""
      fill_in :filters_date_range, with: custom_dates
      # clicking on page to ensure date picker closes
      page.find(:xpath, "//*[contains(text(),'Recent distributions')]").click
    end

    click_on "Filter"
  end

  def recent_distribution_links
    within distributions_section do
      all(".distribution a").map(&:text)
    end
  end

  def has_distributions_section?
    has_selector? distributions_section_selector
  end

  def create_new_distribution
    within distributions_section do
      click_link "New Distribution"
    end
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

  def distributions_section
    find distributions_section_selector
  end

  def distributions_section_selector
    "#distributions"
  end
end
