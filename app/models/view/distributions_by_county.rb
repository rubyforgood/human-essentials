module View
  DistributionsByCounty = Data.define(
    :breakdown,
    :filters,
    :items,
    :reporting_categories
  ) do
    include DateRangeHelper

    class << self
      def filter_params(params)
        return {} unless params.key?(:filters)
        params
          .require(:filters)
          .permit(:by_item_id, :by_reporting_category, :date_range)
      end

      def from_params(params:, organization:, helpers:)
        filters = filter_params(params)
        start_date = helpers.selected_range.first.utc.iso8601
        end_date = helpers.selected_range.last.utc.iso8601
        breakdown = DistributionSummaryByCountyQuery.call(
          organization_id: organization.id,
          start_date: start_date,
          end_date: end_date,
          reporting_category: filters[:by_reporting_category].presence,
          item_id: filters[:by_item_id].presence
        )

        new(
          breakdown: breakdown,
          filters: filters,
          reporting_categories: Item.reporting_categories_for_select,
          items: organization.items.loose.alphabetized.select(:id, :name)
        )
      end
    end
    def selected_reporting_category
      filters[:by_reporting_category].presence
    end

    def selected_item
      filters[:by_item_id].presence
    end
  end
end
