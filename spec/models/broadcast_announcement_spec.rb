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
#  organization_id :bigint
#  user_id         :bigint           not null
#
require "rails_helper"

RSpec.describe BroadcastAnnouncement, type: :model do
  it { should belong_to(:organization).optional }
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

  context "expired?" do
    it "should be true if the announcement is expired" do
      test_a = build(:broadcast_announcement, expiry: 2.days.ago)
      expect(test_a.expired?).to eq(true)
    end

    it "should be false if the announcement has not expired" do
      test_a = build(:broadcast_announcement, expiry: Time.zone.today)
      expect(test_a.expired?).to eq(false)
    end
  end

  context "filter_announcements" do
    it "should include only announcements from the passed organization and from admins" do
      BroadcastAnnouncement.create!(message: "test", user_id: 1, organization_id: 1)
      BroadcastAnnouncement.create!(message: "test", user_id: 1, organization_id: 1)
      BroadcastAnnouncement.create!(message: "test", user_id: 1)
      BroadcastAnnouncement.create!(message: "test", user_id: 1, organization_id: 2)
      expect(BroadcastAnnouncement.filter_announcements(1).count).to eq(3)
    end

    it "shouldn't include expired announcements" do
      BroadcastAnnouncement.create!(message: "test", user_id: 1, organization_id: 1)
      BroadcastAnnouncement.create!(message: "test", user_id: 1, expiry: 2.days.ago, organization_id: 1)
      BroadcastAnnouncement.create!(message: "test", user_id: 1, expiry: 5.days.ago, organization_id: 1)
      BroadcastAnnouncement.create!(message: "test", user_id: 1, expiry: Time.zone.today, organization_id: 1)
      expect(BroadcastAnnouncement.filter_announcements(1).count).to eq(2)
    end
  end
end
