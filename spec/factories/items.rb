# == Schema Information
#
# Table name: items
#
#  id              :integer          not null, primary key
#  name            :string
#  category        :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  barcode_count   :integer
#  organization_id :integer
#  active          :boolean          default(TRUE)
#  partner_key     :string
#  value           :decimal(5, 2)    default(0.0)
#

FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "#{n}T Diapers" }
    organization { Organization.try(:first) || create(:organization) }
    partner_key { BaseItem.first&.partner_key || create(:base_item).partner_key }
  end
end
