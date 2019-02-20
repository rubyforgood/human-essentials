# == Schema Information
#
# Table name: contractors
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
#  type            :string           default("DiaperDriveParticipant")
#

class DiaperDriveParticipant < Contractor
  has_many :donations, inverse_of: :diaper_drive_participant, dependent: :destroy

  def volume
    donations.map { |d| d.line_items.total }.reduce(:+)
  end
end
