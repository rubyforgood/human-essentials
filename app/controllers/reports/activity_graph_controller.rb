class Reports::ActivityGraphController < ApplicationController
  def index
    setup_date_range_picker
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
