# == Schema Information
#
# Table name: line_items
#
#  id              :bigint(8)        not null, primary key
#  quantity        :integer
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :line_item do
    quantity { 1 }
    item

    trait :donation do
      itemizable_type { "Donation" }
      itemizable_id { create(:donation).id }
    end

    trait :purchase do
      itemizable_type { "Purchase" }
      itemizable_id { create(:purchase).id }
    end

    trait :distribution do
      itemizable_type { "Distribution" }
      itemizable_id { create(:distribution).id }
    end

    trait :adjustment do
      itemizable_type { "Adjustment" }
      itemizable_id { create(:adjustment).id }
    end

    trait :audit do
      itemizable_type { "Audit" }
      itemizable_id { create(:audit).id }
    end

    trait :transfer do
      itemizable_type { "Transfer" }
      itemizable_id { create(:transfer).id }
    end
  end
end
