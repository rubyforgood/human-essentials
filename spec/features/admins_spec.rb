RSpec.feature "Site Administration", type: :feature do
  before do
    sign_in(@organization_admin)
    visit '/admins'
  end

  scenario "Admin can create a new organization" do
    click_link "Add New Organization"
    org_params = attributes_for(:organization)
    fill_in "Name", with: org_params["name"]
    fill_in "Short name", with: org_params["short_name"]
    fill_in "Url", with: org_params["url"]
    fill_in "Email", with: org_params["email"]
    fill_in "Address", with: org_params["address"]
    click_button "Create"

    expect(page).to have_content(org_params["name"])
    expect(page).to have_current_path(admins_path)
  end

  scenario "Admin can bail back to their own site" do
    expect(page).to have_xpath("//a[@href='#{dashboard_path(organization_id: @organization.to_param)}']")
  end

  scenario "An admin can edit the properties for an organization" do
    click_link "Edit"
    fill_in "Name", with: "Something else"
    click_button "Update"
    expect(page).to have_content("pdated organization")
    expect(page).to have_content("Something else")
  end

  context "When looking at a single organization" do
    before do
      @organization.users << create(:user, email: "yet_another_user@website.com")
      visit admin_path(@organization.id)
    end
    scenario "Admin can view details about an organization, including the users" do
      expect(page).to have_content(@organization.email)
      expect(page).to have_content(@organization.address)
      @organization.users.each do |u|
        expect(page).to have_content(u.email)
      end
    end

    scenario "An admin can add a new user to an organization" do
      page.find('a', text: "Invite User to this Organization").click
      allow(User).to receive(:invite!).and_return(true)
      within "#addUserModal" do
        fill_in "email", with: "some_new_user@website.com"
        click_button "Submit"
      end
      expect(page).to have_content("invited to organization")
    end


  end



end
