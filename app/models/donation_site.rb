# == Schema Information
#
# Table name: donation_sites
#
#  id              :integer          not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#  latitude        :float
#  longitude       :float

class DonationSite < ApplicationRecord
  require "csv"

  belongs_to :organization

  validates :name, :address, :organization, presence: true

  has_many :donations

  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .order(:name)
  }

  def self.import_csv(filename, organization)
    CSV.parse(filename, headers: true) do |row|
      loc = DonationSite.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end

  def self.csv_export_headers
    %w{Name Address}
  end

  def csv_export_attributes
    [name, address]
  end
end
