require "csv"
# Encapsulates some common behaviors for third-parties that provide inventory
# e.g. ProductDriveParticipant, Vendor
module Provideable
  include Exportable
  extend ActiveSupport::Concern

  included do
    belongs_to :organization # Automatically validates presence as of Rails 5

    def self.import_csv(csv, organization)
      csv.each do |row|
        loc = new(row.to_hash)
        loc.organization_id = organization

        loc.save!
      end
      [[], []]
    end

    def self.csv_export_headers
      ["Business Name", "Contact Name", "Phone", "Email", "Total Diapers"]
    end

    def csv_export_attributes
      [business_name,
       contact_name,
       try(:phone) || "",
       try(:email) || "",
       volume]
    end
  end
end
