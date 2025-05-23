class HistoricalTrends::BaseController < ApplicationController
  def cached_series(type)
    Rails.cache.fetch("#{current_organization.id}-historical-#{type}-data") { HistoricalTrendService.new(current_organization.id, type).series }
  end
end
