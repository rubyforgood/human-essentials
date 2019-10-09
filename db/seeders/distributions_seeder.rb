class DistributionsSeeder
  attr_accessor :organization

  def self.seed(organization)
    new(organization).seed
  end

  def initialize(organization)
    @organization = organization
  end

  def seed
    20.times.each do
      storage_location = random_record_for_org(organization, StorageLocation)
      stored_inventory_items_sample = storage_location.inventory_items.sample(20)

      distribution = create_distribution(storage_location)

      stored_inventory_items_sample.each do |stored_inventory_item|
        create_line_item(stored_inventory_item, distribution)
      end
      distribution.reload
      distribution.storage_location.decrease_inventory(distribution)
    end
  end

  private

  def create_distribution(storage_location)
    Distribution.create!(storage_location: storage_location,
                         partner: random_record_for_org(organization, Partner),
                         organization: organization,
                         issued_at: (Date.today + rand(15).days))
  end

  def create_line_item(stored_inventory_item, distribution)
    distribution_qty = rand(stored_inventory_item.quantity / 2)
    LineItem.create!(
      quantity: distribution_qty,
      item: stored_inventory_item.item,
      itemizable: distribution
    ) if distribution_qty >= 1
  end
end
