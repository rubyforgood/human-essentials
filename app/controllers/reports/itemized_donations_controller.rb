class Reports::ItemizedDonationsController < ApplicationController
  def index
    setup_date_range_picker
    @donations = current_organization.donations.during(helpers.selected_range)
    @itemized_donation_data = DonationItemizedBreakdownService.new(organization: current_organization, donation_ids: @donations.pluck(:id)).fetch
  end
end
