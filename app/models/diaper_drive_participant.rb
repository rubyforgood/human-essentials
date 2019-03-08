# == Schema Information
#
# Table name: diaper_drive_participants
#
#  id              :bigint(8)        not null, primary key
#  contact_name    :string
#  email           :string
#  phone           :string
#  comment         :string
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  address         :string
#  business_name   :string
#  latitude        :float
#  longitude       :float
#

class DiaperDriveParticipant < ApplicationRecord
  require "csv"

  belongs_to :organization # Automatically validates presence as of Rails 5
  has_many :donations, inverse_of: :diaper_drive_participant, dependent: :destroy

  validates :contact_name, presence: { message: "Must provide a name or a business name" }, if: proc { |ddp| ddp.business_name.blank? }
  validates :business_name, presence: { message: "Must provide a name or a business name" }, if: proc { |ddp| ddp.contact_name.blank? }
  validates :phone, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |ddp| ddp.email.blank? }
  validates :email, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |ddp| ddp.phone.blank? }

  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .order(:business_name)
  }

  def volume
    donations.map { |d| d.line_items.total }.reduce(:+)
  end

  def self.import_csv(csv, organization)
    csv.each do |row|
      loc = DiaperDriveParticipant.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end

  def self.csv_export_headers
    ["Business Name", "Contact Name", "Phone", "Email", "Total Diapers"]
  end

  def csv_export_attributes
    [
      business_name,
      contact_name,
      try(:phone) || "",
      try(:email) || "",
      volume
    ]
  end
end
