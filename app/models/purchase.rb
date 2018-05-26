# == Schema Information
#
# Table name: purchases
#
#  id                  :bigint(8)        not null, primary key
#  purchased_from      :string
#  comment             :text
#  organization_id     :integer
#  storage_location_id :integer
#  amount_spent        :integer
#  issued_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Purchase < ApplicationRecord

  belongs_to :organization
  belongs_to :storage_location

  include Itemizable
  include Filterable
  include IssuedAt

  scope :at_storage_location, ->(storage_location_id) { where(storage_location_id: storage_location_id) }
  scope :purchased_from, ->(purchased_from) { where(purchased_from: purchased_from) }
  scope :during, ->(range) { where(purchases: { issued_at: range }) }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }

  before_create :combine_duplicates
  before_destroy :remove_inventory

  validates_numericality_of :amount_spent, greater_than: 0

  def storage_view
    storage_location.nil? ? "N/A" : storage_location.name
  end

  def remove_inventory
    storage_location.remove!(self)
  end

  def track(item,quantity)
    if contains_item_id?(item.id)
      update_quantity(quantity, item)
    else
      LineItem.create(itemizable: self, item_id: item.id, quantity: quantity)
    end
  end

  def contains_item_id? id
    line_items.find_by(item_id: id).present?
  end

  def total_quantity
    self.line_items.sum(:quantity)
  end

  def remove(item)
    # doing this will handle either an id or an object
    item_id = item.to_i
    line_item = self.line_items.find_by(item_id: item_id)
    if (line_item)
      line_item.destroy
    end
  end

  # Use a negative quantity to subtract inventory
  def update_quantity(quantity, item)
    item_id = item.to_i
    line_item = self.line_items.find_by(item_id: item_id)
    line_item.quantity += quantity
    # Inventory can never be negative
    line_item.quantity = 0 if line_item.quantity < 0
    line_item.save
  end

  private
  def combine_duplicates
    Rails.logger.info "Combining!"
    self.line_items.combine!
  end
end
