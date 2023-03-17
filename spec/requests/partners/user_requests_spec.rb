require "rails_helper"

RSpec.describe "/partners/users", type: :request do
  let(:partner) { create(:partner) }
  let(:partner_user) { partner.primary_user }

  before do
    sign_in(partner_user)
  end
  describe "GET #edit" do
    it "successfully loads the page" do
      get edit_partners_user_path(partner_user)
      expect(response).to be_successful
    end
  end

  describe "PATCH #update" do
    it "lets the name be updated", :aggregate_failures do
      patch partners_user_path(
        id: partner_user.id,
        user: {
          name: "New name"
        }
      )
      expect(response).to be_redirect
      expect(response.request.flash[:success]).to eq "User information was successfully updated!"
      partner_user.reload
      expect(partner_user.name).to eq "New name"
    end
  end
end
