# == Schema Information
#
# Table name: items
#
#  id                             :integer          not null, primary key
#  name                           :string
#  category                       :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  barcode_count                  :integer
#  organization_id                :integer
#  active                         :boolean          default(TRUE)
#  partner_key                    :string
#  value_in_cents                 :integer          default(0)
#  on_hand_minimum_quantity       :integer          default(0)
#  on_hand_recommended_quantity   :integer
#  package_size                   :integer
#  distribution_quantity          :integer
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
