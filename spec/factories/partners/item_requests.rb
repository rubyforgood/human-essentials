FactoryBot.define do
  factory :item_request, class: Partners::ItemRequest do
    item
    request { build(:request, organization: item.organization) }
    quantity { 5 }
    sequence(:name) { |n| "Item Request #{n}" }
    sequence(:partner_key) { |n| "partner_key#{n}" }
  end
end
