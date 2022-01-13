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
class Question < ApplicationRecord
  has_rich_text :content
  validates :content, presence: true
  validates :title, presence: true
  validates :for_banks, acceptance: { message: "and for partners can't both be unchecked" }, unless: :for_partners
  validates :for_partners, acceptance: { message: "and for banks can't both be unchecked" }, unless: :for_banks

  def self.questions_for_banks(questions)
    questions.select { |question| question&.for_banks }
  end

  def self.questions_for_partners
    Question.all.select { |question| question&.for_partners }
  end
end
