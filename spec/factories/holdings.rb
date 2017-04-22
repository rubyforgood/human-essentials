# == Schema Information
#
# Table name: holdings
#
#  id           :integer          not null, primary key
#  quantity     :integer
#  created_at   :datetime
#  updated_at   :datetime
#  inventory_id :integer
#  item_id      :integer
#

FactoryGirl.define do
  factory :holding do
    quantity 300
    item
    inventory
  end
end
