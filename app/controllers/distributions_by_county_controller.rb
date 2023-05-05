class DistributionsByCountyController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  def report
    setup_date_range_picker
    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @breakdown = DistributionByCountyReportService.new.get_breakdown(distributions)
  end
end
