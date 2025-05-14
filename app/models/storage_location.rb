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
  has_many :adjustments, dependent: :destroy
  has_many :audits, dependent: :destroy
  has_many :inventory_items, -> { includes(:item).order("items.name") },
           inverse_of: :storage_location,
           dependent: :destroy
  has_many :donations, dependent: :destroy
  has_many :distributions, dependent: :destroy
  has_many :transfers_from, class_name: "Transfer",
                            inverse_of: :from,
                            foreign_key: :from_id,
                            dependent: :destroy
  has_many :transfers_to, class_name: "Transfer",
                          inverse_of: :to,
                          foreign_key: :to_id,
                          dependent: :destroy

  validates :name, :address, presence: true
  validates :warehouse_type, inclusion: { in: WAREHOUSE_TYPES },
                             allow_blank: true
  validates :square_footage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  before_destroy :validate_empty_inventory, prepend: true

  include Discard::Model
  include Geocodable
  include Filterable
  include Exportable

  scope :alphabetized, -> { order(:name) }
  scope :active, -> { where(discarded_at: nil) }
  scope :with_adjustments_for, ->(organization) {
    joins(:adjustments).where(organization_id: organization.id).distinct.active.alphabetized
  }
  scope :with_audits_for, ->(organization) {
    joins(:audits).where(organization_id: organization.id).distinct.active.alphabetized
  }
  scope :with_transfers_to, ->(organization) {
    joins(:transfers_to).where(organization_id: organization.id).distinct.order(:name)
  }
  scope :with_transfers_from, ->(organization) {
    joins(:transfers_from).where(organization_id: organization.id).distinct.order(:name)
  }

  # @param organization [Organization]
  # @param inventory [View::Inventory]
  # @return [Array<Option>]
  def self.items_inventoried(organization, inventory = nil)
    inventory ||= View::Inventory.new(organization.id)
    inventory
      .all_items
      .uniq(&:item_id)
      .sort_by(&:name)
      .map { |i| Option.new(name: i.name, id: i.item_id) }
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
  # @param current_organization [Organization]
  # @return [String]
  def self.generate_csv_from_inventory(storage_locations, inventory, current_organization)
    # Get all inventoried and organization items
    all_inventoried_items = inventory.all_items

    # Not all items are inventoried, so we need to add the organization items to the headers.
    # Yes it's another full table scan, but it's a small dataset and product wants the exports to consistently include all items (active, inactive, etc).
    # This means we have to look for inactive items or items without inventory.
    # note the remapping of item.id to item_id is to enable the uniq call to happen once across the two arrays.
    all_organization_items = current_organization.items.select("DISTINCT ON (LOWER(name)) items.name, items.id as item_id").order("LOWER(name) ASC")

    all_items = (all_inventoried_items + all_organization_items).uniq(&:item_id).sort_by { |item| item&.name&.downcase }

    # Build headers from unique inventoried and organization items, using name as the key.
    item_headers = all_items.map(&:name)

    CSV.generate(headers: true) do |csv|
      csv_data = storage_locations.map do |sl|
        total_quantity = inventory.quantity_for(storage_location: sl.id)
        attributes = [sl.name, sl.address, sl.square_footage, sl.warehouse_type, total_quantity] +
          all_items.map { |item| inventory.quantity_for(storage_location: sl.id, item_id: item.item_id) }
        attributes.map { |attr| normalize_csv_attribute(attr) }
      end
      ([csv_export_headers + item_headers] + csv_data).each do |row|
        csv << row
      end
    end
  end

  def empty_inventory?
    inventory = View::Inventory.new(organization_id)
    inventory.quantity_for(storage_location: id).zero?
  end
end
