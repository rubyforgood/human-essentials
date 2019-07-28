# == Schema Information
#
# Table name: feedback_messages
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)
#  message    :string
#  path       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  resolved   :boolean
#

# == No Schema Information
#

RSpec.describe FeedbackMessage, type: :model do
  let(:user) { FactoryBot.build(:user) }

  describe "relations and attributes" do
    it "belongs to a user" do
      expect(user.feedback_messages.count).to eql 0
      FeedbackMessage.create(message: "Hello Earthlings!", user: user, path: "/fakepath/1")
      expect(user.reload.feedback_messages.count).to eql 1
    end

    it "stores it's attributes" do
      feedback_message = FeedbackMessage.create(message: "Greetings Earthlings!", user: user, path: "/fakepath/2")
      expect(feedback_message.message).to eql("Greetings Earthlings!")
      expect(feedback_message.user).to eql user
      expect(feedback_message.path).to eql "/fakepath/2"
    end
  end
end
