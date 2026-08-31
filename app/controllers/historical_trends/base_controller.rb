class HistoricalTrends::BaseController < ApplicationController
  # The window and the comparison both come from the URL, so a chosen view survives a reload, a
  # bookmark and a link.
  #
  # Cached per organization *and per window*. The comparison is not in the key: it selects from the
  # series rather than changing them, so one cached window serves every selection made against it.
  def trend_for(type)
    from, to = helpers.selected_month_range
    service = HistoricalTrendService.new(current_organization.id, type, from: from, to: to)
    key = ["historical", current_organization.id, type, from.strftime("%Y%m"), to.strftime("%Y%m")]

    @series = Rails.cache.fetch([*key, "series"].join("-")) { service.series }
    @months = service.months
    @last_month_in_progress = service.last_month_in_progress?
    @scheduled_beyond_today = service.scheduled_beyond_today
    @item_categories = current_organization.item_categories.order(:name)

    selections = helpers.selected_comparisons
    @comparison_series = service.comparison_series(selections)
    @table_items = service.items_for(selections)
    @monthly_totals = totals_for(@table_items, service.months.size)

    return unless helpers.compare_previous?

    # Only computed when asked for: it is a second pass over a second window, and most visits do
    # not want it.
    @previous_totals = Rails.cache.fetch([*key, "previous"].join("-")) { service.previous_totals }
    @previous_window = service.previous_window
  end

  private

  def totals_for(items, span)
    items.each_with_object(Array.new(span, 0)) do |item, out|
      item[:data].each_with_index { |value, i| out[i] += value.to_i }
    end
  end
end
