class Reports::ItemizedDistributionsController < ApplicationController
  def index
    setup_date_range_picker
    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @itemized_distribution_data = DistributionItemizedBreakdownService.new(organization: current_organization, distribution_ids: distributions.pluck(:id)).fetch
  end
end
