# == Schema Information
#
# Table name: purchases
#
#  id                  :bigint(8)        not null, primary key
#  purchased_from      :string
#  comment             :text
#  organization_id     :integer
#  storage_location_id :integer
#  amount_spent        :integer
#  issued_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :purchase do
    comment "It's a fine day for diapers."
    purchased_from "Google"
    storage_location
    organization { Organization.try(:first) || create(:organization) }
    issued_at nil
    amount_spent 10

    transient do
      item_quantity 10
      item_id nil
    end

    trait :with_items do
      storage_location { create :storage_location, :with_items }

      transient do
        item_quantity 100
        item nil
      end

      after(:build) do |instance, evaluator|
        item = if evaluator.item.nil?
                 instance.storage_location.inventory_items.first.item
               else
                 evaluator.item
               end
        instance.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
