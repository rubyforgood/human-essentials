# == Schema Information
#
# Table name: product_drive_participants
#
#  id              :integer          not null, primary key
#  address         :string
#  business_name   :string
#  comment         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class ProductDriveParticipant < ApplicationRecord
  has_paper_trail
  include Provideable
  include Geocodable

  has_many :donations, inverse_of: :product_drive_participant, dependent: :destroy

  validates :phone, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |pdp| pdp.email.blank? }
  validates :email, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |pdp| pdp.phone.blank? }
  validates :comment, length: { maximum: 500 }

  scope :alphabetized, -> { order(:contact_name) }

  def volume
    donations.map { |d| d.line_items.total }.reduce(:+)
  end

  def volume_by_product_drive(product_drive_id)
    donations.by_product_drive(product_drive_id).map { |d| d.line_items.total }.sum
  end

  def donation_source_view
    return if contact_name.blank?

    "#{contact_name} (participant)"
  end
end
