# spec/requests/partner_users_controller_spec.rb

RSpec.describe PartnerUsersController, type: :request do
  let!(:partner) { create(:partner) } # Assuming you have a factory for creating partners
  let!(:user) { create(:user) } # Assuming you have a factory for creating users
  let(:default_params) do
    {organization_id: @organization.to_param}
  end

  before do
    sign_in(user)
  end

  describe "GET #index" do
    it "renders the index template and assigns @users" do
      get partner_users_path(default_params.merge(partner_id: partner))
      expect(response).to render_template(:index)
      expect(assigns(:users)).to eq(partner.users)
    end
  end

  describe "POST #create" do
    let(:valid_user_params) do
      {
        email: "meow@example.com",
        name: "Meow Mix"
      }
    end

    context "with valid user params" do
      it "invites a new user and redirects back with notice" do
        expect {
          post partner_users_path(default_params.merge(partner_id: partner)), params: {user: valid_user_params}
        }.to change(User.all, :count).by(1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("has been invited. Invitation email sent to")
      end
    end

    context "with invalid user params" do
      it "renders the index template with alert" do
        expect {
          post partner_users_path(default_params.merge(partner_id: partner)), params: {user: {email: "invalid_email"}}
        }.not_to change(User, :count)

        expect(response).to render_template(:index)
        expect(flash[:alert]).to eq("Invitation failed. Check the form for errors.")
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:partner_user) do
      UserInviteService.invite(
        email: "meow@example.com",
        name: "Meow Mix",
        roles: [Role::PARTNER],
        resource: partner
      )
    end

    it "removes the user role from the partner and redirects back with notice" do
      expect {
        delete partner_user_path(default_params.merge(partner_id: partner, id: partner_user))
      }.to change { partner_user.roles.count }.from(1).to(0)

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Access to #{partner.name} has been revoked for #{partner_user.name}.")
    end

    it "redirects back with alert if the user role removal fails" do
      allow_any_instance_of(User).to receive(:remove_role).and_return(false)

      delete partner_user_path(default_params.merge(partner_id: partner, id: partner_user))

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Invitation failed. Check the form for errors.")
    end
  end

  describe "PATCH #resend_invitation" do
    let!(:partner_user) do
      UserInviteService.invite(
        email: "meow@example.com",
        name: "Meow Mix",
        roles: [Role::PARTNER],
        resource: partner
      )
    end

    context "when the user has not accepted the invitation" do
      it "resends the invitation and redirects back with notice" do
        expect_any_instance_of(User).to receive(:invite!)

        post resend_invitation_partner_user_path(default_params.merge(partner_id: partner, id: partner_user))

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Invitation email sent to #{partner_user.email}")
      end
    end

    context "when the user has already accepted the invitation" do
      it "redirects back with alert" do
        partner_user.update!(invitation_accepted_at: Time.zone.now)

        post resend_invitation_partner_user_path(default_params.merge(partner_id: partner, id: partner_user))

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("User has already accepted invitation.")
      end
    end
  end
end
