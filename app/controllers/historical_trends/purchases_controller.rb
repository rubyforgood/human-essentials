class HistoricalTrends::PurchasesController < HistoricalTrends::BaseController
  def index
    @series = cached_series('Purchase')
    @title = "Monthly Purchases"
  end
end
