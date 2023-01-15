# == Schema Information
#
# Table name: served_areas
#
#  id                 :bigint           not null, primary key
#  client_share       :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  county_id          :bigint           not null
#  partner_profile_id :bigint           not null
#
FactoryBot.define do
  factory :partners_served_area, class: "Partners::ServedArea" do
    association :partner_profile
    association :county
    client_share { 1 }
  end
end
