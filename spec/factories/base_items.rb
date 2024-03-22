# == Schema Information
#
# Table name: base_items
#
#  id            :bigint           not null, primary key
#  barcode_count :integer
#  category      :string
#  item_count    :integer
#  name          :string
#  partner_key   :string
#  size          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :base_item do
    # TODO: Can this use Faker? This makes
    # it a pain in the ass to make items
    sequence(:name) { |size| "#{size}T Diapers" }
    size { nil }
    sequence(:partner_key) { |n| "#{n}t_diapers" }
  end
end
