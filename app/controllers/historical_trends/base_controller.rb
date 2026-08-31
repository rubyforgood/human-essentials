class HistoricalTrends::BaseController < ApplicationController
  # The window comes from the URL, so a chosen range survives a reload, a bookmark and a link.
  #
  # Cached per organization *and per window*, which the key did not carry before -- there was only
  # one window, so there was only one thing to cache. Without the range in the key, choosing a
  # different one would have been served the previous one's figures from the cache.
  def trend_for(type)
    from, to = helpers.selected_month_range
    service = HistoricalTrendService.new(current_organization.id, type, from: from, to: to)
    key = "#{current_organization.id}-historical-#{type}-#{from.strftime("%Y%m")}-#{to.strftime("%Y%m")}"
    @series = Rails.cache.fetch(key) { service.series }
    @months = service.months
    @last_month_in_progress = service.last_month_in_progress?
    @scheduled_beyond_today = service.scheduled_beyond_today
  end
end
