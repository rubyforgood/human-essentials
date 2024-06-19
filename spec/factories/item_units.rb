# == Schema Information
#
# Table name: item_units
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  item_id    :bigint
#
FactoryBot.define do
  factory :item_unit do
    sequence(:name) { |n| "Unit #{n}" }
    item

    before(:create) do |unit, _|
      unit.item.organization.request_units.find_or_create_by(name: unit.name)
    end
  end
end
