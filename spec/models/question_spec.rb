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
require "rails_helper"

RSpec.describe Question, type: :model do
  describe "scope for_partners" do
    it "should filter out questions that aren't meant for partners" do
      question_1 = build(:question)
      question_1.update(for_partners: false)
      question_1.update(for_banks: true)

      question_2 = build(:question)
      question_2.update(for_partners: true)
      question_2.update(for_banks: false)

      question_3 = build(:question)
      question_3.update(for_partners: true)
      question_3.update(for_banks: true)

      partner_questions = Question.for_partners

      expect(partner_questions.count).to eq 2
      expect(partner_questions.first.for_partners).to eq true
      expect(partner_questions.last.for_partners).to eq true
    end
  end

  describe "scope for_banks" do
    it "should filter out questions that aren't meant for banks" do
      question_1 = build(:question)
      question_1.update(for_partners: false)
      question_1.update(for_banks: true)

      question_2 = build(:question)
      question_2.update(for_partners: true)
      question_2.update(for_banks: false)

      question_3 = build(:question)
      question_3.update(for_partners: true)
      question_3.update(for_banks: true)

      bank_questions = Question.for_banks

      expect(bank_questions.count).to eq 2
      expect(bank_questions.first.for_banks).to eq true
      expect(bank_questions.last.for_banks).to eq true
    end
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:answer) }

    it "question for_banks and for_partners attributes can't both be false" do
      question = build(:question)
      question.update(for_partners: false)
      question.update(for_banks: false)
      expect(question).to_not be_valid
    end
  end
end
