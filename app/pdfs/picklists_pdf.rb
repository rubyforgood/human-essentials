# Configures a Prawn PDF template for generating Distribution manifests
class PicklistsPdf
  include Prawn::View
  include ItemsHelper

  def initialize(organization, requests)
    @requests = requests # does this need to be Request.includes(XXX).etc? Investigate.
    @organization = organization
    @request = @requests.first # temporary for single picklist only
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

      text "Requested by:", style: :bold
      font_size 12
      text @request.partner.name
      move_up 24

      text "Partner Primary Contact:", style: :bold, align: :right
      font_size 12
      text @request.partner.profile.primary_contact_name, align: :right
      font_size 10
      text @request.partner.profile.primary_contact_email, align: :right
      text @request.partner.profile.primary_contact_phone, align: :right
      move_down 10

      if @request.partner.profile.pick_up_name.present?
        move_up 10
        text "Partner Pickup Person:", style: :bold
        font_size 12
        text @request.partner.profile.pick_up_name
        font_size 10
        text @request.partner.profile.pick_up_email
        text @request.partner.profile.pick_up_phone
        move_up 24

        text "Requested on:", style: :bold, align: :right
        font_size 12
        text @request.created_at.to_fs(:date_picker), align: :right
        font_size 10
        move_down 30
      else
        text "Requested on:", style: :bold
        font_size 12
        text @request.created_at.to_fs(:date_picker)
        font_size 10
      end

      if @organization.ytd_on_distribution_printout
        move_up 22
        text "Items Received Year-to-Date:", style: :bold, align: :right
        font_size 12
        text @request.partner.quantity_year_to_date.to_s, align: :right
        font_size 10
      end

      move_down 10
      text "Comments:", style: :bold
      font_size 12
      text @request.comments

      move_down 20

      data = request_data

      font_size 11

      # Line item table
      table(data) do
        self.header = true
        self.cell_style = { padding: [5, 20, 5, 20]}
        self.row_colors = %w(dddddd ffffff)

        cells.borders = []

         # Header row
         row(0).borders = [:bottom]
         row(0).border_width = 2
         row(0).font_style = :bold
         row(0).size = 10
         row(0).column(1..-1).borders = %i(bottom left)
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
        move_down 5

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
    data = [["Items Requested",
      "Quantity",
      "[X]",
      "Differences / Comments"]]

    request = @requests.first
    request_items = request.request_items.map do |request_item|
      RequestItem.from_json(request_item, request)
    end

    data + request_items.map do |request_item|
      [request_item.item.name,
        request_item.quantity,
        "[  ]",
        ""]
    end
  end
end

  
