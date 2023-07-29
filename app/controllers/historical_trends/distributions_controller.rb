class HistoricalTrends::DistributionsController < HistoricalTrends::BaseController
  def index
    @series = cached_series('Distribution')
    @title = 'Monthly Distributions'
  end
end
