# == Schema Information
#
# Table name: base_items
#
#  id                 :bigint           not null, primary key
#  barcode_count      :integer
#  category           :string
#  item_count         :integer
#  name               :string
#  partner_key        :string
#  reporting_category :string
#  size               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

FactoryBot.define do
  factory :base_item do
    sequence(:name) { |size| "#{size}Dont test this" }
    size { nil }
    sequence(:partner_key) { |n| "#{n}dont_test_this" }
  end
end
