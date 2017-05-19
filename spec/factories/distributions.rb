# == Schema Information
#
# Table name: distributions
#
#  id           :integer          not null, primary key
#  comment      :text
#  created_at   :datetime
#  updated_at   :datetime
#  inventory_id :integer
#  partner_id   :integer
#

FactoryGirl.define do
  factory :distribution do
    inventory
    partner

    trait :with_items do
      inventory { create :inventory, :with_items }

      transient do
        item_quantity 100
        item nil
      end

      after(:build) do |distribution, evaluator|
        item = if evaluator.item.nil?
                 distribution.inventory.inventory_items.first.item
               else
                 evaluator.item
               end
        distribution.containers << build(:container, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
