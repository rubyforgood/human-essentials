class DistributionSummaryController < ApplicationController
  def index
    setup_date_range_picker

    # calling .recent on recent donations by manufacturers will only count the last 3 donations
    # which may not make sense when calculating total count using a date range
    @recent_donations_from_manufacturers = current_organization.donations.during(helpers.selected_range).by_source(:manufacturer)
    @top_manufacturers = current_organization.manufacturers.by_donation_count

    @distribution_data = helpers.received_distributed_data(helpers.selected_range)
  end
end
