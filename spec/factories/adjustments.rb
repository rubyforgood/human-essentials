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
    storage_location nil
    comment "A comment"

    after(:build) do |instance, evaluator|
      instance.storage_location = evaluator.storage_location || create(:storage_location, organization: instance.organization)
    end

    trait :with_items do
      transient do
        item_quantity 100
        item nil
      end

      after(:build) do |instance, evaluator|
        instance.storage_location ||= create(:storage_location, :with_items, item: evaluator.item, organization: instance.organization)
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
