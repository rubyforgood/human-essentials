class DistributionsByCountyController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  include DateRangeHelper
  include DistributionHelper

  def report
    setup_date_range_picker

    @dbc_info = View::DistributionsByCounty.from_params(params: params,
      organization: current_organization, helpers: helpers)
  end
end
