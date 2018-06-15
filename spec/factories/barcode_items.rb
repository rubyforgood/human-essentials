# == Schema Information
#
# Table name: barcode_items
#
#  id               :bigint(8)        not null, primary key
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
    sequence(:value) { (SecureRandom.random_number * (10**12)).to_i } # 037000863427
    quantity 50
    barcodeable { create(:canonical_item) }
    global true
    # after(:build) do |instance, evaluator|
    #   instance.barcodeable = evaluator.barcodeable || create(:canonical_item, organization: instance.organization)
    # end
  end

  factory :barcode_item, class: "BarcodeItem" do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:value) { (SecureRandom.random_number * (10**12)).to_i } # 037000863427
    quantity 50
    barcodeable nil # { create(:item, organization: organization) }
    global false

    after(:build) do |instance, evaluator|
      instance.barcodeable = evaluator.barcodeable || create(:item,
                                                             organization: (instance.organization || Organization.try(:first)),
                                                             canonical_item: (CanonicalItem.try(:first) || create(:canonical_item)))
    end
  end
end
