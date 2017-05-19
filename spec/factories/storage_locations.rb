# == Schema Information
#
# Table name: storage_locations
#
#  id         :integer          not null, primary key
#  name       :string
#  address    :string
#  created_at :datetime
#  updated_at :datetime
#

FactoryGirl.define do
  factory :storage_location do
    transient do
      item_quantity 100
      item nil
    end

    name "Smithsonian Institute"
    address "1500 Remount Road, Front Royal, VA"

    trait :with_items do
      after(:create) do |storage_location, evaluator|
        item = (evaluator.item.nil?) ? create(:item) : evaluator.item
        item.save if item.new_record?
        create_list(:inventory_item, 1, storage_location: storage_location, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
