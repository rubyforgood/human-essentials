# == Schema Information
#
# Table name: donation_sites
#
#  id              :integer          not null, primary key
#  address         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  name            :string
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class DonationSite < ApplicationRecord
  has_paper_trail
  require "csv"

  belongs_to :organization

  validates :name, :address, :organization, presence: true
  validates :phone, presence: {message: "Must provide a phone or an email"}, if: proc { |ds| ds.email.blank? }
  validates :email, presence: {message: "Must provide a phone or an email"}, if: proc { |ds| ds.phone.blank? }

  has_many :donations, dependent: :destroy

  include Geocodable
  include Exportable

  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .order(:name)
  }
  scope :alphabetized, -> { order(:name) }

  def self.import_csv(csv, organization)
    csv.each do |row|
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
