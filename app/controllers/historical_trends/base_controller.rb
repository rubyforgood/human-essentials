class HistoricalTrends::BaseController < ApplicationController
  # The window, the category and the comparison all come from the URL, so a chosen view survives a
  # reload, a bookmark and a link.
  #
  # Cached per organization *and per window and category*, which the key did not carry before --
  # there was only one of each, so there was only one thing to cache. Without them in the key,
  # choosing a different range or category would be served the previous one's figures.
  def trend_for(type)
    from, to = helpers.selected_month_range
    category_id = helpers.selected_trend_category
    service = HistoricalTrendService.new(current_organization.id, type,
      from: from, to: to, category_id: category_id)

    @series = cached(service, type, from, to, category_id, "series") { service.series }
    @monthly_totals = cached(service, type, from, to, category_id, "totals") { service.monthly_totals }
    @category_series = cached(service, type, from, to, category_id, "categories") { service.category_series }
    @months = service.months
    @last_month_in_progress = service.last_month_in_progress?
    @scheduled_beyond_today = service.scheduled_beyond_today
    @item_categories = current_organization.item_categories.order(:name)

    return unless helpers.compare_previous?

    # Only computed when asked for: it is a second pass over a second window, and most visits do
    # not want it.
    @previous_totals = cached(service, type, from, to, category_id, "previous") { service.previous_totals }
    @previous_window = service.previous_window
  end

  private

  def cached(_service, type, from, to, category_id, part, &block)
    key = ["historical", current_organization.id, type, from.strftime("%Y%m"), to.strftime("%Y%m"),
      category_id || "all", part].join("-")
    Rails.cache.fetch(key, &block)
  end
end
