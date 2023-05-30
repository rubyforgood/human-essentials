# == Schema Information
#
# Table name: counties
#
#  id         :bigint           not null, primary key
#  category   :enum             default("US_County"), not null
#  name       :string
#  region     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :county do
    sequence(:name) { |n| "County #{n}" }
    region { Faker::Address.state }
    category { "US_County" }
  end
end
