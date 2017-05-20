class DashboardController < ApplicationController
  respond_to :html, :js

  def index
    @recent_donations = Donation.includes(:line_items).recent
    @recent_distributions = Distribution.includes(:line_items).recent
  end
end
