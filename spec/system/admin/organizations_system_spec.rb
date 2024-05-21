RSpec.describe "Admin Organization Management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }
  let(:super_admin_no_org) { create(:super_admin, organization: nil) }

  let!(:foo_org) { create(:organization, name: 'foo') }
  let!(:bar_org) { create(:organization, name: 'bar') }
  let!(:baz_org) { create(:organization, name: 'baz') }

  context "While signed in as an Administrative User (super admin)" do
    before :each do
      sign_in(super_admin)
    end

    it "filters by organizations by name in organizations index page" do
      visit admin_organizations_path

      # All organizations listed on load
      [foo_org, bar_org, baz_org].each do |o|
        expect(page).to have_content(o.name)
      end

      # Searching by 'ba' should remove the 'foo' organization
      # from the organizations list but keep the 'bar' and 'baz'
      # organization listed.
      fill_in "filterrific_search_name", with: "ba"

      expect(page).not_to have_content(foo_org.name)
      [bar_org, baz_org].each do |o|
        expect(page).to have_content(o.name)
      end

      # Searching by 'bar' should only have the 'bar' organization
      # listed.
      fill_in "filterrific_search_name", with: "bar"
      [foo_org, baz_org].each do |o|
        expect(page).not_to have_content(o.name)
      end

      expect(page).to have_content(bar_org.name)
    end

    it "creates a new organization" do
      visit new_admin_organization_path
      admin_user_params = attributes_for(:organization_admin)
      org_params = attributes_for(:organization)
      within "form#new_organization" do
        fill_in "organization_name", with: org_params[:name]
        fill_in "organization_short_name", with: org_params[:short_name]
        fill_in "organization_url", with: org_params[:url]
        fill_in "organization_email", with: org_params[:email]
        fill_in "organization_street", with: "1500 Remount Road"
        fill_in "organization_city", with: "Front Royal"
        select("VA", from: "organization_state")
        fill_in "organization_zipcode", with: "22630"

        fill_in "organization_user_name", with: admin_user_params[:name]
        fill_in "organization_user_email", with: admin_user_params[:email]

        click_on "Save"
      end

      expect(page).to have_content("All Human Essentials Organizations")

      within("tr.#{org_params[:short_name]}") do
        first(:link, "View").click
      end

      expect(page).to have_content(org_params[:name])
      expect(page).to have_content("Remount")
      expect(page).to have_content("Front Royal")
      expect(page).to have_content("VA")
      expect(page).to have_content("22630")

      expect(page).to have_content(admin_user_params[:name])
      expect(page).to have_content(admin_user_params[:email])
      expect(page).to have_content("invited")
    end

    it "can view organization details", :aggregate_failures do
      visit admin_organizations_path

      within("tr.#{foo_org.short_name}") do
        first(:link, "View").click
      end

      expect(page.find("h1")).to have_text(foo_org.name)
      expect(page).to have_link("Home", href: admin_dashboard_path)

      expect(page).to have_content("Organization Info")
      expect(page).to have_content("Contact Info")
      expect(page).to have_content("Default email text")
      expect(page).to have_content("Users")
    end
  end
  context "While signed in as an Administrative User with no organization (super admin no org)" do
    before :each do
      sign_in(super_admin_no_org)
    end

    it "creates a new organization" do
      visit new_admin_organization_path
      org_params = attributes_for(:organization)
      fill_in "organization_name", with: org_params[:name]
      fill_in "organization_short_name", with: org_params[:short_name]
      fill_in "organization_url", with: org_params[:url]
      fill_in "organization_email", with: org_params[:email]
      fill_in "organization_street", with: "1500 Remount Road"
      fill_in "organization_city", with: "Front Royal"
      select("VA", from: "organization_state")
      fill_in "organization_zipcode", with: "22630"

      admin_user_params = attributes_for(:organization_admin)
      fill_in "organization_user_name", with: admin_user_params[:name]
      fill_in "organization_user_email", with: admin_user_params[:email]

      click_on "Save"

      expect(page).to have_content("All Human Essentials Organizations")

      within("tr.#{org_params[:short_name]}") do
        first(:link, "View").click
      end

      expect(page).to have_content(org_params[:name])
      expect(page).to have_content("Remount")
      expect(page).to have_content("Front Royal")
      expect(page).to have_content("VA")
      expect(page).to have_content("22630")
      expect(page).to have_content(admin_user_params[:name])
      expect(page).to have_content(admin_user_params[:email])
      expect(page).to have_content("invited")
    end
  end
end
