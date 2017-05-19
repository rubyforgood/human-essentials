# == Schema Information
#
# Table name: distributions
#
#  id              :integer          not null, primary key
#  comment         :text
#  created_at      :datetime
#  updated_at      :datetime
#  inventory_id    :integer
#  partner_id      :integer
#  organization_id :integer
#

FactoryGirl.define do
  factory :distribution do
    inventory
    partner
    organization { Organization.try(:first) || create(:organization) }

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
        distribution.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
