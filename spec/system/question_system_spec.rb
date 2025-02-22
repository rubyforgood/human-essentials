RSpec.describe "Question search", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "while logged in" do
    before do
      sign_in(user)
    end

    it "filters by question title" do
      question_1 = FactoryBot.create(:question, title: "first")
      question_2 = FactoryBot.create(:question, title: "second")
      question_3 = FactoryBot.create(:question, title: "third")

      visit help_path

      [question_1, question_2, question_3].each do |question|
        expect(page).to have_content(question.title)
      end

      fill_in "filterrific_search_title", with: "ir"

      expect(page).not_to have_content(question_2.title)
      [question_1, question_3].each do |question|
        expect(page).to have_content(question.title)
      end

      fill_in "filterrific_search_title", with: "nd"

      expect(page).to have_content(question_2.title)
      [question_1, question_3].each do |question|
        expect(page).not_to have_content(question.title)
      end

      fill_in "filterrific_search_title", with: "yz"

      [question_1, question_2, question_3].each do |question|
        expect(page).not_to have_content(question.title)
      end
    end
  end
end
