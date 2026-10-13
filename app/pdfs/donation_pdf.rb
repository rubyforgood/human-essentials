# The donation receipt: what came in, from whom, and what it was worth.
class DonationPdf < ApplicationPdf
  # Who gave it, read off whichever source the donation names.
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
          @name = "Product Drive -- #{donation.product_drive.name}"
        end
      when Donation::SOURCES[:misc]
        @name = "Misc. Donation"
        @address = nil
        @email = nil
      end
    end
  end

  attr_reader :donation, :donor

  def initialize(organization, donation)
    super(organization)
    @donation = Donation.includes(line_items: [:item]).find_by(id: donation.id)
    @donor = DonorInfo.new(@donation)
  end

  def template
    "pdfs/donation"
  end

  def document_name
    "Donation receipt"
  end

  def money_raised
    return "$0.00" unless donation.money_raised&.positive?

    dollar_value(donation.money_raised)
  end

  def line_item_table
    data = donation_data
    hide_columns(data)
    table_from(data, quantities: ["Quantity"])
  end

  def donation_data
    data = [["Item",
      "Value per item",
      "In-kind value",
      "Quantity"]]
    data += donation.line_items.sorted.map do |c|
      [c.item.name,
        dollar_value(c.item.value_in_cents),
        dollar_value(c.value_per_line_item),
        c.quantity]
    end
    data + [["Total items received",
      "",
      dollar_value(donation.value_per_itemizable),
      donation.line_items.total]]
  end

  def hide_columns(data)
    column_names_to_hide.each do |col_name|
      col_index = data.first.find_index(col_name)
      data.each { |line| line.delete_at(col_index) } if col_index.present?
    end
  end

  private

  def column_names_to_hide
    columns_to_hide = []
    columns_to_hide.push("Value per item", "In-kind value") if organization.hide_value_columns_on_receipt
    columns_to_hide
  end
end
