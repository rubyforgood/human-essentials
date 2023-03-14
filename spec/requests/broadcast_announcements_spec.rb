require "rails_helper"

RSpec.describe "BroadcastAnnouncements", type: :request do
  before do
    sign_in(@user)
  end
  let(:valid_attributes) {
    {
      expiry: Time.zone.today,
      link: "http://google.com",
      message: "test",
      user_id: 1,
      organization_id: 1
    }
  }

  let(:invalid_attributes) {
    {
      link: "badlink.com"
    }
  }

  describe "GET /index" do
    it "renders a successful response" do
      BroadcastAnnouncement.create! valid_attributes
      get broadcast_announcements_url
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_broadcast_announcement_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "render a successful response" do
      announcement = BroadcastAnnouncement.create! valid_attributes
      get edit_broadcast_announcement_url(announcement)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new BroadcastAnnouncement then redirects" do
        expect {
          post broadcast_announcements_url, params: {broadcast_announcement: valid_attributes}
        }.to change(BroadcastAnnouncement, :count).by(1)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "with invalid parameters" do
      it "does not create a new BroadcastAnnouncement" do
        expect {
          post broadcast_announcements_url, params: {broadcast_announcement: invalid_attributes}
        }.to change(BroadcastAnnouncement, :count).by(0)
      end

      it "does not render a successful response" do
        post broadcast_announcements_url, params: {broadcast_announcement: invalid_attributes}
        expect(response).not_to be_successful
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        {
          expiry: Time.zone.yesterday,
          link: "http://google.com",
          message: "new_test",
          user_id: 1,
          organization_id: 1
        }
      }

      it "updates the requested announcement and redirects" do
        announcement = BroadcastAnnouncement.create! valid_attributes
        patch broadcast_announcement_url(announcement), params: {broadcast_announcement: new_attributes}
        announcement.reload
        expect(announcement.message).to eq("new_test")
        expect(response).to have_http_status(:redirect)
      end
    end

    context "with invalid parameters" do
      it "does not render a successful response" do
        announcement = BroadcastAnnouncement.create! valid_attributes
        patch broadcast_announcement_url(announcement), params: {broadcast_announcement: invalid_attributes}
        expect(response).not_to be_successful
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested announcement then redirects" do
      announcement = BroadcastAnnouncement.create! valid_attributes
      expect {
        delete broadcast_announcement_url(announcement)
      }.to change(BroadcastAnnouncement, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end
end
