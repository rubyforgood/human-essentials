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

require_relative "../inventory"

FactoryBot.define do
  factory :storage_location do
    name { "Smithsonian Conservation Center" }
    address { "1500 Remount Road, Front Royal, VA 22630" }
    organization { Organization.try(:first) || create(:organization) }
    square_footage { 100 }
    warehouse_type { StorageLocation::WAREHOUSE_TYPES.sample }
    transient do
      item_count { 1 }
    end

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:create) do |storage_location, evaluator|
        if evaluator.item.nil? && !evaluator.item_count.zero?
          item_count = evaluator.item_count

          TestInventory.create_inventory(
            storage_location.organization, {
              storage_location.id => (0...item_count).to_h do
                item = create(:item, organization_id: storage_location.organization_id)
                [item.id, evaluator.item_quantity]
              end
            }
          )
        elsif evaluator.item
          item = evaluator.item
          item.save if item.new_record?
          TestInventory.create_inventory(
            storage_location.organization,
            {
              storage_location.id => {item.id => evaluator.item_quantity}
            }
          )
        end
      end
    end
  end
end
