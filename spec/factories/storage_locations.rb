# == Schema Information
#
# Table name: storage_locations
#
#  id              :integer          not null, primary key
#  address         :string
#  latitude        :float
#  longitude       :float
#  name            :string
#  square_footage  :integer
#  warehouse_type  :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

FactoryBot.define do
  factory :storage_location do
    name { "Smithsonian Conservation Center" }
    address { "1500 Remount Road, Front Royal, VA 22630" }
    organization { Organization.try(:first) || create(:organization) }
    square_footage { 100 }
    warehouse_type { StorageLocation::WAREHOUSE_TYPES.sample }

    trait :with_items do
      transient do
        item_count { 1 }
        item_quantity { 100 }
        item { nil }
      end

      after(:create) do |storage_location, evaluator|
        if evaluator.item.nil?
          item_count = evaluator.item_count

          create_list(:inventory_item, item_count,
                      storage_location: storage_location,
                      quantity: evaluator.item_quantity)
        else
          item = evaluator.item
          item.save if item.new_record?
          create_list(:inventory_item, 1,
                      storage_location: storage_location,
                      quantity: evaluator.item_quantity,
                      item: item,)
        end
      end
    end
  end
end
