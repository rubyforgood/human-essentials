# Configures a Prawn PDF template for generating Purchase records.
#
# The purchase counterpart to DonationPdf. Donations have had a printable receipt since long before
# the design system migration and purchases have not, which was half of an asymmetry between two
# pages that are otherwise the same shape -- see docs/design-decisions.md.
#
# Deliberately the same document as a donation receipt: same logo block, same organization block,
# same line item table, same footer. What differs is what a purchase *is* -- money going out to a
# vendor rather than goods coming in from a donor -- so "Donation from" becomes "Purchased from"
# and "Money Raised" becomes "Amount spent".
class PurchasePdf
  include Prawn::View
  include ItemsHelper

  def initialize(organization, purchase)
    @purchase = Purchase.includes(line_items: [:item]).find_by(id: purchase.id)
    @organization = organization
  end

  def compute_and_render
    font_families["OpenSans"] = PrawnRails.config["font_families"][:OpenSans]
    font "OpenSans"
    font_size 10

    logo_image = if @organization.logo.attached?
      StringIO.open(@organization.logo.download)
    else
      Organization::DIAPER_APP_LOGO
    end

    footer_height = 35

    bounding_box [bounds.left, bounds.top], width: bounds.width, height: bounds.height - footer_height do
      image logo_image, fit: [250, 85]

      bounding_box [bounds.right - 225, bounds.top], width: 225, height: 85 do
        text @organization.name, align: :right
        text @organization.address, align: :right
        text @organization.email, align: :right
      end

      font_size 12
      text "Issued on:", style: :bold
      text @purchase.issued_at.to_fs(:distribution_date)
      move_up 24

      font_size 12
      text "Purchased from:", style: :bold, align: :right
      font_size 10
      text @purchase.purchased_from_view, align: :right
      move_down 20

      font_size 12
      text "<strong>Amount spent: </strong>#{dollar_value(@purchase.amount_spent_in_cents)}",
        inline_format: true

      if @purchase.storage_location
        move_down 4
        text "<strong>Storage location: </strong>#{@purchase.storage_location.name}", inline_format: true
      end

      move_down 10
      font_size 12
      text "Comments:", style: :bold
      text @purchase.comment

      move_down 20

      data = purchase_data
      hide_columns(data)
      hidden_columns_length = column_names_to_hide.length

      font_size 11

      table(data) do
        self.header = true
        self.cell_style = {padding: [5, 20, 5, 20]}
        self.row_colors = %w[dddddd ffffff]

        cells.borders = []

        row(0).borders = [:bottom]
        row(0).border_width = 2
        row(0).font_style = :bold
        row(0).size = 9
        row(0).column(1..-1).borders = %i[bottom left]

        row(-1).borders = [:top]
        row(-1).font_style = :bold
        row(-1).column(1..-1).borders = %i[top left]
        row(-1).column(1..-1).border_left_color = "aaaaaa"

        row(-2).borders = [:top]
        row(-2).padding = [2, 0, 2, 0]

        column(0).width = 190 + (hidden_columns_length * 60)

        column(1..-1).row(1..-3).borders = [:left]
        column(1..-1).row(1..-3).border_left_color = "aaaaaa"
        column(1).style align: :right
      end
    end

    number_pages "Page <page> of <total>",
      start_count_at: 1,
      at: [bounds.right - 130, 22],
      align: :right

    repeat :all do
      bounding_box [bounds.left, bounds.bottom + footer_height], width: bounds.width do
        stroke_bounds
        font "OpenSans"
        font_size 9
        stroke_horizontal_rule
        move_down(5)

        logo_offset = (bounds.width - 190) / 2
        bounding_box([logo_offset, 0], width: 190, height: 33) do
          text "Lovingly created with", valign: :center
          image Organization::DIAPER_APP_LOGO, width: 75, vposition: :center, position: :right
        end
      end
    end

    render
  end

  def purchase_data
    data = [["Items Purchased", "Value/item", "In-Kind Value", "Quantity"]]
    data += @purchase.line_items.sorted.map do |c|
      [c.item.name,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.quantity]
    end
    data + [["", "", "", ""],
      ["Total Items Purchased",
        "",
        dollar_value(@purchase.value_per_itemizable),
        @purchase.line_items.total]]
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
    columns_to_hide.push("Value/item", "In-Kind Value") if @organization.hide_value_columns_on_receipt
    columns_to_hide
  end
end
