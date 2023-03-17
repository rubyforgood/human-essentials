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
    context "with valid email format" do
      it "successfully invites a new user and sets a flash message", :aggregate_failures do
        user_params = {user: {name: "New User", email: "newuser@example.com"}}
        post partners_users_path, params: user_params

        expect(response).to redirect_to(partners_users_path)
        expect(response.request.flash[:success]).to eq "You have invited #{user_params[:user][:name]} to join your organization!"
      end
    end

    context "with invalid email format" do
      it "does not invite a new user and sets an error flash message for invalid email formats", :aggregate_failures do
        invalid_emails = [
          "invaliduser@.example",
          "invalid@user@example.com",
          "user@domain",
          "user@.com",
          "u@domain.com",
          "user@domain..com",
          ",123asd@dom.com",
          "user@d.c.co",
          "invalid@@com.com",
          "user@domain._com",
          "user@domain.com_",
          "user@.domain.com",
          "user@domain.com..",
          "user@domain.-com",
          "user@domain.com-"
        ]

        invalid_emails.each do |email|
          post partners_users_path, params: {user: {name: "Invalid User", email: email}}

          expect(response).to redirect_to(new_partners_user_path)
          expect(response.request.flash[:error]).to eq "Invalid email format. Please enter a valid email address."
        end
      end
    end
  end
end
