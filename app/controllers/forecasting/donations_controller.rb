class Forecasting::DonationsController < Forecasting::BaseController
  def index
    @series = series('Donation')
    @title = 'Monthly Donations'
  end
end
