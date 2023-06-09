class HistoricalTrends::DistributionsController < HistoricalTrends::BaseController
  def index
    @series = series('Distribution')
    @title = 'Monthly Distributions'
  end
end
