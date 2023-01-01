# == Schema Information
#
# Table name: partner_counties
#
#  id           :bigint           not null, primary key
#  client_share :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  county_id    :bigint           not null
#  partner_id   :bigint           not null
#
FactoryBot.define do
  factory :partner_county do
    association :partner
    association :county
    client_share { 1 }
  end
end
