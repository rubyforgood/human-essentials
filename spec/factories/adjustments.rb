# == Schema Information
#
# Table name: adjustments
#
#  id                  :integer          not null, primary key
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#  storage_location_id :integer
#  user_id             :bigint
#

FactoryBot.define do
  factory :adjustment do
    organization { Organization.try(:first) || create(:organization) }
    storage_location
    comment { "A comment" }
    user { organization.users.try(:first) || create(:user, organization_id: organization.id) }

    trait :with_items do
      storage_location { create :storage_location, :with_items, item: item || create(:item), organization: organization }

      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:build) do |adjustment, evaluator|
        event_item = View::Inventory.new(adjustment.organization_id)
          .items_for_location(adjustment.storage_location_id)
          .first
          &.db_item
        item = evaluator.item || event_item || create(:item)
        adjustment.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: adjustment)
      end
    end
  end
end
