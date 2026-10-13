# The purchase record: what the bank bought, from whom, and what it cost.
#
# Deliberately the same document as the donation receipt -- same letterhead, same facts row, same
# table -- because a purchase and a donation are the same shape. What differs is what a purchase
# *is*, money going out to a vendor rather than goods coming in from a donor, so "Donation from"
# becomes "Purchased from" and "Money raised" becomes "Amount spent". See docs/design-decisions.md.
class PurchasePdf < ApplicationPdf
  attr_reader :purchase

  def initialize(organization, purchase)
    super(organization)
    @purchase = Purchase.includes(line_items: [:item]).find_by(id: purchase.id)
  end

  def template
    "pdfs/purchase"
  end

  def document_name
    "Purchase record"
  end

  def line_item_table
    data = purchase_data
    hide_columns(data)
    table_from(data, quantities: ["Quantity"])
  end

  def purchase_data
    data = [["Item", "Value per item", "In-kind value", "Quantity"]]
    data += purchase.line_items.sorted.map do |c|
      [c.item.name,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.quantity]
    end
    data + [["Total items purchased",
      "",
      dollar_value(purchase.value_per_itemizable),
      purchase.line_items.total]]
  end

  def hide_columns(data)
    column_names_to_hide.each do |col_name|
      col_index = data.first.find_index(col_name)
      data.each { |line| line.delete_at(col_index) } if col_index.present?
    end
  end

  private

  # The same organization setting the donation receipt honours: a bank that does not want values
  # printed does not want them printed here either.
  def column_names_to_hide
    columns_to_hide = []
    columns_to_hide.push("Value per item", "In-kind value") if organization.hide_value_columns_on_receipt
    columns_to_hide
  end
end
