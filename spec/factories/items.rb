# == Schema Information
#
# Table name: items
#
#  id              :integer          not null, primary key
#  name            :string
#  category        :string
#  created_at      :datetime
#  updated_at      :datetime
#  barcode_count   :integer
#  organization_id :integer
#

FactoryBot.define do
  factory :item do
    canonical_item
    sequence(:name) { |n| "#{n}T Diapers" }
    category "disposable"
    organization { Organization.try(:first) || create(:organization) }
  end
end
