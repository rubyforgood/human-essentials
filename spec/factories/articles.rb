# == Schema Information
#
# Table name: articles
#
#  id                :bigint           not null, primary key
#  for_organizations :boolean
#  for_partners      :boolean
#  question          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :article do
    sequence(:question) { |num| "question number: #{num}" }
    for_organizations { true }
    for_partners { false }
  end
end
