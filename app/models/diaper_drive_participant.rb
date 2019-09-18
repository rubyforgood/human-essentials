# == Schema Information
#
# Table name: diaper_drive_participants
#
#  id              :integer          not null, primary key
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
  include Provideable
  include Geocodable

  has_many :donations, inverse_of: :diaper_drive_participant, dependent: :destroy

  validates :phone, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |ddp| ddp.email.blank? }
  validates :email, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |ddp| ddp.phone.blank? }

  scope :alphabetized, -> { order(:contact_name) }

  def volume
    donations.map { |d| d.line_items.total }.reduce(:+)
  end
end
