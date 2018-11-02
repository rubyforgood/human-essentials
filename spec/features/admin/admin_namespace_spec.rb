RSpec.feature "Admin Namespace" do
  context "While signed in as an Administrative User (super admin)" do
    before do
      sign_in(@super_admin)
    end
  end

  context "While signed in as an Administrative User with no organzation (super admin no org)" do
    before do
      sign_in(@super_admin_no_org)
    end
  end

  context "While signed in as a normal user" do
    before do
      sign_in(@user)
    end
  end

  context "While signed in as an organizational admin" do
    before do
      sign_in(@organization_admin)
    end
  end
end