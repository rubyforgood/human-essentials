class HistoricalTrends::DistributionsController < HistoricalTrends::BaseController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
    @series = cached_series('Distribution')
    @title = 'Monthly Distributions'
  end
end
