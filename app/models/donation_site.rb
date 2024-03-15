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
  validates :contact_name, length: {minimum: 3}, allow_blank: true
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email format"}, allow_blank: true

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
    %w{Name Address Contact Name Email Phone}
  end

  def csv_export_attributes
    [name, address, contact_name, email, phone]
  end
end
