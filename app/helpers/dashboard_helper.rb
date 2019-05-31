# Encapsulates methods used on the Dashboard that need some business logic
module DashboardHelper
  def display_interval
    selected_interval.humanize.downcase
  end

  def filter_intervals
    [
      %w(Today today),
      %w(Yesterday yesterday),
      ["This Week", "this_week"],
      ["This Month", "this_month"],
      ["Last Month", "last_month"],
      ["Year to date", "year_to_date"],
      ["Last Year", "last_year"],
      ["All time", "all_time"],
    ]
  end

  def selected_interval
    params.dig(:dashboard_filter, :interval) || "year_to_date"
  end

  def selected_range
    now = Time.zone.now
    case selected_interval
    when "today"
      now.beginning_of_day..now
    when "yesterday"
      (now - 1).beginning_of_day..(now - 1).end_of_day
    when "this_week"
      now.beginning_of_week..now
    when "this_month"
      now.beginning_of_month..now
    when "last_month"
      (now - 1.month).beginning_of_month..(now - 1.month).end_of_month
    when "year_to_date"
      now.beginning_of_year..now
    when "last_year"
      (now - 1.year).beginning_of_year..(now - 1.year).end_of_year
    else
      Time.zone.local(2017, 1, 1, 0, 0, 0)..now
    end
  end

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
    number_with_delimiter current_organization.donations.during(range).collect(&:money_raised).compact.reduce(0, :+)
  end

  def total_received_donations(range = selected_range)
    number_with_delimiter total_received_donations_unformatted(range)
  end

  def total_received_from_diaper_drives(range = selected_range)
    number_with_delimiter total_received_from_diaper_drives_unformatted(range)
  end

  def total_purchased(range = selected_range)
    number_with_delimiter total_purchased_unformatted(range)
  end

  def total_distributed(range = selected_range)
    number_with_delimiter total_distributed_unformatted(range)
  end

  private

  def total_received_donations_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.donations.during(range)).sum(:quantity)
  end

  def total_received_from_diaper_drives_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.donations.by_source(:diaper_drive).during(range)).sum(:quantity)    
  end

  def total_purchased_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.purchases.during(range)).sum(:quantity)
  end

  def total_distributed_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.distributions.during(range)).sum(:quantity)
  end
end
