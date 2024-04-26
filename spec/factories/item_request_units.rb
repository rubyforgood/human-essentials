# == Schema Information
#
# Table name: item_request_units
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  item_id    :bigint
#
FactoryBot.define do
  factory :item_request_unit do
    sequence(:name) { |n| "Unit #{n}" }
    item
  end
end
