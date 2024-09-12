# Configures a Prawn PDF template for generating Distribution manifests
class PicklistsPdf
  include Prawn::View
  include ItemsHelper

  def initialize(organization, requests)
    @requests = requests
    @organization = organization
  end

  def compute_and_render
    font_families["OpenSans"] = PrawnRails.config["font_families"][:OpenSans]
    font "OpenSans"
    font_size 10
    footer_height = 35

    @requests.each do |request|
      logo_image = if @organization.logo.attached?
        StringIO.open(@organization.logo.download)
      else
        Organization::DIAPER_APP_LOGO
      end

      # Bounding box containing non-footer elements
      bounding_box [bounds.left, bounds.top], width: bounds.width, height: bounds.height - footer_height do
        image logo_image, fit: [250, 85]

        bounding_box [bounds.right - 225, bounds.top], width: 225, height: 85 do
          text @organization.name, align: :right
          text @organization.address, align: :right
          text @organization.email, align: :right
        end

        text "Requested by:", style: :bold
        font_size 12
        text request.partner.name
        move_up 24

        text "Partner Primary Contact:", style: :bold, align: :right
        font_size 12
        text request.partner.profile.primary_contact_name, align: :right
        font_size 10
        text request.partner.profile.primary_contact_email, align: :right
        text request.partner.profile.primary_contact_phone, align: :right
        move_down 10

        if request.partner.profile.pick_up_name.present?
          move_up 10
          text "Partner Pickup Person:", style: :bold
          font_size 12
          text request.partner.profile.pick_up_name
          font_size 10
          text request.partner.profile.pick_up_email
          text request.partner.profile.pick_up_phone
          move_up 24

          text "Requested on:", style: :bold, align: :right
          font_size 12
          text request.created_at.to_fs(:date_picker), align: :right
          font_size 10
          move_down 30
        else
          text "Requested on:", style: :bold
          font_size 12
          text request.created_at.to_fs(:date_picker)
          font_size 10
        end

        if @organization.ytd_on_distribution_printout
          move_up 22
          text "Items Received Year-to-Date:", style: :bold, align: :right
          font_size 12
          text request.partner.quantity_year_to_date.to_s, align: :right
          font_size 10
        end

        move_down 10
        text "Comments:", style: :bold
        font_size 12
        text request.comments

        move_down 20

        items = request.item_requests
        data = has_custom_units?(items) ? data_with_units(items) : data_no_units(items)

        font_size 11

        # Line item table
        table(data, width: bounds.width, column_widths: {1 => 65, -2 => 35}) do
          self.header = true
          self.cell_style = {padding: [5, 10, 5, 10]}
          self.row_colors = %w[dddddd ffffff]

          cells.borders = []

          # Header row
          row(0).borders = [:bottom]
          row(0).border_width = 2
          row(0).font_style = :bold
          row(0).size = 10
          row(0).column(1..-1).borders = %i[bottom left]
        end
      end

      start_new_page unless request == @requests.last
    end

    repeat :all do
      # Page footer
      bounding_box [bounds.left, bounds.bottom + footer_height], width: bounds.width do
        stroke_bounds
        font "OpenSans"
        font_size 9
        stroke_horizontal_rule
        move_down 5

        logo_offset = (bounds.width - 190) / 2
        bounding_box([logo_offset, 0], width: 190, height: 33) do
          text "Lovingly created with", valign: :center
          image Organization::DIAPER_APP_LOGO, width: 75, vposition: :center, position: :right
        end
      end
    end

    number_pages "Page <page> of <total>",
      start_count_at: 1,
      at: [bounds.right - 130, 22],
      align: :right

    render
  end

  def has_custom_units?(items)
    Flipper.enabled?(:enable_packs) && items.any? { |item| item.request_unit }
  end

  def data_with_units(items)
    data = [["Items Requested",
      "Quantity",
      "Unit (if applicable)",
      "[X]",
      "Differences / Comments"]]

    data + items.map do |i|
      item_name = Item.find(i.item_id).name

      [item_name,
        i.quantity,
        i.request_unit&.capitalize&.pluralize(i.quantity),
        "[  ]",
        ""]
    end
  end

  def data_no_units(items)
    data = [["Items Requested",
      "Quantity",
      "[X]",
      "Differences / Comments"]]

    data + items.map do |i|
      item_name = Item.find(i.item_id).name

      [item_name,
        i.quantity,
        "[  ]",
        ""]
    end
  end
end
