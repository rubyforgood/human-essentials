class HistoricalTrends::PurchasesController < HistoricalTrends::BaseController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
    trend_for("Purchase")
    @title = "Monthly purchases"
  end
end
