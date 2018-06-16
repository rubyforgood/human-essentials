# == Schema Information
#
# Table name: storage_locations
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

class StorageLocation < ApplicationRecord
  require "csv"

  belongs_to :organization
  has_many :inventory_items, -> { includes(:item).order("items.name") },
           inverse_of: :storage_location
  has_many :donations, dependent: :destroy
  has_many :distributions, dependent: :destroy
  has_many :items, through: :inventory_items
  has_many :transfers_from, class_name: "Transfer",
                            inverse_of: :from,
                            foreign_key: :id,
                            dependent: :destroy
  has_many :transfers_to, class_name: "Transfer",
                          inverse_of: :to,
                          foreign_key: :id,
                          dependent: :destroy

  validates :name, :address, :organization, presence: true

  include Filterable
  scope :containing, ->(item_id) {
    joins(:inventory_items).where("inventory_items.item_id = ?", item_id)
  }
  scope :alphabetized, -> { order(:name) }

  def self.item_total(item_id)
    StorageLocation.select("quantity")
                   .joins(:inventory_items)
                   .where("inventory_items.item_id = ?", item_id)
                   .collect(&:quantity)
                   .reduce(:+)
  end

  def self.items_inventoried
    Item.joins(:storage_locations).select(:id, :name).group(:id, :name).order(name: :asc)
  end

  def item_total(item_id)
    inventory_items.select(:quantity).find_by(item_id: item_id).try(:quantity)
  end

  def size
    inventory_items.sum(:quantity)
  end

  def to_csv
    org = organization

    CSV.generate(headers: true) do |csv|
      csv << ["Quantity", "DO NOT CHANGE ANYTHING IN THIS ROW"]
      org.items.each do |item|
        csv << ["", item.name]
      end
    end
  end

  def intake!(donation)
    log = {}
    donation.line_items.each do |line_item|
      inventory_item = InventoryItem.find_or_create_by(storage_location_id: id,
                                                       item_id: line_item.item_id) do |inv_item|
        inv_item.quantity = 0
      end
      inventory_item.quantity += begin
                                   line_item.quantity
                                 rescue StandardError
                                   0
                                 end
      inventory_item.save
      log[line_item.item_id] = "+#{line_item.quantity}"
    end
    log
  end

  def remove!(donation_or_purchase)
    log = {}
    donation_or_purchase.line_items.each do |line_item|
      inventory_item = InventoryItem.find_by(storage_location: id, item_id: line_item.item_id)
      if (inventory_item.quantity - line_item.quantity) <= 0
        inventory_item.destroy
      else
        inventory_item.update(quantity: inventory_item.quantity - line_item.quantity)
      end
      log[line_item.item_id] = "-#{line_item.quantity}"
    end
    log
  end

  def adjust_from_past!(donation_or_purchase, previous_line_item_values)
    donation_or_purchase.line_items.each do |line_item|
      inventory_item = InventoryItem.find_or_create_by(storage_location_id: id, item_id: line_item.item_id)
      # If the item wasn't deleted by the user, then it will be present to be deleted
      # here, and delete returns the item as a return value.
      if previous_line_item_value = previous_line_item_values.delete(line_item.id)
        inventory_item.quantity += line_item.quantity
        inventory_item.quantity -= previous_line_item_value.quantity
        inventory_item.save!
      end
      inventory_item.destroy! if inventory_item.quantity == 0
    end
    # Update storage for line items that are no longer persisted because they
    # were removed durring the updated/delete process.
    previous_line_item_values.values.each do |value|
      inventory_item = InventoryItem.find_or_create_by(storage_location_id: id, item_id: value.item_id)
      inventory_item.decrement!(:quantity, value.quantity)
      inventory_item.destroy! if inventory_item.quantity == 0
    end
  end

  def distribute!(distribution)
    updated_quantities = {}
    insufficient_items = []
    distribution.line_items.each do |line_item|
      inventory_item = inventory_items.find_by(item: line_item.item)
      next if inventory_item.nil?
      if inventory_item.quantity >= line_item.quantity
        updated_quantities[inventory_item.id] = (updated_quantities[inventory_item.id] ||
                                                 inventory_item.quantity) - line_item.quantity
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
        insufficient_items
      )
    end

    update_inventory_inventory_items(updated_quantities)
  end

  def self.import_csv(filename, organization)
    CSV.parse(filename, headers: true) do |row|
      loc = StorageLocation.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end

  def self.import_inventory(filename, org, loc)
    current_org = Organization.find(org)
    donation = current_org.donations.create(storage_location_id: loc.to_i,
                                            source: "Misc. Donation",
                                            organization_id: current_org.id)
    CSV.parse(filename, headers: false) do |row|
      donation.line_items
              .create(quantity: row[0].to_i, item_id: current_org.items.find_by(name: row[1]))
    end
    donation.storage_location.intake!(donation)
  end

  # Used to move inventory between StorageLocations; reflects items being physically moved
  # Ex: move 500 size "2" diapers from main warehouse to overflow warehouse because insufficient space in main warehouse
  def move_inventory!(transfer)
    updated_quantities = {}
    item_validator = Errors::InsufficientAllotment.new("Transfer items exceeds \
                                                        the available inventory")
    transfer.line_items.each do |line_item|
      inventory_item = inventory_items.find_by(item: line_item.item)
      new_inventory_item = transfer.to.inventory_items.find_or_create_by(item: line_item.item)
      next if inventory_item.nil? || inventory_item.quantity.zero?
      if inventory_item.quantity >= line_item.quantity
        updated_quantities[inventory_item.id] = (updated_quantities[inventory_item.id] ||
                                                 inventory_item.quantity) - line_item.quantity
        updated_quantities[new_inventory_item.id] = (updated_quantities[new_inventory_item.id] ||
          new_inventory_item.quantity) + line_item.quantity
      else
        item_validator.add_insufficiency(line_item.item,
                                         inventory_item.quantity,
                                         line_item.quantity)
      end
    end

    raise item_validator unless item_validator.satisfied?

    update_inventory_inventory_items(updated_quantities)
  end

  # Used to adjust inventory at a StorageLocation to reflect reality
  # Ex: we thought we had 200 size "5" diapers, but we actually have 180 size "5" diapers
  def adjust!(adjustment)
    updated_quantities = {}
    item_validator = Errors::InsufficientAllotment.new("Adjustment exceeds the available inventory")

    adjustment.line_items.each do |line_item|
      inventory_item = inventory_items.find_by(item: line_item.item)
      next if inventory_item.nil? || inventory_item.quantity.zero?

      if (inventory_item.quantity + line_item.quantity) >= 0
        updated_quantities[inventory_item.id] = (updated_quantities[inventory_item.id] ||
                                                 inventory_item.quantity) + line_item.quantity
      else
        item_validator.add_insufficiency(line_item.item,
                                         inventory_item.quantity,
                                         line_item.quantity)
      end
    end

    raise item_validator unless item_validator.satisfied?

    update_inventory_inventory_items(updated_quantities)
  end

  def reclaim!(distribution)
    ActiveRecord::Base.transaction do
      distribution.line_items.each do |line_item|
        inventory_item = inventory_items.find_by(item: line_item.item)
        inventory_item.update(quantity: inventory_item.quantity + line_item.quantity)
      end
    end
    distribution.destroy
  end

  private

  def update_inventory_inventory_items(records)
    ActiveRecord::Base.transaction do
      records.each do |inventory_item_id, quantity|
        InventoryItem.find(inventory_item_id).update(quantity: quantity)
      end
    end
  end
end
