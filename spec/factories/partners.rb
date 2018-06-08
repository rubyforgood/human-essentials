# == Schema Information
#
# Table name: partners
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  email           :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Leslie Sue, the #{n}" }
    sequence(:email) { |n| "leslie#{n}@gmail.com" }
    organization { Organization.try(:first) || create(:organization) }
  end
end
