# == Schema Information
#
# Table name: tickets
#
#  id           :integer          not null, primary key
#  created_at   :datetime
#  updated_at   :datetime
#  partner_id   :integer
#  inventory_id :integer
#

FactoryGirl.define do
  factory :ticket do
    inventory
    partner

    trait :with_items do
      association :inventory, factory: :inventory_with_items

      transient do
        item_quantity 100
        item nil
      end

      after(:build) do |ticket, evaluator|
        item = if evaluator.item.nil?
                 ticket.inventory.holdings.first.item
               else
                 evaluator.item
               end
        ticket.containers << build(:container, quantity: evaluator.item_quantity, item: item)
      end

      after(:create) do |ticket, evaluator|
        item = if evaluator.item.nil?
                 ticket.inventory.holdings.first.item
               else
                 evaluator.item
               end
        create_list(:container, 1, itemizable: ticket, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
