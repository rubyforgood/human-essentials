# == Schema Information
#
# Table name: account_requests
#
#  id                   :bigint           not null, primary key
#  email                :string           not null
#  organization_name    :string           not null
#  organization_website :string
#  request_details      :text             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

FactoryBot.define do
  factory :account_request do
    sequence(:email) { Faker::Internet.unique.email }
    organization_name { Faker::Company.name }
    organization_website { Faker::Internet.domain_name }
    request_details { Faker::Lorem.paragraphs }
  end
end

