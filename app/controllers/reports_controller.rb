class ReportsController < ApplicationController
  before_action :setup_date_range_picker

  def donations_summary
    @donations = current_organization.donations.during(helpers.selected_range)
    @recent_donations = @donations.recent
  end

  def manufacturer_donations_summary
    @recent_donations_from_manufacturers = current_organization.donations.during(helpers.selected_range).by_source(:manufacturer)
    @top_manufacturers = current_organization.manufacturers.by_donation_count
    @donations = current_organization.donations.during(helpers.selected_range)
    @recent_donations = @donations.recent
  end

  def purchases_summary
    @purchases = current_organization.purchases.during(helpers.selected_range)
    @recent_purchases = @purchases.recent.includes(:vendor)
  end

  def product_drives_summary
    @donations = current_organization.donations.during(helpers.selected_range)
    @recent_donations = @donations.recent
  end

  def itemized_donations
    @donations = current_organization.donations.during(helpers.selected_range)
    @itemized_donation_data = DonationItemizedBreakdownService.new(organization: current_organization, donation_ids: @donations.pluck(:id)).fetch
  end

  def itemized_distributions
    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @itemized_distribution_data = DistributionItemizedBreakdownService.new(organization: current_organization, distribution_ids: distributions.pluck(:id)).fetch
  end

  def distributions_summary
    distributions = current_organization.distributions.includes(:partner).during(helpers.selected_range)
    @recent_distributions = distributions.recent
  end

  def activity_graph
    @distribution_data = received_distributed_data(helpers.selected_range)
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
