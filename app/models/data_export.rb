require 'csv'

class DataExport
  def initialize(organization, type)
    @current_organization = organization
    @type = type
  end

  def as_csv
    return nil unless current_organization.present? && type.present?
    
    data_to_export = grab_data_to_export
    headers = grab_headers_to_export
    generate_csv(data_to_export, headers)
  end

  private

  attr_reader :current_organization, :type

  def grab_data_to_export
    case type
    when "donations"
      current_organization.donations
                          .includes(:line_items, :storage_location, :donation_site, :diaper_drive_participant)
                          .order(created_at: :desc)
    when "donation_sites"
      current_organization.donation_sites.all.order(:name)
    when "partner_agencies"
      current_organization.purchases
                          .includes(:line_items, :storage_location)
                          .order(created_at: :desc)
    else
      []
    end
  end

  def grab_headers_to_export
    case type
    when "donations"
      Donation.csv_export_headers
    when "donation_sites"
      DonationSite.csv_export_headers
    when "partner_agencies"
      Partner.csv_export_headers
    when "purchases"
      Purchase.csv_export_headers
    else
      []
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
