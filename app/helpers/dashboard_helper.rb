# Encapsulates methods used on the Dashboard that need some business logic
module DashboardHelper
  def received_distributed_data(range = selected_range)
    {
      "Received donations" => total_received_donations_unformatted(range),
      "Purchased" => total_purchased_unformatted(range),
      "Distributed" => total_distributed_unformatted(range)
    }
  end

  def total_on_hand(total = nil)
    number_with_delimiter(total || "-1")
  end

  def total_received_money_donations(range = selected_range)
    current_organization.donations.during(range).sum { |d| d.money_raised || 0 }
  end

  def total_received_money_donations_from_product_drives(range: selected_range)
    current_organization.donations.by_source(:product_drive).during(range).sum { |d| d.money_raised || 0 }
  end

  def total_received_donations(range = selected_range)
    number_with_delimiter total_received_donations_unformatted(range)
  end

  def total_received_from_product_drives(range = selected_range)
    number_with_delimiter total_received_from_product_drives_unformatted(range)
  end

  def total_purchased(range = selected_range)
    number_with_delimiter total_purchased_unformatted(range)
  end

  def total_distributed(range = selected_range)
    number_with_delimiter total_distributed_unformatted(range)
  end

  def future_distributed
    number_with_delimiter future_distributed_unformatted
  end

  private

  def total_received_donations_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.donations.during(range)).sum(:quantity)
  end

  def total_received_from_product_drives_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.donations.by_source(:product_drive).during(range)).sum(:quantity)
  end

  def total_purchased_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.purchases.during(range)).sum(:quantity)
  end

  def total_distributed_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.distributions.during(range)).sum(:quantity)
  end

  def future_distributed_unformatted
    LineItem.active.where(itemizable: current_organization.distributions.future).sum(:quantity)
  end
end
