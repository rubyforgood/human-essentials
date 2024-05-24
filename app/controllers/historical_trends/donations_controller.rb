class HistoricalTrends::DonationsController < HistoricalTrends::BaseController
  def index
    @series = cached_series('Donation')
    @title = 'Monthly Donations'
  end
end
