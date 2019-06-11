# == Schema Information
#
# Table name: adjustments
#
#  id                  :bigint(8)        not null, primary key
#  organization_id     :integer
#  storage_location_id :integer
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :adjustment do
    organization { Organization.try(:first) || create(:organization) }
    storage_location
    comment { "A comment" }

    trait :with_items do
      storage_location { create :storage_location, :with_items, item: item || create(:item), organization: organization }

      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:build) do |adjustment, evaluator|
        item = evaluator.item || adjustment.storage_location.inventory_items.first.item
        adjustment.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: adjustment)
      end
    end
  end
end
