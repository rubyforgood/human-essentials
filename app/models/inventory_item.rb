# == Schema Information
#
# Table name: inventory_items
#
#  id                  :integer          not null, primary key
#  quantity            :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  item_id             :integer
#  storage_location_id :integer
#

class InventoryItem < ApplicationRecord
  MAX_INT = 2**31

  belongs_to :storage_location
  belongs_to :item

  validates :quantity, presence: true
  validates :storage_location_id, presence: true
  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: MAX_INT }

  scope :by_partner_key, ->(partner_key) { joins(:item).merge(Item.by_partner_key(partner_key)) }
  scope :active, -> { joins(:item).where(items: { active: true }) }

  delegate :name, to: :item, prefix: true
end
