class DistributionsByCountyController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  def report
    setup_date_range_picker

    @dbc_info = View::DistributionsByCounty.from_params(params: params,
      organization: current_organization, helpers: helpers)
  end
end
