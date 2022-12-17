class DistributionsByCountyController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  def show
    setup_date_range_picker
    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    breakdown_hash = {}
    breakdown_hash["Unspecified"] = {}
    breakdown_hash["Unspecified"][:region] = "ZZZ" # after all natural region names
    breakdown_hash["Unspecified"][:num_items] = 0
    breakdown_hash["Unspecified"][:amount] = 0.00
    distributions.each do |distribution|
      served_areas = distribution.partner.profile.served_areas
      num_items_for_distribution = distribution.line_items.total
      value_of_distribution = distribution.line_items.total_value
      if served_areas.size == 0
        breakdown_hash["Unspecified"][:num_items] += num_items_for_distribution
        breakdown_hash["Unspecified"][:amount] += value_of_distribution
      else
        served_areas.each do |served_area|
          name = served_area.county.name
          percentage = served_area.client_share / 100.0
          if !breakdown_hash[name]
            breakdown_hash[name] = {}
            breakdown_hash[name][:name] = name
            breakdown_hash[name][:region] = served_area.county.region
            breakdown_hash[name][:num_items] = (num_items_for_distribution * percentage).round(0)
            breakdown_hash[name][:amount] = value_of_distribution * percentage
          else
            breakdown_hash[name][:num_items] = breakdown_hash[name][:num_items] + (num_items_for_distribution * percentage).round(0)
            breakdown_hash[name][:amount] = breakdown_hash[name][:amount] + value_of_distribution * percentage
          end
        end
      end
    end

    @breakdown = breakdown_hash.sort_by { |k, v| [v[:region], k] }
  end
end
