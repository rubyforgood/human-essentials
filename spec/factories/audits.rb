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
    organization { Organization.try(:first) || create(:organization) }
    user { nil }
    storage_location { nil }
    adjustment { nil }
    status { :in_progress }

    after(:build) do |instance, evaluator|
      instance.storage_location = evaluator.storage_location || create(:storage_location, organization: instance.organization)
      instance.user = evaluator.user || create(:organization_admin, organization: instance.organization)
    end

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:build) do |audit, evaluator|
        item = evaluator.item || audit.storage_location.inventory_items.first.item
        audit.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: audit)
      end
    end    
  end
end