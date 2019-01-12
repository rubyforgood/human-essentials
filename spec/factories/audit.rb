# == Schema Information
#
# Table name: audits
#
#  id                  :bigint(8)        not null, primary key
#  user_id             :bigint(8)
#  organization_id     :bigint(8)
#  adjustment_id       :bigint(8)
#  storage_location_id :bigint(8)
#  status              :integer          default("in_progress"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :audit do
    user { User.try(:first) || create(:user) }
    organization { Organization.try(:first) || create(:organization) }
    storage_location { nil }
    adjustment { nil }
    status { :in_progress }

    after(:build) do |instance, evaluator|
      instance.storage_location = evaluator.storage_location || create(:storage_location, organization: instance.organization)
    end

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end
    end

    after(:build) do |instance, evaluator|
      instance.storage_location ||= create(:storage_location, :with_items, item: evaluator.item)
      item = if evaluator.item.nil?
               instance.storage_location.inventory_items.first.items
             else
               evaluator.item
             end
      instance.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item)
    end
  end
end