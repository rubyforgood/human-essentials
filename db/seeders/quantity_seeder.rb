class QuantitySeeder
  attr_accessor :organization, :items

  def self.seed(organization, items)
    new(organization, items).seed
  end

  def initialize(organization, items)
    @organization = organization
    @items = items
  end

  def seed
    items.each do |_category, entries|
      entries.each do |entry|
        seed_quantity(entry['name'], inv_arbor, entry['qty']['arbor'])
        seed_quantity(entry['name'], inv_pdxdb, entry['qty']['pdxdb'])
      end
    end
  end

  def inv_arbor
    @inv_arbor ||= StorageLocation.find_by(name: "Bulk Storage Location")
  end

  def inv_pdxdb
    @inv_pdxdb ||= StorageLocation.find_by(name: "Pawnee Main Bank (Office)")
  end

  def seed_quantity(item_name, storage_location, quantity)
    return if quantity.zero?

    item = Item.find_by(name: item_name, organization: organization)
    adjustment = organization.adjustments.create!(
      comment: "Starting inventory",
      storage_location: storage_location,
      user: organization.users.find_by(organization_admin: true)
    )

    LineItem.create!(quantity: quantity, item: item, itemizable: adjustment)

    adjustment.reload
    increasing_adjustment, decreasing_adjustment = adjustment.split_difference
    adjustment.storage_location.increase_inventory increasing_adjustment
    adjustment.storage_location.decrease_inventory decreasing_adjustment
  end
end
