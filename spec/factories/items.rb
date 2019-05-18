# == Schema Information
#
# Table name: items
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  category        :string
#  created_at      :datetime
#  updated_at      :datetime
#  barcode_count   :integer
#  organization_id :integer
#  active          :boolean          default(TRUE)
#  partner_key     :string
#  value           :integer    default(0)
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
