class Reports::ManufacturerDonationsSummaryController < ApplicationController
  def index
    @recent_donations_from_manufacturers = current_organization.donations.during(helpers.selected_range).by_source(:manufacturer)
    puts 'try'
  end
end
