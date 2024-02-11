class ReportsController < ApplicationController
  def donations_summary
    setup_date_range_picker

    @donations = current_organization.donations.during(helpers.selected_range)
    @recent_donations = @donations.recent
  end

  def manufacturer_donations_summary
    setup_date_range_picker

    @recent_donations_from_manufacturers = current_organization.donations.during(helpers.selected_range).by_source(:manufacturer)
    @top_manufacturers = current_organization.manufacturers.by_donation_count
    @donations = current_organization.donations.during(helpers.selected_range)
    @recent_donations = @donations.recent
  end

  def product_drives_summary
    setup_date_range_picker
    @donations = current_organization.donations.during(helpers.selected_range)
    @recent_donations = @donations.recent
  end

  def itemized_donations
    setup_date_range_picker
    @donations = current_organization.donations.during(helpers.selected_range)
    @itemized_donation_data = DonationItemizedBreakdownService.new(organization: current_organization, donation_ids: @donations.pluck(:id)).fetch
  end
end
