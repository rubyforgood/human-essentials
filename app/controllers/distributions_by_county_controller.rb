class DistributionsByCountyController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  def show
    setup_date_range_picker
    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @breakdown = {}
    @breakdown["Unspecified"] = {}
    @breakdown["Unspecified"][:num_items] = 0
    @breakdown["Unspecified"][:amount] = 0.00
    distributions.each do |distribution|
      partner_counties = distribution.partner.partner_counties
      num_items_for_distribution = distribution.line_items.total
      value_of_distribution = distribution.line_items.total_value
      if partner_counties.size == 0
        @breakdown["Unspecified"][:num_items] += num_items_for_distribution
        @breakdown["Unspecified"][:amount] += value_of_distribution
      else
        partner_counties.each do |pc|
          name = pc.county.name
          if !@breakdown[name]
            @breakdown[name] = {}
            @breakdown[name][:region] = pc.county.region
            @breakdown[name][:num_items] = num_items_for_distribution * pc.client_share
            @breakdown[name][:amount] = value_of_distribution * pc.client_share
          else
            @breakdown[name][:num_items] = @breakdown[name][:num_items] + num_items_for_distribution * pc.client_share
            @breakdown[name][:amount] = @breakdown[name][:amount] + value_of_distribution * pc.client_share
          end
        end
      end
    end
  end
end
