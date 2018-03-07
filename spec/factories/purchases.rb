# == Schema Information
#
# Table name: purchases
#
#  id                  :integer          not null, primary key
#  purchased_from      :string
#  comment             :text
#  organization_id     :integer
#  storage_location_id :integer
#  amount_spent        :integer
#  issued_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :purchase do
    comment "It's a fine day for diapers."
    purchased_from "Google"
    storage_location
    organization { Organization.try(:first) || create(:organization) }
    issued_at nil
    amount_spent 10

    transient do
      item_quantity 10
      item_id nil
    end

    trait :with_item do
      after(:create) do |instance, evaluator|
        item_id = (evaluator.item_id.nil?) ? create(:item).id : evaluator.item_id
        instance.line_items << create(:line_item, :purchase, quantity: evaluator.item_quantity, item_id: item_id)
      end
    end
  end
end
