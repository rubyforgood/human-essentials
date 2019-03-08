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
#  weight_in_grams :integer
#

FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "#{n}T Diapers" }
    category { "disposable" }
    organization { Organization.try(:first) || create(:organization) }
    partner_key { CanonicalItem.first&.partner_key || create(:canonical_item).partner_key }
  end
end
