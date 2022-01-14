# == Schema Information
#
# Table name: questions
#
#  id           :bigint           not null, primary key
#  for_banks    :boolean
#  for_partners :boolean
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :question do
    title { "question" }
    for_banks { true }
    for_partners { false }
    answer { "content" }
  end
end
