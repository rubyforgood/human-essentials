# == Schema Information
#
# Table name: transfers
#
#  id              :integer          not null, primary key
#  from_id         :integer
#  to_id           :integer
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

FactoryBot.define do
  factory :transfer do
    organization { Organization.try(:first) || create(:organization) }
    from_id { create(:storage_location).id }
    to_id { create(:storage_location).id }
    comment "A comment"

    trait :with_items do
      transient do
        item_quantity 100
        item nil
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
