# == Schema Information
#
# Table name: distributions
#
#  id                  :integer          not null, primary key
#  comment             :text
#  created_at          :datetime
#  updated_at          :datetime
#  storage_location_id :integer
#  partner_id          :integer
#  organization_id     :integer
#

FactoryGirl.define do
  factory :distribution do
    storage_location
    partner
    organization { Organization.try(:first) || create(:organization) }
    issued_at nil

    trait :with_items do
      storage_location { create :storage_location, :with_items }

      transient do
        item_quantity 100
        item nil
      end

      after(:build) do |distribution, evaluator|
        item = if evaluator.item.nil?
                 distribution.storage_location.inventory_items.first.item
               else
                 evaluator.item
               end
        distribution.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
