RSpec.feature "Admin Feedback Message Management" do
  context "While signed in as an Administrative User (super admin)" do
    before :each do
      sign_in(@super_admin)
    end

    scenario "viewing and marking feedback as resolved", js: true do
      feedback_message = FactoryBot.create(:feedback_message)
      visit admin_feedback_messages_path

      expect(feedback_message.resolved).to eq(false)
      expect(page).to have_content("Feedback message that has been left")
      expect(page).to have_content("https://example.com/diaperbank/dashboard")

      # mark the feedback as resolved
      check "Resolved"
      visit current_path
      feedback_message.reload
      expect(feedback_message.resolved).to eq(true)
    end
  end
end