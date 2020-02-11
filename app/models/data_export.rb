require "csv"

# TODO: Move this out of models
# Encapsulates CSV Export logic into a single class. `SUPPORTED_TYPES` lists
# the classes for which this can work.
class DataExport
  SUPPORTED_TYPES = %w(
    Donation
    DonationSite
    Partner
    Purchase
    Distribution
    DiaperDriveParticipant
    Vendor
    StorageLocation
    Adjustment
    Transfer
    Item
    BarcodeItem
  ).map(&:freeze).freeze

  def initialize(organization, type)
    @current_organization = organization
    @type = type
  end

  def as_csv
    return nil unless current_organization.present? && type.present?
    return nil unless SUPPORTED_TYPES.include? type

    data_to_export = type.constantize.for_csv_export(current_organization)
    headers = type.constantize.csv_export_headers
    generate_csv(data_to_export, headers)
  end

  def self.supported_types
    SUPPORTED_TYPES
  end

  private

  attr_reader :current_organization, :type

  def generate_csv(data, headers)
    CSV.generate(headers: true) do |csv|
      csv << headers

      data.each do |element|
        csv << element.csv_export_attributes
      end
    end
  end
end
