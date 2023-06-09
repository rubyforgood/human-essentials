class HistoricalTrends::DonationsController < HistoricalTrends::BaseController
  def index
    @series = series('Donation')
    @title = 'Monthly Donations'
  end
end
