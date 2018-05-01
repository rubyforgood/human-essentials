# == Schema Information
#
# Table name: canonical_items
#
#  id            :integer          not null, primary key
#  key           :string
#  name          :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :canonical_item do
    sequence(:name) { |size| "#{size}T Diapers" }
    sequence(:key) { |k| "#{k}foo" }
  end
end
