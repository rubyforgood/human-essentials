# Configures a Prawn PDF template for generating Donation receipts
class DonationPdf
  include Prawn::View
  include ItemsHelper

  class DonorInfo
    attr_reader :name, :address, :email

    def initialize(donation)
      if donation.nil?
        raise "Must pass a Donation object"
      end
      case donation.source
      when Donation::SOURCES[:donation_site]
        @name = donation.donation_site.name
        @address = donation.donation_site.address
        @email = donation.donation_site.email
      when Donation::SOURCES[:manufacturer]
        @name = donation.manufacturer.name
        @address = nil
        @email = nil
      when Donation::SOURCES[:product_drive]
        if donation.product_drive_participant
          @name = donation.product_drive_participant.business_name
          @address = donation.product_drive_participant.address
          @email = donation.product_drive_participant.email
        else
          @name = donation.product_drive.name
        end
      when Donation::SOURCES[:misc]
        @name = "Misc. Donation"
        @address = nil
        @email = nil
      end
    end
  end

  def initialize(organization, donation)
    @donation = Donation.includes(line_items: [:item]).find_by(id: donation.id)
    @organization = organization
    @donor = DonorInfo.new(@donation)
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

      font_size 12
      text "Issued on:", style: :bold
      text @donation.issued_at.to_fs(:distribution_date)
      move_up 24

      font_size 12
      text "Donation from:", style: :bold, align: :right
      font_size 10
      text @donor.name, align: :right
      text @donor.address, align: :right
      text @donor.email, align: :right
      move_down 10
      # Get some additional vertical distance in left column if all donor info is nil
      if @donor.name.nil? && @donor.address.nil? && @donor.email.nil?
        move_down 10
      end

      font_size 12
      money_raised = "$0.00"
      if @donation.money_raised && @donation.money_raised > 0
        money_raised = dollar_value(@donation.money_raised)
      end
      text "<strong>Money Raised In Dollars: </strong>#{money_raised}", inline_format: true

      move_down 10
      font_size 12
      text "Comments:", style: :bold
      text @donation.comment

      move_down 20

      data = donation_data

      hide_columns(data)
      hidden_columns_length = column_names_to_hide.length

      font_size 11

      # Line item table
      table(data) do
        self.header = true
        self.cell_style = {
          padding: [5, 20, 5, 20]
        }
        self.row_colors = %w[dddddd ffffff]

        cells.borders = []

        # Header row
        row(0).borders = [:bottom]
        row(0).border_width = 2
        row(0).font_style = :bold
        row(0).size = 9
        row(0).column(1..-1).borders = %i[bottom left]

        # Total Items footer row
        row(-1).borders = [:top]
        row(-1).font_style = :bold
        row(-1).column(1..-1).borders = %i[top left]
        row(-1).column(1..-1).border_left_color = "aaaaaa"

        # Footer spacing row
        row(-2).borders = [:top]
        row(-2).padding = [2, 0, 2, 0]

        column(0).width = 190 + (hidden_columns_length * 60)

        # Quantity column
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

  def donation_data
    data = [["Items Received",
      "Value/item",
      "In-Kind Value",
      "Quantity"]]
    data += @donation.line_items.sorted.map do |c|
      [c.item.name,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.quantity]
    end
    data + [["", "", "", ""],
      ["Total Items Received",
        "",
        dollar_value(@donation.value_per_itemizable),
        @donation.line_items.total]]
  end

  def hide_columns(data)
    column_names_to_hide.each do |col_name|
      col_index = data.first.find_index(col_name)
      data.each { |line| line.delete_at(col_index) } if col_index.present?
    end
  end

  private

  def column_names_to_hide
    in_kind_column_name = "In-Kind Value"
    columns_to_hide = []
    columns_to_hide.push("Value/item", in_kind_column_name) if @organization.hide_value_columns_on_receipt
    columns_to_hide
  end
end
