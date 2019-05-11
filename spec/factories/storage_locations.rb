# == Schema Information
#
# Table name: storage_locations
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#  latitude        :float
#  longitude       :float
#

FactoryBot.define do
  factory :storage_location do
    name { "Smithsonian Conservation Center" }
    address { "1500 Remount Road, Front Royal, VA 22630" }
    organization { Organization.try(:first) || create(:organization) }

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:create) do |storage_location, evaluator|
        item = evaluator.item.nil? ? create(:item) : evaluator.item
        item.save if item.new_record?
        create_list(:inventory_item, 1,
                    storage_location: storage_location,
                    quantity: evaluator.item_quantity,
                    item: item)
      end
    end
  end
end
