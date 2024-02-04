# == Schema Information
#
# Table name: transfers
#
#  id              :integer          not null, primary key
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  from_id         :integer
#  organization_id :integer
#  to_id           :integer
#

FactoryBot.define do
  factory :transfer do
    transient do
      storage_location { nil }
    end
    organization { Organization.try(:first) || create(:organization) }
    from { nil }
    to { nil }
    comment { "A comment" }

    after(:build) do |instance, evaluator|
      # the Itemizable shared_example needs `storage_location` to be an option
      instance.from = evaluator.storage_location || evaluator.from || create(:storage_location, organization: evaluator.organization)
      instance.to = evaluator.to || create(:storage_location, organization: evaluator.organization)
    end

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:build) do |transfer, evaluator|
        event_item = View::Inventory.new(transfer.organization_id)
          .items_for_location(transfer.from_id)
          .first
          &.db_item
        item = evaluator.item || event_item || create(:item)
        transfer.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: transfer)
      end

      after(:create) do |instance, evaluator|
        evaluator.from.increase_inventory(instance.line_item_values)
      end
    end
  end
end
