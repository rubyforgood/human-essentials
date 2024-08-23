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
  has_paper_trail
  MAX_INT = 2**31

  EARLIEST_VERSION = "2021-08-02"

  belongs_to :storage_location
  belongs_to :item

  validates :quantity, presence: true
  validates :storage_location_id, presence: true
  validates :item_id, presence: true

  scope :by_partner_key, ->(partner_key) { joins(:item).merge(Item.by_partner_key(partner_key)) }
  scope :active, -> { joins(:item).where(items: { active: true }) }
  scope :inactive, -> { joins(:item).where(items: { active: false }) }

  delegate :name, to: :item, prefix: true

  def to_h
    { item_id: item_id, quantity: quantity, item_name: item.name }.stringify_keys
  end

end
