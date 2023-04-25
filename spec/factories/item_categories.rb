# == Schema Information
#
# Table name: item_categories
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
FactoryBot.define do
  factory :item_category do
    association :organization
    sequence(:name) { |n| "#{Faker::Appliance.brand} #{n}" }
    description { Faker::Lorem.paragraph_by_chars(number: 250) }
  end
end
