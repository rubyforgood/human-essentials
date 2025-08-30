# == Schema Information
#
# Table name: items
#
#  id                           :integer          not null, primary key
#  active                       :boolean          default(TRUE)
#  additional_info              :text
#  barcode_count                :integer
#  distribution_quantity        :integer
#  name                         :string
#  on_hand_minimum_quantity     :integer          default(0), not null
#  on_hand_recommended_quantity :integer
#  package_size                 :integer
#  partner_key                  :string
#  reporting_category           :string
#  value_in_cents               :integer          default(0)
#  visible_to_partners          :boolean          default(TRUE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  item_category_id             :integer
#  kit_id                       :integer
#  organization_id              :integer
#

FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "#{n}Dont test this" }
    organization { Organization.try(:first) || create(:organization) }
    partner_key { nil }
    reporting_category { kit ? nil : "disposable_diapers" }
    kit { nil }

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end

    trait :with_unit do
      transient do
        unit { "pack" }
      end
      after(:create) do |item, evaluator|
        create(:item_unit, name: evaluator.unit, item: item)
      end
    end
  end
end
