RSpec.describe "Users::Registrations", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe "PATCH #update" do
    before do
      sign_in(user)
    end

    it "updates the user's phone number" do
      patch user_registration_path, params: {user: {phone_number: "555-123-4567", current_password: "password!"}}

      expect(response).to redirect_to(root_path)
      expect(user.reload.phone_number).to eq("555-123-4567")
    end
  end
end
