# Encapsulates business logic related to displaying Donations
module DonationsHelper
  def total_received_donations(range = selected_range)
    number_with_delimiter total_received_donations_unformatted(range)
  end

  def total_received_money_donations(range = selected_range)
    current_organization.donations.during(range).sum { |d| d.money_raised || 0 }
  end

  def total_received_money_donations_from_product_drives(range: selected_range)
    current_organization.donations.by_source(:product_drive).during(range).sum { |d| d.money_raised || 0 }
  end

  def total_received_from_product_drives(range = selected_range)
    number_with_delimiter total_received_from_product_drives_unformatted(range)
  end

  def total_number_of_drives(range = selected_range)
    formatted_range = format_date_range_to_iso(range)
    current_organization.product_drives.within_date_range(formatted_range).count
  end

  private

  def total_received_donations_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.donations.during(range)).sum(:quantity)
  end

  def total_received_from_product_drives_unformatted(range = selected_range)
    LineItem.active.where(itemizable: current_organization.donations.by_source(:product_drive).during(range)).sum(:quantity)
  end

  def format_date_range_to_iso(range)
    "#{range.begin.to_date.iso8601} - #{range.end.to_date.iso8601}"
  end
end
