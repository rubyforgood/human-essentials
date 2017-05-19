# == Schema Information
#
# Table name: line_items
#
#  id              :integer          not null, primary key
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#

FactoryGirl.define do
  factory :line_item do
    quantity 0
    item
    itemizable_type "Donation"
    itemizable_id { create(:donation).id }

    trait :donation do
    end

    trait :distribution do
      itemizable_type "Distribution"
      itemizable_id { create(:distribution).id }
    end
  end
end
