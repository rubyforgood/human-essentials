class DistributionsByCountyController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  def report
    setup_date_range_picker
    start_date = helpers.selected_range.first.utc.iso8601
    end_date = helpers.selected_range.last.utc.iso8601

    @reporting_categories = Item.reporting_categories_for_select
    @items = current_organization.items.loose.alphabetized.select(:id, :name)
    @selected_reporting_category = filter_params[:by_reporting_category].presence
    @selected_item = filter_params[:by_item_id].presence

    @breakdown = DistributionSummaryByCountyQuery.call(
      organization_id: current_organization.id,
      start_date: start_date,
      end_date: end_date,
      reporting_category: @selected_reporting_category,
      item_id: @selected_item
    )
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params
      .require(:filters)
      .permit(:by_item_id,  :by_reporting_category,  :date_range)
  end


end


