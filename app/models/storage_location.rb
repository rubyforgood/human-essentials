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

  include Geocodable
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
    # NOTE: this was originally headers: false; it may create buggy behavior
    CSV.parse(filename, headers: true) do |row|
      adjustment.line_items
                .create(quantity: row[0].to_i, item_id: current_org.items.find_by(name: row[1]))
    end
    adjustment.storage_location.increase_inventory(adjustment)
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
  def increase_inventory(itemizable_array)
    itemizable_array = itemizable_array.is_a?(Array) ? itemizable_array : itemizable_array.to_a

    # This is, at least for now, how we log changes to the inventory made in this call
    log = {}
    # Iterate through each of the line-items in the moving box
    itemizable_array.each do |item_hash|
      unless item_hash[:active]
        # If the item was previously hidden (inactive), make it active
        Item.unscoped.find(item_hash[:item_id]).update(active: true)
        # line_item.reload
      end
      # Locate the storage box for the item, or create a new storage box for it
      inventory_item = inventory_items.find_or_create_by!(item_id: item_hash[:item_id])
      # Increase the quantity-on-record for that item
      inventory_item.increment!(:quantity, item_hash[:quantity])
      # Record in the log that this has occurred
      log[item_hash[:item_id]] = "+#{item_hash[:quantity]}"
    end
    # log could be pulled from dirty AR stuff?
    # Save the final changes -- does this need to occur here?
    save
    # return log
    log
  end

  # TODO: re-evaluate this for optimization
  def decrease_inventory(itemizable_array)
    itemizable_array = itemizable_array.is_a?(Array) ? itemizable_array : itemizable_array.to_a
    # This is, at least for now, how we log changes to the inventory made in this call
    log = {}
    # This tracks items that have insufficient inventory counts to be reduced as much
    insufficient_items = []
    # Iterate through each of the line-items in the moving box
    itemizable_array.each do |item|
      # Locate the storage box for the item, or create an empty storage box
      inventory_item = inventory_items.find_by(item_id: item[:item_id]) || inventory_items.build
      # If we've got sufficient inventory in the storage box to fill the moving box, then continue
      next unless inventory_item.quantity < item[:quantity]

      # Otherwise, we need to record that there was insufficient inventory on-hand
      insufficient_items << {
        item_id: item[:item_id],
        item_name: item[:name],
        quantity_on_hand: inventory_item.quantity,
        quantity_requested: item[:quantity]
      }
    end

    # NOTE: Could this be handled by a validation instead?
    # If we found any insufficiencies
    unless insufficient_items.empty?
      # Raise this custom error with information about each of the items that showed insufficient
      # This bails out of the method!
      raise Errors::InsufficientAllotment.new(
        "Requested items exceed the available inventory",
        insufficient_items
      )
    end

    # Re-run through the items in the moving box again
    itemizable_array.each do |item|
      # Look for the moving box for this item -- we know there is sufficient quantity this time
      # Raise AR:RNF if it fails to find it -- though that seems moot since it would have been
      # captured by the previous block.
      inventory_item = inventory_items.find_by(item_id: item[:item_id])
      # Reduce the inventory box quantity
      inventory_item.decrement!(:quantity, item[:quantity])
      # Record in the log that this has occurred
      log[item[:item_id]] = "-#{item[:quantity]}"
    end
    # log could be pulled from dirty AR stuff
    save!
    # return log
    log
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
