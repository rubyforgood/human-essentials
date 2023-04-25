describe Users::SessionsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "post create" do
    let(:user) { create :user }
    let(:role) { Object.new }

    before do
      allow(controller).to receive(:set_current_role).and_call_original
      allow(UsersRole)
        .to receive(:current_role_for)
        .with(user)
        .and_return role
      post :create, params: {user: user_params}
    end

    context "with valid credentials" do
      let(:user_params) { {email: user.email, password: user.password} }

      it "sets current role" do
        expect(controller)
          .to have_received(:set_current_role)
          .with role
      end
    end

    context "with invalid credentials" do
      let(:user_params) { {email: user.email, password: Faker::Internet.password} }

      it "does not set current role" do
        expect(controller)
          .not_to have_received :set_current_role
      end
    end
  end
end
