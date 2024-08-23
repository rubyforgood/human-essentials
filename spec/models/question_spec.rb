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

  describe "remove_redundant_error" do
    it "should return an array with only one error message related to the checkboxes." do
      question = build(:question)
      errors = [
        "For banks and for partners can't both be unchecked",
        "For partners and for banks can't both be unchecked"
      ]
      expect(question.remove_redundant_error(errors)).to eq ["For partners and for banks can't both be unchecked"]
    end
  end

  describe "punctuate" do
    it "should punctuate each string in a given array" do
      sentences = [
        "This is a sentence",
        "This is another sentence",
        "This is a third sentence"
      ]
      question = build(:question)
      expect(question.punctuate(sentences)).to eq "This is a sentence. This is another sentence. This is a third sentence. "
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
