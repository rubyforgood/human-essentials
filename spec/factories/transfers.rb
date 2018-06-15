# == Schema Information
#
# Table name: transfers
#
#  id              :bigint(8)        not null, primary key
#  from_id         :integer
#  to_id           :integer
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

FactoryBot.define do
  factory :transfer do
    transient do
      storage_location nil
    end
    organization { Organization.try(:first) || create(:organization) }
    from nil
    to nil
    comment "A comment"

    after(:build) do |instance, evaluator|
      # the Itemizable shared_example needs `storage_location` to be an option
      instance.from = evaluator.storage_location || evaluator.from || create(:storage_location, organization: evaluator.organization)
      instance.to = evaluator.to || create(:storage_location, organization: evaluator.organization)
    end

    trait :with_items do
      transient do
        item_quantity 100
        item nil
      end

      after(:build) do |instance, evaluator|
        instance.from = create(:storage_location, :with_items, item: evaluator.item, organization: evaluator.organization)
        item = if evaluator.item.nil?
                 instance.from.inventory_items.first.item
               else
                 evaluator.item
               end
        instance.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
