# == Schema Information
#
# Table name: inventory_items
#
#  id                  :bigint(8)        not null, primary key
#  storage_location_id :integer
#  item_id             :integer
#  quantity            :integer          default(0)
#  created_at          :datetime
#  updated_at          :datetime
#

class InventoryItem < ApplicationRecord
  belongs_to :storage_location
  belongs_to :item

  validates :quantity, presence: true
  validates :storage_location_id, presence: true
  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :by_partner_key, ->(partner_key) { joins(:item).merge(Item.by_partner_key(partner_key)) }

  delegate :name, to: :item, prefix: true
end
