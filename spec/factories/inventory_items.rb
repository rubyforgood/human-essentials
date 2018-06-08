# == Schema Information
#
# Table name: inventory_items
#
#  id                  :bigint(8)        not null, primary key
#  storage_location_id :integer
#  item_id             :integer
#  quantity            :integer
#  created_at          :datetime
#  updated_at          :datetime
#

FactoryBot.define do
  factory :inventory_item do
    quantity 300
    item
    storage_location
  end
end
