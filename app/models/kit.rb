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
  include Itemizable

  belongs_to :storage_location
  belongs_to :organization

  validates :storage_location, :organization, presence: true
  validate :can_build_kit?

  delegate :inventory_items, to: :storage_location

  def can_build_kit?
    grouped_inventory_items = inventory_items.group_by(&:item_id)
    line_items.each do |line_item|
      inventory_item = grouped_inventory_items[line_item.item_id]&.first
      next if inventory_item.quantity > line_item.quantity
      self.errors.add(:base, "Not enough #{line_item.item.name} to build kit")
    end
  end
end
