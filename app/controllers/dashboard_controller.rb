class DashboardController < ApplicationController
  respond_to :html, :js

  def index
    @recent_donations = current_organization.donations.includes(:line_items).recent
    @recent_distributions = current_organization.distributions.includes(:line_items).recent
    @total_inventory = current_organization.total_inventory
  end
end
