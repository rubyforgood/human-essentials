# == Schema Information
#
# Table name: adjustments
#
#  id                  :integer          not null, primary key
#  organization_id     :integer
#  storage_location_id :integer
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Adjustment < ApplicationRecord
  belongs_to :organization
  belongs_to :storage_location

  include Itemizable

  validates :storage_location, :organization, presence: true
  validates_associated :line_items
  validate :line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization

  private

  def storage_locations_belong_to_organization
    return if self.organization.nil?

    if !self.organization.storage_locations.include?(self.storage_location)
      errors.add :storage_location, 'storage location must belong to organization'
    end
  end
end
