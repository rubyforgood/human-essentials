# == Schema Information
#
# Table name: manufacturers
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  organization_id :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :manufacturer do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:name) { |n| "Manufacturer #{n}" }
  end
end
