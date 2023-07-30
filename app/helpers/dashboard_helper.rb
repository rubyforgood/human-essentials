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

  def total_purchased(range = selected_range)
    number_with_delimiter total_purchased_unformatted(range)
  end

  def total_distributed(range = selected_range)
    number_with_delimiter total_distributed_unformatted(range)
  end

  def future_distributed
    number_with_delimiter future_distributed_unformatted
  end

  def recently_added_user_display_text(user)
    (user.name == "Name Not Provided") ? user.email : user.name
  end

  private

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
