# == Schema Information
#
# Table name: purchases
#
#  id                  :bigint(8)        not null, primary key
#  purchased_from      :string
#  comment             :text
#  organization_id     :integer
#  storage_location_id :integer
#  amount_spent_in_cents        :integer
#  issued_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  vendor_id           :integer
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
        item = evaluator.item || purchase.storage_location.inventory_items.first.item
        purchase.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: purchase)
      end
    end
  end
end
