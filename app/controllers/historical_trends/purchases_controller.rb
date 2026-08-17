class HistoricalTrends::PurchasesController < HistoricalTrends::BaseController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
    @series = cached_series('Purchase')
    @title = "Monthly Purchases"
  end
end
