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

  describe "POST #create" do
    let(:params) do
      {user: {name: "New User", email: "new_partner_email@example.com"}}
    end

    it "creates a new user" do
      post partners_users_path, params: params

      aggregate_failures do
        expect(response.request.flash[:success]).to eq "You have invited New User to join your organization!"
        expect(response).to redirect_to(partners_users_path)
      end
    end

    context "when the user already exists" do
      let(:user) { create(:user, name: "Existing User") }

      let(:params) do
        {user: {name: user.name, email: user.email}}
      end

      it "creates a new user" do
        post partners_users_path, params: params

        aggregate_failures do
          expect(response.request.flash[:success]).to eq "You have invited Existing User to join your organization!"
          expect(response).to redirect_to(partners_users_path)
          expect(user.roles.count).to eq(2)
        end
      end

      context "when org user had role removed" do
        before do
          post remove_user_organization_path(user_id: user.id)
        end

        it "adds role to user" do
          post partners_users_path, params: params

          aggregate_failures do
            expect(response.request.flash[:success]).to eq "You have invited Existing User to join your organization!"
            expect(response).to redirect_to(partners_users_path)
            expect(user.roles.count).to eq(2)
          end
        end
      end
    end
  end
end
