# == Schema Information
#
# Table name: inventory_items
#
#  id           :integer          not null, primary key
#  inventory_id :integer
#  item_id      :integer
#  quantity     :integer
#  created_at   :datetime
#  updated_at   :datetime
#

class InventoryItem < ApplicationRecord
  after_initialize :set_quantity

  belongs_to :inventory
  belongs_to :item

  validates :quantity, presence: true
  validates :inventory_id, presence: true
  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  # TODO - is there a reason for doing this instead of setting a DB default?
  def set_quantity
    self.quantity ||= 0
  end
end
