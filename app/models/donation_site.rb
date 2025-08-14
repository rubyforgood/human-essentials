# == Schema Information
#
# Table name: donation_sites
#
#  id              :integer          not null, primary key
#  active          :boolean          default(TRUE)
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

  validates :name, :address, presence: true
  validates :name, uniqueness: {scope: :organization_id, message: "must be unique within the organization"}
  validates :contact_name, length: {minimum: 3}, allow_blank: true
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email format"}, allow_blank: true

  has_many :donations, dependent: :restrict_with_error

  include Geocodable
  include Exportable

  scope :active, -> { where(active: true) }

  scope :alphabetized, -> { order(:name) }

  def self.import_csv(csv, organization)
    errors = []
    warnings = []
    csv.each_with_index do |row, index|
      loc = DonationSite.new(row.to_hash)
      loc.organization_id = organization
      if loc.save
        Rails.logger.info "Successfully imported: #{loc.name}"
      else
        errors << "Row #{index + 2}, #{row.to_hash["name"]} - #{loc.errors.full_messages.join(", ")}"
      end
    end
    [errors, warnings]
  end

  def self.csv_export_headers
    ["Name", "Address", "Contact Name", "Email", "Phone"]
  end

  def csv_export_attributes
    [name, address, contact_name, email, phone]
  end

  def deactivate!
    update!(active: false)
  end

  def reactivate!
    update!(active: true)
  end
end
