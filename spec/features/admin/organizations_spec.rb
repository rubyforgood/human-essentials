RSpec.feature "Organizations Admin" do
  before :each do
    sign_in(@super_admin)
  end

  scenario "creating a new organization" do
    visit new_admin_organization_path
    screenshot_and_open_image
    click_link "Add New Organization"
    org_params = attributes_for(:organization)
    fill_in "Name", with: org_params[:name]
    fill_in "Short name", with: org_params[:short_name]
    fill_in "Url", with: org_params[:url]
    fill_in "Email", with: org_params[:email]
    fill_in "Street", with: "1234 Banana Drive"
    fill_in "City", with: "Boston"
    select("MA", from: "State")
    fill_in "Zipcode", with: "12345"

    click_on "Create"

    expect(page).to have_content("All Diaperbase Organizations")

    within("tr.#{org_params[:short_name]}") do
      first(:link, "View").click
    end

    expect(page).to have_content(org_params[:name])
    expect(page).to have_content("Banana")
    expect(page).to have_content("Boston")
    expect(page).to have_content("MA")
    expect(page).to have_content("12345")
  end
end