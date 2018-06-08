# == Schema Information
#
# Table name: canonical_items
#
#  id            :bigint(8)        not null, primary key
#  name          :string
#  category      :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  size          :string
#  item_count    :integer
#

FactoryBot.define do
  factory :canonical_item do
    sequence(:name) { |size| "#{size}T Diapers" }
    category "Infant Diapers"
    size nil
  end
end
