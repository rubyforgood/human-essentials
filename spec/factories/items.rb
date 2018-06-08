# == Schema Information
#
# Table name: items
#
#  id                :bigint(8)        not null, primary key
#  name              :string
#  category          :string
#  created_at        :datetime
#  updated_at        :datetime
#  barcode_count     :integer
#  organization_id   :integer
#  canonical_item_id :integer
#  active            :boolean          default(TRUE)
#

FactoryBot.define do
  factory :item do
    canonical_item { CanonicalItem.first }
    sequence(:name) { |n| "#{n}T Diapers" }
    category "disposable"
    organization { Organization.try(:first) || create(:organization) }
  end
end
