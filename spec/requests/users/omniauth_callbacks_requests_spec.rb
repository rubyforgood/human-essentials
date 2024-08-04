RSpec.describe "Users - Omniauth Callbacks", type: :request do
  before do
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        name: "Me Me",
        email: "me@me.com"
      },
      credentials: {
        token: "token",
        refresh_token: "refresh token"
      }
    })
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe "GET #google_oauth2" do
    context "with a valid user" do
      it "redirects correctly" do
        organization = create(:organization)
        create(:user, email: "me@me.com", organization: organization)

        post "/users/auth/google_oauth2/callback"

        expect(session["google.token"]).to eq("token")
        expect(session["google.refresh_token"]).to eq("refresh token")
        expect(response).to redirect_to(root_path)
      end
    end

    context "without a valid user" do
      it "should redirect to new registration URL" do
        post "/users/auth/google_oauth2/callback"

        expect(response).to redirect_to(new_user_registration_url)
        expect(flash[:alert]).to eq("Authentication failed: User not found!")
      end
    end
  end
end
