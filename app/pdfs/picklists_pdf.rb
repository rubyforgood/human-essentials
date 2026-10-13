# Picklists: one sheet per partner request, listing what to pull from the shelves, with a box to
# tick for each line and room to write down what was short or substituted.
#
# Takes a collection, so a batch prints as one PDF with each request starting on a new page.
class PicklistsPdf < ApplicationPdf
  attr_reader :requests

  def initialize(organization, requests)
    super(organization)
    @requests = requests
  end

  def template
    "pdfs/picklists"
  end

  def document_name
    "Picklist"
  end

  def line_item_table(request)
    line_items = request.item_requests
    has_custom_units?(line_items) ? data_with_units(line_items) : data_no_units(line_items)
  end

  def has_custom_units?(line_items)
    line_items.any?(&:request_unit)
  end

  def data_with_units(line_items)
    Table.new(
      [Column.new("Item", :text),
        Column.new("Quantity", :quantity),
        Column.new("Unit", :text),
        Column.new("Picked", :check),
        Column.new("Differences / comments", :write_in)],
      line_items.map do |line_item|
        [line_item.name,
          line_item.quantity,
          line_item.request_unit&.pluralize(line_item.quantity.to_i),
          nil,
          nil]
      end,
      nil
    )
  end

  def data_no_units(line_items)
    Table.new(
      [Column.new("Item", :text),
        Column.new("Quantity", :quantity),
        Column.new("Picked", :check),
        Column.new("Differences / comments", :write_in)],
      line_items.map { |line_item| [line_item.name, line_item.quantity, nil, nil] },
      nil
    )
  end

  # Shown only when the partner has a quota above zero.
  def quota_for(request)
    quota = request.partner.quota
    quota if quota&.positive?
  end
end
