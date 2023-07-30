class DistributionsSummaryController < ApplicationController
  def index
    setup_date_range_picker

    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @recent_distributions = distributions.recent
  end
end
