# == Schema Information
#
# Table name: diaper_drive_participants
#
#  id              :integer          not null, primary key
#  name            :string
#  contact_name    :string
#  email           :string
#  phone           :string
#  comment         :string
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  address         :string
#  business_name   :string
#

class DiaperDriveParticipant < ApplicationRecord
  require 'csv'

  belongs_to :organization  # Automatically validates presence as of Rails 5
  has_many :donations, inverse_of: :diaper_drive_participant

  validates :name, presence: true
  validates :phone, presence: { message: "Must provide a phone or an e-mail" }, if: Proc.new { |ddp| ddp.email.blank? }
  validates :email, presence: { message: "Must provide a phone or an e-mail" }, if: Proc.new { |ddp| ddp.phone.blank? }

  # TODO - This should be set up with a callback to cache the total so we're not hitting the DB
  def volume
    donations.map { |d| d.line_items.total }.reduce(:+)
  end
  
  def self.import_csv(filename,organization)
    CSV.parse(filename, :headers => true) do |row|
      loc = DiaperDriveParticipant.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end  
end
