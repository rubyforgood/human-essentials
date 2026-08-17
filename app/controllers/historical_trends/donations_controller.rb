class HistoricalTrends::DonationsController < HistoricalTrends::BaseController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
    @series = cached_series('Donation')
    @title = 'Monthly Donations'
  end
end
