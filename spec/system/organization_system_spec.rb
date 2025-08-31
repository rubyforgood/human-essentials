RSpec.describe "Organization management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let(:super_admin_org_admin) { create(:super_admin_org_admin, organization: organization) }

  include ActionView::RecordIdentifier

  shared_examples "organization role management checks" do |user_factory|
    let!(:managed_user) { create(user_factory, name: "User to be managed", organization: organization) }

    it 'can remove that user from the organization' do
      visit organization_path
      accept_confirm do
        click_button dom_id(managed_user, "dropdownMenu")
        click_button "Remove User"
      end

      expect(page).to have_content("User has been removed!")
      expect(managed_user.has_role?(Role::ORG_USER)).to be false
    end

    it "can promote that user from the organization" do
      visit organization_path
      accept_confirm do
        click_button dom_id(managed_user, "dropdownMenu")
        click_button "Promote to Admin"
      end

      expect(page).to have_content("User has been promoted!")
      expect(managed_user.has_role?(Role::ORG_ADMIN, organization)).to be true
    end

    it "can demote that user from the organization" do
      managed_user.add_role(Role::ORG_ADMIN, organization)
      visit organization_path
      accept_confirm do
        click_button "Demote to User"
      end

      expect(page).to have_content("User has been demoted!")
      expect(managed_user.has_role?(Role::ORG_ADMIN, organization)).to be false
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    it "can add a new user to an organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit organization_path
      click_on "Invite User to this Organization"
      within "#addUserModal" do
        fill_in "email", with: "some_new_user@website.com"
        click_on "Invite User"
      end
      expect(page).to have_content("invited to organization")
    end

    context "managing a user from the organization" do
      include_examples "organization role management checks", :user
    end

    context "managing a super admin user from the organization" do
      include_examples "organization role management checks", :super_admin
    end
  end

  context "while signed in as a super admin" do
    before do
      sign_in(super_admin_org_admin)
    end

    before(:each) do
      visit admin_dashboard_path
      within ".main-header" do
        click_on super_admin_org_admin.name.to_s
      end
      click_link "Switch to: #{organization.name}"
    end

    context "managing a user from the organization" do
      include_examples "organization role management checks", :user
    end

    context "managing a super admin user from the organization" do
      include_examples "organization role management checks", :super_admin
    end
  end
end
