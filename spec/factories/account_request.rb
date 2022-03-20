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
    name { Faker::Name.unique.name }
    email { Faker::Internet.unique.email }
    organization_name { Faker::Company.unique.name }
    organization_website { Faker::Internet.unique.url }
    request_details { Faker::Lorem.unique.paragraphs.join(", ") }
  end
end

