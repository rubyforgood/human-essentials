# == Schema Information
#
# Table name: articles
#
#  id           :bigint           not null, primary key
#  for_banks    :boolean
#  for_partners :boolean
#  question     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :article do
    question { "question" }
    for_banks { true }
    for_partners { false }
    content { "content" }
  end
end
