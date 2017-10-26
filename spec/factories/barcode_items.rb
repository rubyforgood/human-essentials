# == Schema Information
#
# Table name: barcode_items
#
#  id              :integer          not null, primary key
#  value           :string
#  item_id         :integer
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

FactoryGirl.define do

  factory :barcode_item do
    organization nil
    sequence(:value) { |n| "#{n}" * 12 } # 037000863427
    item
    quantity 50

    trait :for_organization do
      organization { Organization.try(:first) || create(:organization) }
    end
  end
end
