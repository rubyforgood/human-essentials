# == Schema Information
#
# Table name: purchases
#
#  id                    :bigint           not null, primary key
#  amount_spent_in_cents :integer
#  comment               :text
#  issued_at             :datetime
#  purchased_from        :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  organization_id       :integer
#  storage_location_id   :integer
#  vendor_id             :integer
#

FactoryBot.define do
  factory :purchase do
    comment { "It's a fine day for diapers." }
    purchased_from { "Google" }
    storage_location
    organization { Organization.try(:first) || create(:organization) }
    issued_at { nil }
    amount_spent_in_cents { 10_00 }
    vendor { Vendor.try(:first) || create(:vendor) }

    transient do
      item_quantity { 10 }
      item_id { nil }
    end

    trait :with_items do
      storage_location { create :storage_location, :with_items, item: item || create(:item), organization: organization }

      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:build) do |purchase, evaluator|
        item = evaluator.item || purchase.storage_location.inventory_items.first&.item || create(:item)
        purchase.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: purchase)
      end

      after(:create) do |instance, evaluator|
        evaluator.storage_location.increase_inventory(instance)
      end
    end
  end
end
