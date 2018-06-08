# == Schema Information
#
# Table name: adjustments
#
#  id                  :bigint(8)        not null, primary key
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
  include Filterable
  scope :at_location, ->(location_id) { where(storage_location_id: location_id) }

  validates :storage_location, :organization, presence: true
  validate :line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization

  def self.storage_locations_adjusted_for(organization)
    includes(:storage_location).where(organization_id: organization.id).collect(&:storage_location)
  end

  private

  def storage_locations_belong_to_organization
    return if organization.nil?

    unless organization.storage_locations.include?(storage_location)
      errors.add :storage_location, "storage location must belong to organization"
    end
  end
end
