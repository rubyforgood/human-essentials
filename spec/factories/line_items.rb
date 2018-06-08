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
    quantity 1
    item
    itemizable_type "Donation"
    itemizable_id { create(:donation).id }

    trait :donation do
    end

    trait :purchase do
    end

    trait :distribution do
      itemizable_type "Distribution"
      itemizable_id { create(:distribution).id }
    end
  end
end
