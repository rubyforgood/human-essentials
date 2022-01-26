# == Schema Information
#
# Table name: questions
#
#  id           :bigint           not null, primary key
#  for_banks    :boolean          default(TRUE), not null
#  for_partners :boolean          default(TRUE), not null
#  title        :string           not null
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
