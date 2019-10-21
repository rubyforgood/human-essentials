# Configures a Prawn PDF template for generating Distribution manifests
class DistributionPdf
  include Prawn::View
  include ItemsHelper

  def initialize(organization, distribution)
    @distribution = distribution
    font_families["OpenSans"] = PrawnRails.config["font_families"][:OpenSans]
    font "OpenSans"
    font_size 10

    image organization.logo_path, fit: [325, 110]

    bounding_box [bounds.right - 225, bounds.top], width: 225, height: 50 do
      text organization.name, align: :right
      text organization.address, align: :right
      text organization.email, align: :right
    end

    text "Issued to:", style: :bold, align: :right
    font_size 12
    text @distribution.partner.name, align: :right
    font_size 10
    move_down 10

    text "Issued on:", style: :bold, align: :right
    font_size 12
    text @distribution.distributed_at, align: :right
    font_size 10
    move_down 10

    text "Items Received Year-to-Date:", style: :bold, align: :right
    font_size 12
    text @distribution.partner.quantity_year_to_date.to_s, align: :right
    font_size 10
    move_up 10

    text "Comments:", style: :bold
    font_size 12
    text @distribution.comment

    move_down 20

    data = [["Items Received", "Value/item", "In-Kind Value", "Quantity", "Packages"]]
    data += @distribution.line_items.sorted.map do |c|
      [c.item.name, item_value(c.item.value_in_cents), item_value(c.value_per_line_item), c.quantity, c.package_count]
    end
    data += [["", "", "", "", ""], ["Total Items Received", "", item_value(@distribution.value_per_itemizable), @distribution.line_items.total, ""]]

    font_size 11
    # Line item table
    table(data) do
      self.header = true
      self.cell_style = {
        padding: [5, 20, 5, 20]
      }
      self.row_colors = %w(dddddd ffffff)

      cells.borders = []

      # Header row
      row(0).borders = [:bottom]
      row(0).border_width = 2
      row(0).font_style = :bold
      row(0).size = 9
      row(0).column(1..-1).borders = %i(bottom left)

      # Total Items footer row
      row(-1).borders = [:top]
      row(-1).font_style = :bold
      row(-1).column(1..-1).borders = %i(top left)
      row(-1).column(1..-1).border_left_color = "aaaaaa"

      # Footer spacing row
      row(-2).borders = [:top]
      row(-2).padding = [2, 0, 2, 0]

      column(0).width = 190

      # Quantity column
      column(1..-1).row(1..-3).borders = [:left]
      column(1..-1).row(1..-3).border_left_color = "aaaaaa"
      column(1).style align: :right
    end

    number_pages "Page <page> of <total>",
                 start_count_at: 1,
                 at: [bounds.right - 130, 22],
                 align: :right

    repeat :all do
      # Page footer
      bounding_box [bounds.left, bounds.bottom + 35], width: bounds.width do
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
  end
end
