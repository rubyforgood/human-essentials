require "csv"

# TODO: Move this out of models
# Encapsulates CSV Export logic into a single class. `SUPPORTED_TYPES` lists
# the classes for which this can work.
class DataExport
  SUPPORTED_TYPES = %w(
    Adjustment
    BarcodeItem
    DiaperDriveParticipant
    Distribution
    Donation
    DonationSite
    Item
    Partner
    PartnerDistribution
    Purchase
    Request
    StorageLocation
    Transfer
    Vendor
  ).map(&:freeze).freeze

  def initialize(organization, type, filters, date_range)
    @current_organization = organization
    @type = type
    @filters = filters
    @date_range = date_range
  end

  def as_csv
    return nil unless current_organization.present? && type.present?
    return nil unless SUPPORTED_TYPES.include? type

    generate_csv
  end

  def self.supported_types
    SUPPORTED_TYPES
  end

  private

  attr_reader :current_organization, :type, :filters, :date_range

  def exportable
    @exportable ||= type.constantize
  end

  def model_class
    @model_class ||= type.constantize
  end

  def data_to_export
    exportable.for_csv_export(current_organization, filters, date_range)
  end

  def generate_csv
    CSV.generate(headers: true) do |csv|
      model_class.csv_export(data_to_export).each do |row|
        csv << row
      end
    end
  end
end
