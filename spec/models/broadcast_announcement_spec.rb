# == Schema Information
#
# Table name: broadcast_announcements
#
#  id              :bigint           not null, primary key
#  expiry          :date
#  link            :text
#  message         :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#
require 'rails_helper'

RSpec.describe BroadcastAnnouncement, type: :model do
    it { should belong_to(:organization) }
    it { should belong_to(:user) }
    it { should validate_presence_of(:message) }

    it "should roughly check if link is valid" do
      test_a = build(:broadcast_announcement, link: "notalink")
      expect(test_a).not_to be_valid 
    end

    it "should validate a good link" do
      test_a = build(:broadcast_announcement, link: "https://google.com")
      expect(test_a).to be_valid
    end

    it "should validate a valid announcement" do
      test_a = build(:broadcast_announcement)
      expect(test_a).to be_valid
    end
end
