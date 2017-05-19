# == Schema Information
#
# Table name: transfers
#
#  id         :integer          not null, primary key
#  from_id    :integer
#  to_id      :integer
#  comment    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Transfer < ApplicationRecord
  belongs_to :from, :class_name => 'Inventory', :foreign_key => :from_id
  belongs_to :to, :class_name => 'Inventory', :foreign_key => :to_id

  has_many :line_items, as: :itemizable, inverse_of: :itemizable
  has_many :items, through: :line_items
  accepts_nested_attributes_for :line_items,
    allow_destroy: true

  validates :from, :to, presence: true
  validates_associated :line_items
  validate :line_item_items_exist_in_inventory

  # TODO - this could probably be made an association method for the `line_items` association
  def quantities_by_category
    line_items.includes(:item).group("items.category").sum(:quantity)
  end

  # TODO - this could probably be made an association method for the `line_items` association
  def sorted_line_items
    line_items.includes(:item).order("items.name")
  end

  # TODO - this could probably be made an association method for the `line_items` association
  def total_quantity
    line_items.sum(:quantity)
  end

  private

  # TODO - this could probably be made an association method for the `line_items` association
  def line_item_items_exist_in_inventory
    self.line_items.each do |line_item|
      next unless line_item.item
      inventory_item = self.from.inventory_items.find_by(item: line_item.item)
      if inventory_item.nil?
        errors.add(:inventory,
                   "#{line_item.item.name} is not available " \
                   "at this storage location")
      end
    end
  end
end
