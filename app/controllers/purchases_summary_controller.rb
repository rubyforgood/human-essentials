class PurchasesSummaryController < ApplicationController
  def index
    setup_date_range_picker
    @purchases = current_organization.purchases.during(helpers.selected_range)
    @recent_purchases = @purchases.recent.includes(:vendor)
  end
end
