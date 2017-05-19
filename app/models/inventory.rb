# == Schema Information
#
# Table name: inventories
#
#  id              :integer          not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

class Inventory < ApplicationRecord
  belongs_to :organization
  
  has_many :inventory_items
  has_many :donations
  has_many :distributions
  has_many :items, through: :inventory_items

  validates :name, :address, :organization, presence: true

  include Filterable
  scope :containing, ->(item_id) { joins(:inventory_items).where('inventory_items.item_id = ?', item_id) }

  def self.item_total(item_id)
    Inventory.select('quantity').joins(:inventory_items).where('inventory_items.item_id = ?', item_id).collect { |h| h.quantity }.reduce(:+)
  end

  def self.items_inventoried
    Item.joins(:inventories).group(:name)
  end

  def item_total(item_id)
    inventory_items.select(:quantity).find_by_item_id(item_id).try(:quantity)
  end

  def size
    inventory_items.sum(:quantity)
  end

  def intake!(donation)
    log = {}
    donation.line_items.each do |line_item|
      inventory_item = InventoryItem.find_or_create_by(inventory_id: self.id, item_id: line_item.item_id) do |inventory_item|
        inventory_item.quantity = 0
      end
      inventory_item.quantity += line_item.quantity rescue 0
      inventory_item.save
      log[line_item.item_id] = "+#{line_item.quantity}"
    end
    log
  end

  def distribute!(distribution)
    updated_quantities = {}
    insufficient_items = []
    distribution.line_items.each do |line_item|
      inventory_item = self.inventory_items.find_by(item: line_item.item)
      next if inventory_item.nil? || inventory_item.quantity == 0
      if inventory_item.quantity >= line_item.quantity
        updated_quantities[inventory_item.id] = (updated_quantities[inventory_item.id] || inventory_item.quantity) - line_item.quantity
      else
        insufficient_items << {
          item_id: line_item.item.id,
          item_name: line_item.item.name,
          quantity_on_hand: inventory_item.quantity,
          quantity_requested: line_item.quantity
        }
      end
    end

    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "Distribution line_items exceed the available inventory",
        insufficient_items)
    end

    update_inventory_inventory_items(updated_quantities)
  end

  # TODO - this action is happening in the Transfer model/controller - does this method belong here?
  def move_inventory!(transfer)
    updated_quantities = {}
    insufficient_items = []
    transfer.line_items.each do |line_item|
      inventory_item = self.inventory_items.find_by(item: line_item.item)
      new_inventory_item = transfer.to.inventory_items.find_or_create_by(item: line_item.item)
      next if inventory_item.nil? || inventory_item.quantity == 0
      if inventory_item.quantity >= line_item.quantity
        updated_quantities[inventory_item.id] = (updated_quantities[inventory_item.id] || inventory_item.quantity) - line_item.quantity
        updated_quantities[new_inventory_item.id] = (updated_quantities[new_inventory_item.id] ||
          new_inventory_item.quantity) + line_item.quantity
      else
        insufficient_items << {
          item_id: line_item.item.id,
          item_name: line_item.item.name,
          quantity_on_hand: inventory_item.quantity,
          quantity_requested: line_item.quantity
        }
      end
    end

    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "Transfer line_items exceed the available inventory",
        insufficient_items)
    end

    update_inventory_inventory_items(updated_quantities)
  end


  # TODO - this action is happening in the DistributionsController. Is this model the correct place for this method?
  def reclaim!(distribution)
    ActiveRecord::Base.transaction do
      distribution.line_items.each do |line_item|
        inventory_item = self.inventory_items.find_by(item: line_item.item)
        inventory_item.update_attribute(:quantity, inventory_item.quantity + line_item.quantity)
      end
    end
    distribution.destroy
  end

  private

  def update_inventory_inventory_items(records)
    ActiveRecord::Base.transaction do
      records.each do |inventory_item_id, quantity|
        InventoryItem.find(inventory_item_id).update_attribute("quantity", quantity)
      end
    end
  end

end
