# Prepares data to be shown to the users for their dashboard.
class DashboardController < ApplicationController
  respond_to :html, :js

  def index
    setup_date_range_picker
    @donations = current_organization.donations.includes(:line_items).during(helpers.selected_range)
    @recent_donations = @donations.recent
    @purchases = current_organization.purchases.includes(:line_items).during(helpers.selected_range)
    @recent_purchases = @purchases.recent

    @recent_distributions = current_organization.distributions.includes(:line_items).during(helpers.selected_range).recent
    @total_inventory = current_organization.total_inventory

    @org_stats = OrganizationStats.new(current_organization)

    # calling .recent on recent donations by manufacturers will only count the last 3 donations
    # which may not make sense when calculating total count using a date range
    @recent_donations_from_manufacturers = current_organization.donations.includes(:line_items).during(helpers.selected_range).by_source(:manufacturer)
    @top_manufacturers = current_organization.manufacturers.by_donation_count
  end
end
