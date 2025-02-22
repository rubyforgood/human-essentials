RSpec.describe "Authorization", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  it "redirects to the dashboard when unauthorized user attempts access" do
    sign_in(user)
    visit "/admin/dashboard"

    expect(page.find("h1")).to have_content "Dashboard"
    expect(page.find(".alert")).to have_content "Access Denied"
  end

  it "redirects to the organization dashboard when authorized" do
    sign_in(user)
    visit dashboard_path

    expect(current_path).to eql "/dashboard"
  end

  context "Submitting a form with an invalid CSRF token" do
    before(:all) do
      ActionController::Base.allow_forgery_protection = true
    end

    context "When logging in" do
      it "should redirect back and show a helpful message" do
        visit "/users/sign_in"
        fill_in "user_email", with: user.email
        fill_in "user_password", with: DEFAULT_USER_PASSWORD
        first('input[name="authenticity_token"]', visible: false).set("NOTAVALIDCSRFTOKEN")
        page.execute_script("$(\"meta[name='csrf-token']\").attr('content', 'NOTAVALIDCSRFTOKEN');")
        click_button "Log in"
        expect(current_path).to eql "/users/sign_in"
        expect(page).to have_content "Your session expired. This could be due to leaving a page open for a long time, or having multiple tabs open. Try resubmitting."
      end
    end

    context "When logged in and creating a distribution" do
      before do
        create(:partner, organization: organization, name: "Test Partner")
        storage_location = create(:storage_location, organization: organization, name: "Test Storage Location")
        setup_storage_location(storage_location)
      end
      it "should redirect back and show a helpful message" do
        sign_in(user)
        visit new_distribution_path
        select "Test Partner", from: "Partner"
        select "Test Storage Location", from: "From storage location"
        first('input[name="authenticity_token"]', visible: false).set("NOTAVALIDCSRFTOKEN")
        page.execute_script("$(\"meta[name='csrf-token']\").attr('content', 'NOTAVALIDCSRFTOKEN');")
        click_button "Save"
        expect(current_path).to eql new_distribution_path
        expect(page).to have_content "Your session expired. This could be due to leaving a page open for a long time, or having multiple tabs open. Try resubmitting."
      end
    end

    after(:all) do
      ActionController::Base.allow_forgery_protection = false
    end
  end
end
