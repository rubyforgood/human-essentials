# == Schema Information
#
# Table name: item_categories
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
FactoryBot.define do
  factory :item_category do
    association :organization
    name { Faker::Appliance.unique.brand }
    description { Faker::Lorem.sentence(word_count: 30) }
  end
end
