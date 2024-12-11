class DistributionsByCountyController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  def report
    setup_date_range_picker
    start_date = helpers.selected_range.first.iso8601
    end_date = helpers.selected_range.last.iso8601
    @breakdown = DistributionSummaryByCountyQuery.call(
      organization_id: current_organization.id,
      start_date: start_date,
      end_date: end_date
    )
  end
end
