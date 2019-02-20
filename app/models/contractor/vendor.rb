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

class Vendor < Contractor
  has_many :purchases, inverse_of: :vendor, dependent: :destroy

  def volume
    purchases.map { |d| d.line_items.total }.reduce(:+)
  end
end
