# == Schema Information
#
# Table name: questions
#
#  id         :bigint           not null, primary key
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :question do
    title { "Dont test this" }
    answer { "Dont test this" }
  end
end
