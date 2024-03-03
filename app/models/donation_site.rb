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

  validates :name, :address, :contact_name, :organization, presence: true
  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :phone, presence: true, format: {with: /\A\+?[\d\s\-]+\z/, message: "must be a valid phone number"}

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
