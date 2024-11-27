# == Schema Information
#
# Table name: units
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
FactoryBot.define do
  factory :unit do
    sequence(:name) { |n| "Unit #{n}" }
    organization
  end
end
