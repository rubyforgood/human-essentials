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

class Inventory < ActiveRecord::Base
  has_many :holdings
  has_many :donations
  has_many :tickets
  has_many :items, through: :holdings

  validates :name, presence: true
  validates :address, presence: true

  def self.item_total(item_id)
    Inventory.select('quantity').joins(:holdings).where('holdings.item_id = ?', item_id).collect { |h| h.quantity }.reduce(:+)
  end

  def item_total(item_id)
    holdings.select(item_id: item_id).first.quantity
  end

  def size
    holdings.collect { |h| h.quantity }.reduce(:+)
  end

  def intake!(donation)
    log = {}
    donation.containers.each do |container|
      holding = Holding.find_or_create_by(inventory_id: self.id, item_id: container.item_id) do |holding|
        holding.quantity = 0
      end
      holding.quantity += container.quantity rescue 0
      holding.save
      log[container.item_id] = "+#{container.quantity}"
    end
    log
  end

  def distribute!(ticket)
    updated_quantities = {}
    insufficient_items = []
    ticket.containers.each do |container|
      holding = self.holdings.find_by(item: container.item)
      next if holding.nil? || holding.quantity == 0
      if holding.quantity >= container.quantity
        updated_quantities[holding.id] = (updated_quantities[holding.id] || holding.quantity) - container.quantity
      else
        insufficient_items << {
          item_id: container.item.id,
          item_name: container.item.name,
          quantity_on_hand: holding.quantity,
          quantity_requested: container.quantity
        }
      end
    end

    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "Ticket containers exceed the available inventory",
        insufficient_items)
    end

    update_inventory_holdings(updated_quantities)
  end

  def move_inventory!(transfer)
    updated_quantities = {}
    insufficient_items = []
    transfer.containers.each do |container|
      holding = self.holdings.find_by(item: container.item)
      new_holding = transfer.to.holdings.find_or_create_by(item: container.item)
      next if holding.nil? || holding.quantity == 0
      if holding.quantity >= container.quantity
        updated_quantities[holding.id] = (updated_quantities[holding.id] || holding.quantity) - container.quantity
        updated_quantities[new_holding.id] = (updated_quantities[new_holding.id] || 
          new_holding.quantity) + container.quantity
      else
        insufficient_items << {
          item_id: container.item.id,
          item_name: container.item.name,
          quantity_on_hand: holding.quantity,
          quantity_requested: container.quantity
        }
      end
    end

    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "Transfer containers exceed the available inventory",
        insufficient_items)
    end

    update_inventory_holdings(updated_quantities)
  end



  def reclaim!(ticket)
    ActiveRecord::Base.transaction do
      ticket.containers.each do |container|
        holding = self.holdings.find_by(item: container.item)
        holding.update_attribute(:quantity, holding.quantity + container.quantity)
      end
    end
    ticket.destroy
  end

  def total_inventory
    holdings.sum(:quantity)
  end

  private

  def update_inventory_holdings(records)
    ActiveRecord::Base.transaction do
      records.each do |holding_id, quantity|
        Holding.find(holding_id).update_attribute("quantity", quantity)
      end
    end
  end

end