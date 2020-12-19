# == Schema Information
#
# Table name: feedback_messages
#
#  id         :bigint           not null, primary key
#  message    :text
#  path       :string
#  resolved   :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#

# == No Schema Information
#

RSpec.describe FeedbackMessage, type: :model do
  let(:user) { FactoryBot.build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_length_of(:message).is_at_least(10) }

    it "allows long messages" do
      message = FeedbackMessage.new(message: "Diapers! " * 1000, user: user)

      expect(message).to be_valid
    end
  end

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
