# == Schema Information
#
# Table name: barcode_items
#
#  id               :integer          not null, primary key
#  barcodeable_type :string           default("Item")
#  quantity         :integer
#  value            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  barcodeable_id   :integer
#  organization_id  :integer
#

FactoryBot.define do
  factory :global_barcode_item, class: "BarcodeItem" do
    sequence(:value) { (SecureRandom.random_number * (10**12)).to_i } # 037000863427
    quantity { 50 }
    barcodeable { BaseItem.all.sample || create(:base_item) }
    barcodeable_type { "BaseItem" }
  end

  factory :barcode_item, class: "BarcodeItem" do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:value) { (SecureRandom.random_number * (10**12)).to_i } # 037000863427
    quantity { 50 }
    barcodeable { nil }

    after(:build) do |instance, evaluator|
      instance.barcodeable = evaluator.barcodeable || create(:item,
                                                             organization: instance.organization || Organization.try(:first),
                                                             base_item: BaseItem.try(:first) || create(:base_item))
    end
  end
end
