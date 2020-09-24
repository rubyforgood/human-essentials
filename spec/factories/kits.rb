# == Schema Information
#
# Table name: kits
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE)
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
FactoryBot.define do
  factory :kit do
    name { "Test Kit" }
    organization
  end
end
