RSpec.shared_examples "restricts access to organization users/admins" do
  context "when signed in as partner" do
    let(:partner) { create(:partner) }
    let(:partner_user) { partner.primary_user }

    before do
      sign_in(partner_user)
    end

    it "redirects partners to their dashboard with a flash message" do
      expect(subject).to redirect_to(partners_dashboard_path)
      expect(flash[:error]).to eq("That screen is not available. Please try again as a bank.")
    end
  end

  context "when signed in as super admin" do
    let(:super_admin) { create(:super_admin) }

    before do
      sign_in(super_admin)
    end

    it "redirects admins to their dashboard with a flash message" do
      expect(subject).to redirect_to(admin_dashboard_path)
      expect(flash[:error]).to eq("That screen is not available. Please try again as a bank.")
    end
  end
end
