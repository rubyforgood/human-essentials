require "rails_helper"

RSpec.describe "/partners/users", type: :request do
  let(:partner) { create(:partner) }
  let(:partner_user) { Partners::Partner.find_by(partner_id: partner.id).primary_user }

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

  describe "GET #switch_to_bank_role" do
    context "with a bank role" do
      it "should redirect to the bank path" do
        partner_user.update!(organization_id: @organization.id)
        get switch_to_bank_role_partners_users_path
        expect(response).to redirect_to(dashboard_path(@organization))
      end
    end

    context "without a bank role" do
      it "should redirect to the root path with an error" do
        get switch_to_bank_role_partners_users_path
        message = "Attempted to switch to a bank role but you have no bank associated with your account!"
        expect(flash[:alert]).to eq(message)
        expect(response).to redirect_to("/")
      end
    end
  end
end
