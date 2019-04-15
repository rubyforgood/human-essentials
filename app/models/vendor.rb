# == Schema Information
#
# Table name: vendors
#
#  id              :bigint(8)        not null, primary key
#  contact_name    :string
#  email           :string
#  phone           :string
#  comment         :string
#  organization_id :integer
#  address         :string
#  business_name   :string
#  latitude        :float
#  longitude       :float
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Vendor < ApplicationRecord
  include Provideable
  include Geocodable

  has_many :purchases, inverse_of: :vendor, dependent: :destroy

  def volume
    purchases.map { |d| d.line_items.total }.reduce(:+)
  end
end
