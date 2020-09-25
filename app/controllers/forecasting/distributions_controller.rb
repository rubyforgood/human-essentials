class Forecasting::DistributionsController < Forecasting::BaseController
  def index
    @series = series('Distribution')
    @title = 'Monthly Distributions'
  end
end
