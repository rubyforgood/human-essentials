# == Schema Information
#
# Table name: holdings
#
#  id           :integer          not null, primary key
#  quantity     :integer
#  created_at   :datetime
#  updated_at   :datetime
#  inventory_id :integer
#  item_id      :integer
#

class Holding < ActiveRecord::Base
  after_initialize :set_quantity

  belongs_to :inventory
  belongs_to :item

  validates :quantity, presence: true
  validates :inventory_id, presence: true
  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  def set_quantity
    self.quantity ||= 0
  end
end