class DashboardController < ApplicationController
  respond_to :html, :js

  def index
    @recent_donations = current_organization.donations.includes(:line_items).during(helpers.selected_range).recent
    @recent_purchases = current_organization.purchases.includes(:line_items).during(helpers.selected_range).recent
    @recent_distributions = current_organization.distributions.includes(:line_items).during(helpers.selected_range).recent
    @total_inventory = current_organization.total_inventory

    @org_stats = OrganizationStats.new(current_organization)
  end
end
