# == Schema Information
#
# Table name: kits
#
#  id                  :bigint           not null, primary key
#  name                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#  storage_location_id :integer
#
class Kit < ApplicationRecord
  has_many :kit_items
  has_many :items, through: :kit_items

  belongs_to :storage_location
  belongs_to :organization

  validates :storage_location, :organization, presence: true
end
