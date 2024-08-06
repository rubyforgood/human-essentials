RSpec.describe "Admin::Questions", type: :request do
  context "while signed in as a super admin" do
    before do
      sign_in(create(:super_admin, organization: nil))
    end

    describe "GET #index" do
      it "lets the user load the page" do
        get admin_questions_path
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "lets the user load the new question page" do
        get new_admin_question_path
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      it "lets the user create questions" do
        post admin_questions_path(question: attributes_for(:question))
        expect(response).to be_redirect
        expect(Question.all.count).to eq 1
      end
    end

    describe "GET #edit" do
      it "lets the user load the edit question page" do
        question = create(:question)
        get edit_admin_question_path(question)
        expect(response).to be_successful
      end
    end

    describe "PATCH #update" do
      it "lets the user update questions" do
        question = create(:question)
        patch admin_question_path(
          {
            id: question.id,
            question: {
              title: "updated question",
              for_banks: false,
              for_partners: true
            }
          }
        )
        expect(response).to be_redirect
        question.reload
        expect(question.title).to eq "updated question"
        expect(question.for_banks).to eq false
        expect(question.for_partners).to eq true
      end
    end

    describe "DELETE #destroy" do
      it "lets the user delete questions" do
        question = create(:question)
        delete admin_question_path(question)
        expect(response).to be_redirect
        expect(Question.all.count).to eq 0
      end
    end
  end
end
