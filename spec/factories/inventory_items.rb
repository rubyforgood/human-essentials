# == Schema Information
#
# Table name: inventory_items
#
#  id                  :integer          not null, primary key
#  quantity            :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  item_id             :integer
#  storage_location_id :integer
#

FactoryBot.define do
  factory :inventory_item do
    quantity { 300 }
    item
    storage_location
  end
end
