# == Schema Information
#
# Table name: storage_locations
#
#  id              :integer          not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#  latitude        :float
#  longitude       :float
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

  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  include Filterable
  scope :containing, ->(item_id) {
    joins(:inventory_items).where("inventory_items.item_id = ?", item_id)
  }
  scope :alphabetized, -> { order(:name) }
  scope :for_csv_export, ->(organization) { where(organization: organization) }

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

  def intake!(adjustment)
    log = {}
    adjustment.line_items.each do |line_item|
      inventory_item = InventoryItem.find_or_create_by(storage_location_id: id,
                                                       item_id: line_item.item_id)
      inventory_item.quantity += line_item&.quantity || 0
      inventory_item.save
      log[line_item.item_id] = "+#{line_item.quantity}"
    end
    log
  end

  # NOTE: This knows too much about donations/purchases
  # NOTE: Can we do logging better? It seems like a side effect
  def remove!(itemizable)
    log = {}
    itemizable.line_items.each do |line_item|
      inventory_item = InventoryItem.find_by(storage_location: id, item_id: line_item.item_id)
      # NOTE: Code smell - are we sure we want to allow this to be destroyed if < 0?
      if (inventory_item.quantity - line_item.quantity) <= 0
        # NOTE: Instead of deleting, maybe we could leave it at 0, and hide it in the UI instead
        inventory_item.destroy
      else
        inventory_item.update(quantity: inventory_item.quantity - line_item.quantity)
      end
      log[line_item.item_id] = "-#{line_item.quantity}"
    end
    log
  end

  # NOTE: Make this code clearer in its intent -- needs more context
  def adjust_from_past!(itemizable, previous_line_item_values)
    itemizable.line_items.each do |line_item|
      # NOTE: Can't we do an association lookup, instead of going all the way up to the model?
      inventory_item = InventoryItem.find_or_create_by(storage_location_id: id, item_id: line_item.item_id)
      # If the item wasn't deleted by the user, then it will be present to be deleted
      # here, and delete returns the item as a return value.
      if previous_line_item_value = previous_line_item_values.delete(line_item.id)
        inventory_item.quantity += line_item.quantity
        inventory_item.quantity -= previous_line_item_value.quantity
        inventory_item.save!
      end
      inventory_item.destroy! if inventory_item.quantity.zero?
    end
    # Update storage for line items that are no longer persisted because they
    # were removed during the update/delete process.
    previous_line_item_values.values.each do |value|
      inventory_item = InventoryItem.find_or_create_by(storage_location_id: id, item_id: value.item_id)
      inventory_item.decrement!(:quantity, value.quantity)
      inventory_item.destroy! if inventory_item.quantity.zero?
    end
  end

  # This is the "subtract inventory method"
  # NOTE: This is not returning a log object
  def distribute!(itemizable)
    # This is passed to update_inventory_inventory_items
    updated_quantities = {}
    # Used in the exception return value
    insufficient_items = []
    itemizable.line_items.each do |line_item|
      inventory_item = inventory_items.find_by(item: line_item.item)
      # NOTE: If the distribution isn't able to find the inventory item, it continues
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

    # NOTE: Could this be handled by a validation instead?
    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "#{itemizable.class.name} line_items exceed the available inventory",
        insufficient_items
      )
    end

    # NOTE: This executes the transaction to actually change the data
    update_inventory_inventory_items(updated_quantities)
  end

  # NOTE: We should generalize this elsewhere -- Importable concern?
  def self.import_csv(csv, organization)
    csv.each do |row|
      loc = StorageLocation.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end

  # NOTE: We should generalize this elsewhere -- Importable concern?
  def self.import_inventory(filename, org, loc)
    current_org = Organization.find(org)
    adjustment = current_org.adjustments.create(storage_location_id: loc.to_i, comment: "Starting Inventory")
    CSV.parse(filename, headers: false) do |row|
      adjustment.line_items
                .create(quantity: row[0].to_i, item_id: current_org.items.find_by(name: row[1]))
    end
    adjustment.storage_location.intake!(adjustment)
  end

  # Used to move inventory between StorageLocations; reflects items being physically moved
  # Ex: move 500 size "2" diapers from main warehouse to overflow warehouse because insufficient space in main warehouse
  # This could all be moved over to the `Transfer` model
  def move_inventory!(transfer)
    # Contains the total deltas from/to for all the InventoryItem records that are being changed
    updated_quantities = {}
    item_validator = Errors::InsufficientAllotment.new("Transfer items exceeds \
                                                        the available inventory")
    transfer.line_items.each do |line_item|
      # NOTE: We should do it this way more
      from_inventory_item = inventory_items.find_by(item: line_item.item)
      # NOTE: Initialize the inventory item on the destination storage location; "to" = "a storage location"
      to_inventory_item = transfer.to.inventory_items.find_or_create_by(item: line_item.item)
      # NOTE: this is for if the transfer includes inventory items that are nonexistent / zero, we can't transfer them
      # maybe we could do this as a validation, or at the model level instead?
      next if from_inventory_item.nil? || from_inventory_item.quantity.zero?

      if from_inventory_item.quantity >= line_item.quantity
        # NOTE: this is subtracting the inventory found on each line item, from the running total of inventory available at the source location
        updated_quantities[from_inventory_item.id] = (updated_quantities[from_inventory_item.id] || from_inventory_item.quantity) - line_item.quantity
        # NOTE: this is adding the inventory found to the new destination at the new storage location
        updated_quantities[to_inventory_item.id] = (updated_quantities[to_inventory_item.id] || to_inventory_item.quantity) + line_item.quantity
      else
        item_validator.add_insufficiency(line_item.item,
                                         from_inventory_item.quantity,
                                         line_item.quantity)
      end
    end

    raise item_validator unless item_validator.satisfied?

    # NOTE: Run the transaction
    update_inventory_inventory_items(updated_quantities)
  end

  # Used to adjust inventory at a StorageLocation to reflect reality
  # Ex: we thought we had 200 size "5" diapers, but we actually have 180 size "5" diapers
  # NOTE: Has too much knowledge about adjustments -- should be moved to `Adjustment`
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

  # NOTE: This reverses a distribution
  # NOTE: Too much knowledge about distribution
  def reclaim!(distribution)
    ActiveRecord::Base.transaction do
      distribution.line_items.each do |line_item|
        if line_item.item.nil? || !line_item.item.active?
          # If the item was previously hidden (inactive), make it active
          Item.unscoped.find(line_item.item_id).update(active: true)
          line_item.reload
        end
        inventory_item = inventory_items.find_by(item: line_item.item)
        inventory_item.update!(quantity: inventory_item.quantity + line_item.quantity)
      end
    end
  end

  # NOTE: This has WAY too much knowledge of distribution
  def update_distribution!(distribution, new_distribution_params)
    ActiveRecord::Base.transaction do
      distribution.line_items.each do |line_item|
        inventory_item = inventory_items.find_or_create_by!(item: line_item.item)
        inventory_item.update!(quantity: (inventory_item.quantity || 0) + line_item.quantity)
        line_item.destroy!
      end
      distribution = distribution.reload
      distribution.update! new_distribution_params

      distribution.line_items.each do |line_item|
        inventory_item = inventory_items.find_by(item: line_item.item)
        raise ActiveRecord::Rollback, "Failed to update distribution, please contact tech support if this problem persists" if inventory_item.nil?

        if inventory_item.quantity == line_item.quantity # otherwise this would make the quantity 0 and an exception would be thrown
          inventory_item.destroy!
        else
          inventory_item.update!(quantity: inventory_item.quantity - line_item.quantity)
        end
      end
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  # FIXME: After this is stable, revisit how we do logging
  def increase_inventory(itemizable)
    itemizable.line_items.each do |line_item|
      inventory_item = inventory_items.find_or_create_by!(item: line_item.item)
      inventory_item.increment!(:quantity, line_item.quantity)
    end
    # log could be pulled from dirty AR stuff
    save
    # return log
  end

  # TODO: re-evaluate this for optimization
  def decrease_inventory(itemizable)
    insufficient_items = []
    itemizable.line_items.each do |line_item|
      inventory_item = inventory_items.find_by(item: line_item.item) || inventory_items.build

      next unless inventory_item.quantity < line_item.quantity

      insufficient_items << {
        item_id: line_item.item.id,
        item_name: line_item.item.name,
        quantity_on_hand: inventory_item.quantity,
        quantity_requested: line_item.quantity
      }
    end

    # NOTE: Could this be handled by a validation instead?
    unless insufficient_items.empty?
      raise Errors::InsufficientAllotment.new(
        "Requested #{itemizable.class.name} items exceed the available inventory",
        insufficient_items
      )
    end

    itemizable.line_items.each do |line_item|
      # Raise AR:RNF if it fails to find it
      inventory_item = inventory_items.find_by(item: line_item.item)
      # Attempt to reduce the inventory box quantity
      inventory_item.decrement!(:quantity, line_item.quantity)
    end
    # log could be pulled from dirty AR stuff
    save!
    # return log
  end
=begin
def distribute!(itemizable)
    # This is passed to update_inventory_inventory_items
    updated_quantities = {}
    # Used in the exception return value
    insufficient_items = []
    itemizable.line_items.each do |line_item|
      inventory_item = inventory_items.find_by(item: line_item.item)
      # NOTE: If the distribution isn't able to find the inventory item, it continues
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
=end

  def self.csv_export_headers
    ["Name", "Address", "Total Inventory"]
  end

  def csv_export_attributes
    [name, address, size]
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
