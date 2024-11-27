# Prepares data to be shown to the users for their dashboard.
class DashboardController < ApplicationController
  respond_to :html, :js

  def index
    @org_stats = OrganizationStats.new(current_organization)
    @total_inventory = current_organization.total_inventory
    @partners_awaiting_review = current_organization.partners.awaiting_review
    @outstanding_requests = current_organization.ordered_requests.where(status: %i[pending started]).order(:created_at)

    @low_inventory_report = LowInventoryQuery.call(current_organization)

    # passing nil here filters the announcements that didn't come from an organization
    @broadcast_announcements = BroadcastAnnouncement.filter_announcements(nil)
  end
end
