class Adjustment < ApplicationRecord
  belongs_to :organization
  belongs_to :storage_location

  has_many :line_items, as: :itemizable, inverse_of: :itemizable
  has_many :items, through: :line_items
  accepts_nested_attributes_for :line_items, allow_destroy: true

  validates :storage_location, :organization, presence: true
  validates_associated :line_items
  validate :line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization

  private

  def storage_locations_belong_to_organization
    if !self.organization.storage_locations.include?(self.storage_location)
      errors.add :storage_location, 'storage location must belong to organization'
    end
  end

  # TODO - this could probably be made an association method for the `line_items` association
  def line_item_items_exist_in_inventory
    self.line_items.each do |line_item|
      next unless line_item.item
      inventory_item = self.storage_location.inventory_items.find_by(item: line_item.item)
      if inventory_item.nil?
        errors.add(:inventory,
                   "#{line_item.item.name} is not available " \
                   "at this storage location")
      end
    end
  end
end
