# == Schema Information
#
# Table name: manufacturers
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

FactoryBot.define do
  factory :manufacturer do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:name) { |n| "Manufacturer #{n}" }
  end
end
