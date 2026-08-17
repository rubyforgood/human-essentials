class DistributionsByCountyController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  include DateRangeHelper
  include DistributionHelper

  def report
    setup_date_range_picker
    start_date = helpers.selected_range.first.utc.iso8601
    end_date = helpers.selected_range.last.utc.iso8601

    @breakdown = DistributionSummaryByCountyQuery.call(
      organization_id: current_organization.id,
      start_date: start_date,
      end_date: end_date
    )
  end
end
