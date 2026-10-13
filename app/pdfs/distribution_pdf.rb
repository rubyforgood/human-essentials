# The distribution receipt: what a partner was given, and what it was worth. Printed from the
# distribution page, from the partner portal, and attached to the email DistributionMailer sends.
class DistributionPdf < ApplicationPdf
  attr_reader :distribution

  def initialize(organization, distribution)
    super(organization)
    @distribution = Distribution.includes(:partner, line_items: [:item]).find_by(id: distribution.id)
  end

  def template
    "pdfs/distribution"
  end

  def document_name
    "Distribution receipt"
  end

  def profile
    distribution.partner.profile
  end

  def line_item_table
    data = distribution.request ? request_data : non_request_data
    hide_columns(data)
    table_from(data, quantities: ["Received", "Quantity"])
  end

  # The address the goods went to, or nil when they were picked up or the partner has none.
  # A program address, when there is one, is where deliveries go.
  def delivery_address_lines
    return unless distribution.delivery? || distribution.shipped?
    return unless profile.address1.present? || profile.program_address1.present?

    if profile.program_address1.blank?
      address_lines(profile.address1, profile.address2, profile.city, profile.state, profile.zip_code)
    else
      address_lines(profile.program_address1, profile.program_address2, profile.program_city,
        profile.program_state, profile.program_zip_code)
    end
  end

  def request_data
    data = [["Items received",
      "Requested",
      "Received",
      "Value per item",
      "In-kind value received",
      "Packages"]]
    item_requests = distribution.request.item_requests.includes(:item)
    line_items = distribution.line_items.sorted

    requested_not_received = item_requests.select do |item_request|
      line_items.none? { |i| i.item_id == item_request.item_id }
    end

    data += line_items.map do |c|
      item_request = item_requests.find { |i| i.item_id == c.item_id }
      [c.item.name,
        request_display_qty(item_request),
        c.quantity,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.package_count]
    end

    data += requested_not_received.sort_by(&:name).map do |item_request|
      [item_request.item.name,
        request_display_qty(item_request),
        "",
        dollar_value(item_request.item.value_in_cents),
        nil,
        nil]
    end

    data + [["Total items received",
      item_requests.sum { |ir| ir.quantity.to_i },
      distribution.line_items.total,
      "",
      dollar_value(distribution.value_per_itemizable),
      ""]]
  end

  def non_request_data
    data = [["Items received",
      "Value per item",
      "In-kind value",
      "Quantity",
      "Packages"]]
    data += distribution.line_items.sorted.map do |c|
      [c.item.name,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.quantity,
        c.package_count]
    end
    data + [["Total items received",
      "",
      dollar_value(distribution.value_per_itemizable),
      distribution.line_items.total,
      ""]]
  end

  def hide_columns(data)
    column_names_to_hide.each do |col_name|
      col_index = data.first.find_index(col_name)
      data.each { |line| line.delete_at(col_index) } if col_index.present?
    end
  end

  private

  def column_names_to_hide
    in_kind_column_name = distribution.request.present? ? "In-kind value received" : "In-kind value"
    columns_to_hide = []
    columns_to_hide.push("Value per item", in_kind_column_name) if organization.hide_value_columns_on_receipt
    columns_to_hide.push("Packages") if organization.hide_package_column_on_receipt
    columns_to_hide
  end

  # Street lines, then "City, State Zip" on one line -- the way an address is written on an envelope.
  # Blank parts drop out, so an incomplete address prints what it has and no stray commas.
  def address_lines(line1, line2, city, state, zip)
    state_and_zip = [state, zip.to_s].compact_blank.join(" ")
    [line1, line2, [city, state_and_zip].compact_blank.join(", ")].compact_blank
  end

  def request_display_qty(item_request)
    if item_request&.request_unit
      "#{item_request.quantity} #{item_request.request_unit.pluralize(item_request.quantity.to_i)}"
    else
      item_request&.quantity || ""
    end
  end
end
