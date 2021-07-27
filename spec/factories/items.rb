# == Schema Information
#
# Table name: items
#
#  id                           :integer          not null, primary key
#  active                       :boolean          default(TRUE)
#  barcode_count                :integer
#  category                     :string
#  distribution_quantity        :integer
#  name                         :string
#  on_hand_minimum_quantity     :integer          default(0), not null
#  on_hand_recommended_quantity :integer
#  package_size                 :integer
#  partner_key                  :string
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
    sequence(:name) { |n| "#{n}T Diapers" }
    organization { Organization.try(:first) || create(:organization) }
    partner_key { BaseItem.first&.partner_key || create(:base_item).partner_key }

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end
  end
end
