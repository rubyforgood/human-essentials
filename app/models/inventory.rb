# == Schema Information
#
# Table name: inventories
#
#  id         :integer          not null, primary key
#  name       :string
#  address    :string
#  created_at :datetime
#  updated_at :datetime
#

class Inventory < ApplicationRecord
  belongs_to :organization
  
  has_many :inventory_items
  has_many :donations
  has_many :distributions
  has_many :items, through: :inventory_items

  validates :name, presence: true
  validates :address, presence: true

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
    donation.containers.each do |container|
      inventory_item = InventoryItem.find_or_create_by(inventory_id: self.id, item_id: container.item_id) do |inventory_item|
        inventory_item.quantity = 0
      end
      inventory_item.quantity += container.quantity rescue 0
      inventory_item.save
      log[container.item_id] = "+#{container.quantity}"
    end
    log
  end

  def distribute!(distribution)
    updated_quantities = {}
    insufficient_items = []
    distribution.containers.each do |container|
      inventory_item = self.inventory_items.find_by(item: container.item)
      next if inventory_item.nil? || inventory_item.quantity == 0
      if inventory_item.quantity >= container.quantity
        updated_quantities[inventory_item.id] = (updated_quantities[inventory_item.id] || inventory_item.quantity) - container.quantity
      else
        insufficient_items << {
          item_id: container.item.id,
          item_name: container.item.name,
          quantity_on_hand: inventory_item.quantity,
          quantity_requested: container.quantity
        }
      end
    end

    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "Distribution containers exceed the available inventory",
        insufficient_items)
    end

    update_inventory_inventory_items(updated_quantities)
  end

  # TODO - this action is happening in the Transfer model/controller - does this method belong here?
  def move_inventory!(transfer)
    updated_quantities = {}
    insufficient_items = []
    transfer.containers.each do |container|
      inventory_item = self.inventory_items.find_by(item: container.item)
      new_inventory_item = transfer.to.inventory_items.find_or_create_by(item: container.item)
      next if inventory_item.nil? || inventory_item.quantity == 0
      if inventory_item.quantity >= container.quantity
        updated_quantities[inventory_item.id] = (updated_quantities[inventory_item.id] || inventory_item.quantity) - container.quantity
        updated_quantities[new_inventory_item.id] = (updated_quantities[new_inventory_item.id] ||
          new_inventory_item.quantity) + container.quantity
      else
        insufficient_items << {
          item_id: container.item.id,
          item_name: container.item.name,
          quantity_on_hand: inventory_item.quantity,
          quantity_requested: container.quantity
        }
      end
    end

    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "Transfer containers exceed the available inventory",
        insufficient_items)
    end

    update_inventory_inventory_items(updated_quantities)
  end


  # TODO - this action is happening in the DistributionsController. Is this model the correct place for this method?
  def reclaim!(distribution)
    ActiveRecord::Base.transaction do
      distribution.containers.each do |container|
        inventory_item = self.inventory_items.find_by(item: container.item)
        inventory_item.update_attribute(:quantity, inventory_item.quantity + container.quantity)
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
