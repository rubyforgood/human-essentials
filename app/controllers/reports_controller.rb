class ReportsController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  before_action :setup_date_range_picker

  # The hub. Deliberately loads nothing: every report already owns its own date range, and a
  # hub that ran fifteen queries to render a menu would be the slowest page in the app.
  def index
  end

  MANUFACTURER_ROWS = 10

  def manufacturer_donations_summary
    range = helpers.selected_range
    @recent_donations_from_manufacturers = current_organization.donations.during(range).by_source(:manufacturer)
    # `to_a`, because these are grouped relations: `.size` on one returns a Hash of group counts
    # rather than a number, and the view wants to count rows. The model's `donating_in_count` exists
    # for the same reason -- it has to say `.count.size`.
    @manufacturers = current_organization.manufacturers.donating_in(range, limit: MANUFACTURER_ROWS).to_a
    # What the page is showing ten *of*. The list was capped at ten and never said so.
    @manufacturers_donating = current_organization.manufacturers.donating_in_count(range)
    @manufacturer_items_total = @manufacturers.sum { |m| m.items_donated.to_i }
  end

  def itemized_donations
    @donations = current_organization.donations.during(helpers.selected_range)
    @itemized_donation_data = DonationItemizedBreakdownService.new(organization: current_organization, donation_ids: @donations.pluck(:id)).fetch
  end

  def itemized_distributions
    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @itemized_distribution_data = DistributionItemizedBreakdownService.new(organization: current_organization, distribution_ids: distributions.pluck(:id)).fetch
  end

  def activity_graph
    @distribution_data = received_distributed_data(helpers.selected_range)
  end

  def itemized_requests
    requests = current_organization.requests.during(helpers.selected_range)
    @itemized_request_data = RequestItemizedBreakdownService.call(organization: current_organization, request_ids: requests.pluck(:id))
  end

  private

  def total_purchased_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.purchases.during(range)).sum(:quantity)
  end

  def total_distributed_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.distributions.during(range)).sum(:quantity)
  end

  def total_received_donations_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.donations.during(range)).sum(:quantity)
  end

  def received_distributed_data(range = selected_range)
    {
      "Received donations" => total_received_donations_unformatted(range),
      "Purchased" => total_purchased_unformatted(range),
      "Distributed" => total_distributed_unformatted(range)
    }
  end
end
