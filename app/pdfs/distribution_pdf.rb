# Configures a Prawn PDF template for generating Distribution manifests
class DistributionPdf
  include Prawn::View
  include ItemsHelper

  def initialize(organization, distribution)
    @distribution = Distribution.includes(:partner, line_items: [:item]).find_by(id: distribution.id)
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

    # Bounding box containing non-footer elements
    bounding_box [bounds.left, bounds.top], width: bounds.width, height: bounds.height - footer_height do
      image logo_image, fit: [250, 85]

      bounding_box [bounds.right - 225, bounds.top], width: 225, height: 85 do
        text @organization.name, align: :right
        text @organization.address, align: :right
        text @organization.email, align: :right
      end

      text "Issued to:", style: :bold
      font_size 12
      text @distribution.partner.name
      move_up 24

      text "Partner Primary Contact:", style: :bold, align: :right
      font_size 12
      text @distribution.partner.profile.primary_contact_name, align: :right
      font_size 10
      text @distribution.partner.profile.primary_contact_email, align: :right
      text @distribution.partner.profile.primary_contact_phone, align: :right
      move_down 10

      if %w(shipped delivered).include?(@distribution.delivery_method)
        move_up 10
        text "Delivery address:", style: :bold
        font_size 10
        text @distribution.partner.profile.address1
        text @distribution.partner.profile.address2
        text @distribution.partner.profile.city
        text @distribution.partner.profile.state
        text @distribution.partner.profile.zip_code
        move_up 40

        text "Issued on:", style: :bold, align: :right
        font_size 12
        text @distribution.distributed_at, align: :right
        font_size 10
        move_down 30
      else
        text "Issued on:", style: :bold
        font_size 12
        text @distribution.distributed_at
        font_size 10
      end

      if @organization.ytd_on_distribution_printout
        move_up 22
        text "Items Received Year-to-Date:", style: :bold, align: :right
        font_size 12
        text @distribution.partner.quantity_year_to_date.to_s, align: :right
        font_size 10
      end

      move_down 10
      text "Comments:", style: :bold
      font_size 12
      text @distribution.comment

      move_down 20

      data = @distribution.request ? request_data : non_request_data
      has_request = @distribution.request.present?

      hide_columns(data)
      hidden_columns_length = column_names_to_hide.length

      font_size 11

      # Line item table
      table(data) do
        self.header = true
        self.cell_style = {
          padding: has_request ? [5, 10, 5, 10] : [5, 20, 5, 20]
        }
        self.row_colors = %w(dddddd ffffff)

        cells.borders = []

        # Header row
        row(0).borders = [:bottom]
        row(0).border_width = 2
        row(0).font_style = :bold
        row(0).size = has_request ? 8 : 9
        row(0).column(1..-1).borders = %i(bottom left)

        # Total Items footer row
        row(-1).borders = [:top]
        row(-1).font_style = :bold
        row(-1).column(1..-1).borders = %i(top left)
        row(-1).column(1..-1).border_left_color = "aaaaaa"

        # Footer spacing row
        row(-2).borders = [:top]
        row(-2).padding = [2, 0, 2, 0]

        column(0).width = 190 + (hidden_columns_length * 60)

        # Quantity column
        column(1..-1).row(1..-3).borders = [:left]
        column(1..-1).row(1..-3).border_left_color = "aaaaaa"
        column(1).style align: :right
        column(-1).row(-1).borders = [:left, :bottom]
      end

      if @organization.signature_for_distribution_pdf
        insert_signature_fields
      end
    end

    number_pages "Page <page> of <total>",
                 start_count_at: 1,
                 at: [bounds.right - 130, 22],
                 align: :right

    repeat :all do
      # Page footer
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

  def request_data
    data = [["Items Received",
      "Requested",
      "Received",
      "Value/item",
      "In-Kind Value Received",
      "Packages"]]

    inventory = nil
    if Event.read_events?(@distribution.organization)
      inventory = View::Inventory.new(@distribution.organization_id)
    end
    request_items = @distribution.request.request_items.map do |request_item|
      RequestItem.from_json(request_item, @distribution.request, inventory)
    end
    line_items = @distribution.line_items.sorted

    requested_not_received = request_items.select do |request_item|
      line_items.none? { |i| i.item_id == request_item.item.id }
    end

    data += line_items.map do |c|
      request_item = request_items.find { |i| i.item.id == c.item_id }
      [c.item.name,
        request_item&.quantity || "",
        c.quantity,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.package_count]
    end

    data += requested_not_received.sort_by(&:name).map do |c|
      [c.item.name,
        c.quantity,
        "",
        dollar_value(c.item.value_in_cents),
        nil,
        nil]
    end

    data + [["", "", "", "", ""],
      ["Total Items Received",
        request_items.map(&:quantity).sum,
        @distribution.line_items.total,
        "",
        dollar_value(@distribution.value_per_itemizable),
        ""]]
  end

  def non_request_data
    data = [["Items Received",
      "Value/item",
      "In-Kind Value",
      "Quantity",
      "Packages"]]
    data += @distribution.line_items.sorted.map do |c|
      [c.item.name,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.quantity,
        c.package_count]
    end
    data + [["", "", "", "", ""],
      ["Total Items Received",
        "",
        dollar_value(@distribution.value_per_itemizable),
        @distribution.line_items.total,
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
    in_kind_column_name = @distribution.request.present? ? "In-Kind Value Received" : "In-Kind Value"
    columns_to_hide = []
    columns_to_hide.push("Value/item", in_kind_column_name) if @organization.hide_value_columns_on_receipt
    columns_to_hide.push("Packages") if @organization.hide_package_column_on_receipt
    columns_to_hide
  end

  def insert_signature_fields
    minimum_space_required = 165
    # Signatures lines shouldn't be separated by a page break, so if we can't fit both lines together we make a new page
    if cursor < minimum_space_required
      start_new_page
    else
      move_down 20
    end

    signature_lines_for "Received By:"

    move_down 20
    signature_lines_for "Delivered By:"
  end

  def signature_lines_for(label)
    # Calculate half the screen width and the gap between the two signature lines
    half_width = bounds.width / 2
    gap = 20
    left_end = half_width - (gap / 2)
    right_start = half_width + (gap / 2)

    text label, style: :bold
    move_down 30
    stroke do
      horizontal_line 0, left_end
      horizontal_line right_start, bounds.width
    end

    move_down 10
    draw_text "(Print Name)", at: [0, cursor]
    draw_text "(Signature and Date)", at: [right_start, cursor]
  end
end
