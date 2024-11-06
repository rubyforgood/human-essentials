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

  scope :alphabetized, -> { order(:name) }
  scope :for_csv_export, ->(organization, *) { where(organization: organization) }
  scope :active_locations, -> { where(discarded_at: nil) }

  # @param organization [Organization]
  # @param inventory [View::Inventory]
  def self.items_inventoried(organization, inventory = nil)
    inventory ||= View::Inventory.new(organization.id)
    inventory
      .all_items
      .uniq(&:item_id)
      .sort_by(&:name)
      .map { |i| OpenStruct.new(name: i.name, id: i.item_id) }
  end

  # @return [Array<Item>]
  def items
    View::Inventory.items_for_location(self).map(&:db_item)
  end

  # @return [Integer]
  def size
    View::Inventory.items_for_location(self).map(&:quantity).sum
  end

  # @param item_id [Integer]
  # @return [Integer]
  def item_total(item_id)
    View::Inventory.new(organization_id)
      .quantity_for(storage_location: id, item_id: item_id)
  end

  # @param inventory [View::Inventory]
  # @return [Integer]
  def inventory_total_value_in_dollars(inventory = nil)
    inventory ||= View::Inventory.new(organization_id)
    inventory&.total_value_in_dollars(storage_location: id)
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
    []
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

  def validate_empty_inventory
    unless empty_inventory?
      errors.add(:base, "Cannot delete storage location containing inventory items with non-zero quantities")
      throw(:abort)
    end
  end

  def self.csv_export_headers
    ["Name", "Address", "Square Footage", "Warehouse Type", "Total Inventory"]
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
    inventory = View::Inventory.new(organization_id)
    inventory.quantity_for(storage_location: id).zero?
  end
end
