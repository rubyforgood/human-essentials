# == Schema Information
#
# Table name: barcode_items
#
#  id         :integer          not null, primary key
#  value      :string
#  item_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  quantity   :integer
#

FactoryGirl.define do

  factory :barcode_item do
    sequence(:value) { |n| "#{n * 5}"}
    item
    quantity 50
  end
end
