# == Schema Information
#
# Table name: counties
#
#  id         :bigint           not null, primary key
#  name       :string
#  region     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :county do
    sequence(:name) { |n| "County #{n}" }
    region { Faker::Address.state }
  end
end
