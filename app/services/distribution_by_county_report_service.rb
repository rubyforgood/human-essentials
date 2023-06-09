# frozen_string_literal: true

class DistributionByCountyReportService
  Breakdown = Struct.new(:name, :region, :num_items, :amount)
  def get_breakdown(distributions)
    breakdowns = {}
    breakdowns["Unspecified"] = Breakdown.new("Unspecified", "ZZZ", 0, 0.00)
    distributions.each do |distribution|
      served_areas = distribution.partner.profile.served_areas
      num_items_for_distribution = distribution.line_items.total
      value_of_distribution = distribution.line_items.total_value
      if served_areas.size == 0
        breakdowns["Unspecified"].num_items += num_items_for_distribution
        breakdowns["Unspecified"].amount += value_of_distribution
      else
        served_areas.each do |served_area|
          name = served_area.county.name
          percentage = served_area.client_share / 100.0
          if !breakdowns[name]
            breakdowns[name] = Breakdown.new(name, served_area.county.region,
              (num_items_for_distribution * percentage).round(0), value_of_distribution * percentage)
          else
            breakdowns[name].num_items = breakdowns[name].num_items + (num_items_for_distribution * percentage).round(0)
            breakdowns[name].amount = breakdowns[name].amount + value_of_distribution * percentage
          end
        end
      end
    end

    breakdown_array = breakdowns.sort_by { |k, v| [v.region, k] }
    @breakdown = breakdown_array.map { |a| a[1] }
  end
end
