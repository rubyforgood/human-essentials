require "rails_helper"

RSpec.describe "BroadcastAnnouncements", type: :request do
  before(:all) do
    @test_a = create(:broadcast_announcement, link: "http://google.com")
  end

  it "creates an announcement" do
    expect(@test_a).to be_valid
  end

  it "can find an announcement" do
    expect(BroadcastAnnouncement.find_by(message: "test")).to eq(@test_a)
  end

  it "deletes an announcement" do
    @test_a.destroy
    expect(BroadcastAnnouncement.count).to eq(0)
  end
end
