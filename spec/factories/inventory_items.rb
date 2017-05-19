# == Schema Information
#
# Table name: inventory_items
#
#  id           :integer          not null, primary key
#  quantity     :integer
#  created_at   :datetime
#  updated_at   :datetime
#  inventory_id :integer
#  item_id      :integer
#

FactoryGirl.define do
  factory :inventory_item do
    quantity 300
    item
    inventory
  end
end
