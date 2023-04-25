describe UsersController, type: :controller do
  describe "get switch_to_role" do
    let(:user) { create :organization_admin, organization: organization }
    let(:organization) { create :organization }
    let(:role) { create :role }
    let(:switch_to_role_id) { role.id }

    before do
      sign_in user
      user.roles << role
      allow(controller)
        .to receive(:set_current_role)
        .and_call_original
      get :switch_to_role, params: {
        organization_id: organization.id,
        role_id: switch_to_role_id
      }
    end

    context "when user may access role" do
      it "sets current role" do
        expect(controller)
          .to have_received(:set_current_role)
          .with(role)
          .at_least(1).time
      end
    end

    context "when user may not access role" do
      let(:switch_to_role_id) { -1 }

      it "does not set current role" do
        expect(controller)
          .not_to have_received :set_current_role
      end
    end
  end
end
