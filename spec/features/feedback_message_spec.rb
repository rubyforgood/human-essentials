RSpec.feature "Feedback Message", type: :feature do
  before do
    sign_in(@user)
  end
  let(:url_prefix) { "/#{@organization.to_param}" }

  context "While viewing the barcode items index page" do
    before do
      @visited_url = url_prefix + "/barcode_items"
      visit @visited_url
    end

    scenario "stores feedback" do
      expect(FeedbackMessage.count).to eql 0
      find(".fa-bug").click
      expect(page).to have_content "Submit your bug/message/input"
      find("#feedback_message_message").set "I have some feedback!"
      click_on "Send Message"
      feedback_message = FeedbackMessage.first
      expect(feedback_message.created_at).to_not be_nil
      expect(feedback_message.message).to_not be_nil
      expect(feedback_message.user).to_not be_nil
      expect(feedback_message.path).to_not be_nil
      expect(feedback_message.message).to eql "I have some feedback!"
      expect(feedback_message.user).to eql @user
      expect(feedback_message.path.include?(@visited_url)).to be true
    end
  end
end
