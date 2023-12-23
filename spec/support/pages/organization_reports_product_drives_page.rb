require_relative "organization_page"

class OrganizationReportsProductDrivesPage < OrganizationPage
  def org_page_path
    "reports/product_drives"
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

  def has_product_drives_section?
    has_selector? product_drives_selector
  end

  def recent_product_drive_donation_links
    within product_drives_section do
      all(".donation a").map(&:text)
    end
  end

  def product_drives_section
    find product_drives_selector
  end

  def product_drives_selector
    "#product_drives"
  end
end
