# == Schema Information
#
# Table name: storage_locations
#
#  id              :integer          not null, primary key
#  address         :string
#  discarded_at    :datetime
#  latitude        :float
#  longitude       :float
#  name            :string
#  square_footage  :integer
#  time_zone       :string           default("America/Los_Angeles"), not null
#  warehouse_type  :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
class StorageLocation < ApplicationRecord
  has_paper_trail
  require "csv"

  WAREHOUSE_TYPES = [
    'Residential space used',
    'Consumer, self-storage or container space',
    'Commercial/office/business space that includes storage space',
    'Warehouse with loading bay'
  ].freeze

  belongs_to :organization
  has_many :inventory_items, -> { includes(:item).order("items.name") },
           inverse_of: :storage_location,
           dependent: :destroy
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
  has_many :kit_allocations, dependent: :destroy

  validates :name, :address, :organization, presence: true
  validates :warehouse_type, inclusion: { in: WAREHOUSE_TYPES },
                             allow_blank: true
  before_destroy :validate_empty_inventory, prepend: true

  include Discard::Model
  include Geocodable
  include Filterable
  include Exportable

  scope :containing, ->(item_id) {
    joins(:inventory_items).where("inventory_items.item_id = ?", item_id)
  }
  scope :has_inventory_items, -> {
    includes(:inventory_items).where.not(inventory_items: { id: nil })
  }
  scope :alphabetized, -> { order(:name) }
  scope :for_csv_export, ->(organization, *) { where(organization: organization) }
  scope :active_locations, -> { where(discarded_at: nil) }

  # @param organization [Organization]
  # @param inventory [View::Inventory]
  def self.items_inventoried(organization, inventory = nil)
    if inventory
      inventory
        .all_items
        .uniq(&:item_id)
        .sort_by(&:name)
        .map { |i| OpenStruct.new(name: i.name, id: i.item_id) }
    else
      organization.items.joins(:storage_locations).select(:id, :name).group(:id, :name).order(name: :asc)
    end
  end

  def item_total(item_id)
    inventory_items.where(item_id: item_id).pick(:quantity) || 0
  end

  def size
    inventory_items.sum(:quantity)
  end

  def total_active_inventory_count
    active_inventory_items
    .select('items.quantity')
    .sum(:quantity)
  end

  def inventory_total_value_in_dollars(inventory = nil)
    if inventory
      inventory.total_value_in_dollars(storage_location: id)
    else
      inventory_total_value = inventory_items.joins(:item).map do |inventory_item|
        value_in_cents = inventory_item.item.try(:value_in_cents)
        value_in_cents * inventory_item.quantity
      end.reduce(:+)
      inventory_total_value.present? ? (inventory_total_value.to_f / 100) : 0
    end
  end

  def to_csv
    org = organization

    CSV.generate(headers: true) do |csv|
      csv << ['Quantity', 'DO NOT CHANGE ANYTHING IN THIS COLUMN']
      org.items.each do |item|
        csv << ["", item.name]
      end
    end
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
  # Requires a user with the ORG_ADMIN role, or it will fail silently
  # First user with role from org found will be used for adjustment creation
  #
  # @param filename [String]
  # @param org [Integer] Organization ID
  # @param loc [Integer] StorageLocation ID
  # @return [void]
  def self.import_inventory(filename, org, loc)
    storage_location = StorageLocation.find(loc.to_i)
    raise Errors::InventoryAlreadyHasItems unless storage_location.empty_inventory?

    current_org = Organization.find(org)
    adjustment = current_org.adjustments.new(storage_location_id: loc.to_i,
                                             user_id: User.with_role(Role::ORG_ADMIN, current_org).first&.id,
                                             comment: "Starting Inventory")
    # NOTE: this was originally headers: false; it may create buggy behavior
    CSV.parse(filename, headers: true) do |row|
      adjustment.line_items
                .build(quantity: row[0].to_i, item_id: current_org.items.find_by(name: row[1]))
    end
    AdjustmentCreateService.new(adjustment).call
  end

  # FIXME: After this is stable, revisit how we do logging
  def increase_inventory(itemizable_array)
    # This is, at least for now, how we log changes to the inventory made in this call
    log = {}
    # Iterate through each of the line-items in the moving box
    itemizable_array.each do |item_hash|
      # Locate the storage box for the item, or create a new storage box for it
      inventory_item = inventory_items.find_or_create_by!(item_id: item_hash[:item_id])
      # Increase the quantity-on-record for that item
      new_quantity = inventory_item.quantity + item_hash[:quantity].to_i
      inventory_item.update!(quantity: new_quantity)
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
    # This is, at least for now, how we log changes to the inventory made in this call
    log = {}
    # This tracks items that have insufficient inventory counts to be reduced as much
    insufficient_items = []
    # Iterate through each of the line-items in the moving box
    itemizable_array.each do |item_hash|
      # Locate the storage box for the item, or create an empty storage box
      inventory_item = inventory_items.find_by(item_id: item_hash[:item_id]) || inventory_items.build
      # If we've got sufficient inventory in the storage box to fill the moving box, then continue
      next unless inventory_item.quantity < item_hash[:quantity]

      # Otherwise, we need to record that there was insufficient inventory on-hand
      insufficient_items << {
        item_id: item_hash[:item_id],
        item_name: item_hash[:name],
        quantity_on_hand: inventory_item.quantity,
        quantity_requested: item_hash[:quantity]
      }
    end
    # NOTE: Could this be handled by a validation instead?
    # If we found any insufficiencies
    if insufficient_items.any? && !Event.read_events?(organization)
      # Raise this custom error with information about each of the items that showed insufficient
      # This bails out of the method!
      raise Errors::InsufficientAllotment.new(
        "Requested items exceed the available inventory.",
        insufficient_items
      )
    end

    # Re-run through the items in the moving box again
    itemizable_array.each do |item_hash|
      # Look for the moving box for this item -- we know there is sufficient quantity this time
      # Raise AR:RNF if it fails to find it -- though that seems moot since it would have been
      # captured by the previous block.
      inventory_item = inventory_items.find_by(item_id: item_hash[:item_id])
      # Reduce the inventory box quantity
      new_quantity = inventory_item.quantity - item_hash[:quantity]
      inventory_item.update(quantity: new_quantity)
      # Record in the log that this has occurred
      log[item_hash[:item_id]] = "-#{item_hash[:quantity]}"
    end
    # log could be pulled from dirty AR stuff
    save!
    # return log
    log
  end

  def validate_empty_inventory
    unless empty_inventory?
      errors.add(:base, "Cannot delete storage location containing inventory items with non-zero quantities")
      throw(:abort)
    end
  end

  def self.csv_export_headers
    ["Name", "Address", "Square Footage", "Warehouse Type", "Total Inventory"]
  end

  # TODO remove this method once read_events? is true everywhere
  def csv_export_attributes
    attributes = [name, address, square_footage, warehouse_type, total_active_inventory_count]
    active_inventory_items.sort_by { |inv_item| inv_item.item.name }.each { |item| attributes << item.quantity }
    attributes
  end

  # @param storage_locations [Array<StorageLocation>]
  # @param inventory [View::Inventory]
  # @return [String]
  def self.generate_csv_from_inventory(storage_locations, inventory)
    all_items = inventory.all_items.uniq(&:item_id).sort_by(&:name)
    additional_headers = all_items.map(&:name).uniq
    CSV.generate(headers: true) do |csv|
      csv_data = storage_locations.map do |sl|
        total_quantity = inventory.quantity_for(storage_location: sl.id)
        attributes = [sl.name, sl.address, sl.square_footage, sl.warehouse_type, total_quantity] +
          all_items.map { |i| inventory.quantity_for(storage_location: sl.id, item_id: i.item_id) }
        attributes.map { |attr| normalize_csv_attribute(attr) }
      end
      ([csv_export_headers + additional_headers] + csv_data).each do |row|
        csv << row
      end
    end
  end

  def empty_inventory?
    if Event.read_events?(organization)
      inventory = View::Inventory.new(organization_id)
      inventory.quantity_for(storage_location: id).zero?
    else
      inventory_items.map(&:quantity).all?(&:zero?)
    end
  end

  def active_inventory_items
    inventory_items
    .includes(:item)
    .where(items: { active: true })
  end
end
