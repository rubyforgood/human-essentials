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

  # nil rather than main's "N/A" when the donation did not come from a product drive. Every other
  # field in the detail list this feeds renders `value.presence || "—"`, which is the convention in
  # sixteen places; returning a string here would make one field in the row say something different
  # for the same condition. The helper stays because it is the one place that knows how a
  # participant is named.
  def drive_participant_view(donation)
    donation.product_drive_participant&.display_name
  end

  def options_with_new(records)
    model_class = records.klass
    label = "---Create New #{model_class.model_name.human}---"
    records.map { |record| [record.name, record.id] } << [label, "new"]
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
