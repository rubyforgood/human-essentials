RSpec.describe "Account request flow", type: :system, js: true do

  it 'should allow prospect users to request an account via form. And their inputs get used to create an organization' do
    visit root_path

    click_button "Click here to request an account with us"

    account_request_attrs = FactoryBot.attributes_for(:account_request)

    fill_in "Name", with: account_request_attrs[:name]
    fill_in "Email", with: account_request_attrs[:email]
    fill_in "Organization name", with: account_request_attrs[:organization_name]
    fill_in "Organization website", with: account_request_attrs[:organization_website]
    fill_in "Request Details (min 50 characters) *", with: account_request_attrs[:request_details]

    expect(AccountRequest.all.count).to eq(0)

    click_button "Submit"

    expect(AccountRequest.all.count).to eq(1)

    created_account_request = AccountRequest.last

    # Request Received
    expect(page).to have_content("Request Received!")
    expect(page).to have_content("We've sent you a email with instructions on next steps at #{created_account_request.email}!")

    # Access link within email they would have received
    visit confirmation_account_requests_path(token: created_account_request.identity_token)

    expect(created_account_request.confirmed_at).to eq(nil)

    click_link "Confirm"

    expect(created_account_request.reload.confirmed_at).not_to eq(nil)
    expect(page).to have_content("Confirmed")
    expect(page).to have_content("We will be processing your request now.")

    # Access link within email sent to admin user to process the request.

    sign_in(@super_admin)
    visit new_admin_organization_url(token: created_account_request.identity_token)

    binding.pry
  end
end

