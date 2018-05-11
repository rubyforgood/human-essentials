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
#  global          :boolean          default(FALSE)
#
FactoryBot.define do

  factory :barcode_item do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:value) { |n| "#{n}" * 12 } # 037000863427
    item nil
    quantity 50

    after(:build) do |instance, evaluator|
	    instance.item = evaluator.item || create(:item, organization: instance.organization, canonical_item: CanonicalItem.first)
    end
  end
end
