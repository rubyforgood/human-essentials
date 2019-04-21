# == Schema Information
#
# Table name: distributions
#
#  id                  :integer          not null, primary key
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  storage_location_id :integer
#  partner_id          :integer
#  organization_id     :integer
#  issued_at           :datetime
#  agency_rep          :string
#

FactoryBot.define do
  factory :distribution do
    storage_location
    partner
    organization { Organization.try(:first) || create(:organization) }
    issued_at { nil }

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end

      storage_location { create :storage_location, :with_items, item: item }

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
