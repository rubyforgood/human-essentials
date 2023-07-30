# Prepares data to be shown to the users for their dashboard.
class DashboardController < ApplicationController
  respond_to :html, :js

  def index
    setup_date_range_picker

    @donations = current_organization.donations.during(helpers.selected_range)
    @recent_donations = @donations.recent

    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @itemized_distribution_data = DistributionItemizedBreakdownService.new(organization: current_organization, distribution_ids: distributions.pluck(:id)).fetch

    @total_inventory = current_organization.total_inventory

    @org_stats = OrganizationStats.new(current_organization)

    # calling .recent on recent donations by manufacturers will only count the last 3 donations
    # which may not make sense when calculating total count using a date range
    @recent_donations_from_manufacturers = current_organization.donations.during(helpers.selected_range).by_source(:manufacturer)
    @top_manufacturers = current_organization.manufacturers.by_donation_count

    @distribution_data = helpers.received_distributed_data(helpers.selected_range)

    @partners_awaiting_review = current_organization.partners.awaiting_review
    # passing nil here filters the announcements that didn't come from an organization
    @broadcast_announcements = BroadcastAnnouncement.filter_announcements(nil)

    @outstanding_requests = Request.where(status: %i[pending started]).order(:created_at)
  end
end
