class HistoricalTrends::PurchasesController < HistoricalTrends::BaseController
  def index
    @series = series('Purchase')
    @title = "Monthly Purchases"
  end
end
