require "csv"

class DataExport
  SUPPORTED_TYPES = %w(
    Donation
    DonationSite
    Partner
    Purchase
    Distribution
    DiaperDriveParticipant
    StorageLocation
    Adjustment
    Transfer
    Item
    BarcodeItem
  ).freeze

  def initialize(organization, type)
    @current_organization = organization
    @type = type
  end

  def as_csv
    return nil unless current_organization.present? && type.present?
    return nil unless SUPPORTED_TYPES.include? type

    data_to_export = grab_data_to_export
    headers = type.constantize.csv_export_headers
    generate_csv(data_to_export, headers)
  end

  private

  attr_reader :current_organization, :type

  def grab_data_to_export
    case type
    when "Donation"
      current_organization.donations
                          .includes(:line_items, :storage_location, :donation_site)
                          .order(created_at: :desc)
    when "DonationSite"
      current_organization.donation_sites.all.order(:name)
    when "Purchase"
      current_organization.purchases
                          .includes(:line_items, :storage_location)
                          .order(created_at: :desc)
    when "Partner"
      current_organization.partners.order(:name)
    when "Distribution"
      current_organization.distributions
                          .includes(:partner, :storage_location, :line_items)
    when "DiaperDriveParticipant"
      current_organization.diaper_drive_participants.order(:name)
    when "StorageLocation"
      current_organization.storage_locations
    when "Adjustment"
      current_organization.adjustments
                          .includes(:storage_location, :line_items)
    when "Transfer"
      current_organization.transfers
                          .includes(:line_items, :from, :to)
    when "Item"
      current_organization.items.includes(:canonical_item).alphabetized
    when "BarcodeItem"
      current_organization.barcode_items.includes(:barcodeable)
    end
  end

  def generate_csv(data, headers)
    CSV.generate(headers: true) do |csv|
      csv << headers

      data.each do |element|
        csv << element.csv_export_attributes
      end
    end
  end
end
