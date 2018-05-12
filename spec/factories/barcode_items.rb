# == Schema Information
#
# Table name: barcode_items
#
#  id               :integer          not null, primary key
#  value            :string
#  barcodeable_id   :integer
#  quantity         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organization_id  :integer
#  global           :boolean          default(FALSE)
#  barcodeable_type :string           default("Item")
#

FactoryBot.define do

  factory :global_barcode_item, class: "BarcodeItem" do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:value) { |n| "#{n}" * 12 } # 037000863427
    quantity 50
    barcodeable nil

    after(:build) do |instance, evaluator|
      instance.barcodeable = evaluator.barcodeable || create(:canonical_item, organization: instance.organization)
    end
  end

  factory :barcode_item, class: "BarcodeItem" do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:value) { |n| "#{n}" * 12 } # 037000863427
    quantity 50
    barcodeable nil

    after(:build) do |instance, evaluator|
      instance.barcodeable = evaluator.barcodeable || create(:item, organization: instance.organization, canonical_item: CanonicalItem.try(:first) || create(:canonical_item))
    end
  end

end
