# == Schema Information
#
# Table name: inventory_item
#
#  id                  :integer          not null, primary key
#  quantity            :integer
#  created_at          :datetime
#  updated_at          :datetime
#  storage_location_id :integer
#  item_id             :integer
#

class InventoryItem < ApplicationRecord
  after_initialize :set_quantity

  belongs_to :storage_location
  belongs_to :item

  validates :quantity, presence: true
  validates :storage_location_id, presence: true
  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  # TODO - is there a reason for doing this instead of setting a DB default?
  def set_quantity
    self.quantity ||= 0
  end
end
