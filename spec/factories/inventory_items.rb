# == Schema Information
#
# Table name: inventory_items
#
#  id                  :integer          not null, primary key
#  storage_location_id :integer
#  item_id             :integer
#  quantity            :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :inventory_item do
    quantity { 300 }
    item
    storage_location
  end
end
