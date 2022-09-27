class Forecasting::PurchasesController < Forecasting::BaseController
  def index
    @series = series('Purchase')
    @title = "Monthly Purchases"
  end
end
