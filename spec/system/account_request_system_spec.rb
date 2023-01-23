RSpec.describe 'Account request flow', type: :system, js: true do
  context 'when in staging' do
    before do
      allow(Rails.env).to receive(:staging?).and_return(true)
    end

    it 'should prompt prospective users to request an account on the live app' do
      visit new_account_request_path
      expect(page).to have_link('click here', href: 'https://humanessentials.app/account_requests/new')
    end
  end

  context 'when not in staging' do
    before do
      allow(Rails.env).to receive(:staging?).and_return(false)
    end
    it 'should allow prospective users to request an account via a form. And that request form data gets used to create an organization' do
      ndbn_member = FactoryBot.create(:ndbn_member)
      visit root_path

      click_button('Request A Demo', match: :first)
      choose('account_bank')

      account_request_attrs = FactoryBot.attributes_for(:account_request)

      fill_in 'Name', with: account_request_attrs[:name]
      fill_in 'Email', with: account_request_attrs[:email]
      fill_in 'Organization name', with: account_request_attrs[:organization_name]
      fill_in 'Organization website', with: account_request_attrs[:organization_website]
      fill_in 'Request Details (min 50 characters)', with: account_request_attrs[:request_details]
      select "#{ndbn_member.ndbn_member_id} - #{ndbn_member.account_name}", from: 'account_request[ndbn_member_id]'

      expect(AccountRequest.count).to eq(0)

      expect { click_button 'Submit' }.to change(AccountRequest, :count).by(1)

      created_account_request = AccountRequest.last

      # Request Received
      expect(page).to have_content('Request Received!')
      expect(page).to have_content("We've sent you a email with instructions on next steps at #{created_account_request.email}!")

      # Access link within email they would have received
      visit confirmation_account_requests_path(token: created_account_request.identity_token)

      expect(created_account_request.confirmed_at).to eq(nil)

      click_link 'I\'m ready! Let\'s go!'

      expect(created_account_request.reload.confirmed_at).not_to eq(nil)

      expect(page).to have_content('Confirmed!')
      expect(page).to have_content('We will be processing your request now.')

      # Access link within email sent to admin user to process the request.
      sign_in(@super_admin)
      visit new_admin_organization_path(token: created_account_request.identity_token)

      fill_in 'Short name', with: 'fakeshortname'

      click_button 'Save'

      # Expect to see the a new organization with the name provided
      # originally in the AccountRequest
      expect(page).to have_content('All Human Essentials Organizations')
      expect(page).to have_content(created_account_request.organization_name)
      expect(page).to have_content(created_account_request.email)

      # Ensure the AccountRequest is not considered processed
      expect(created_account_request.reload.processed?).to eq(true)
    end

    context 'with a partner agency' do
      it 'reveals text that directs current partner to human essentials sign in page' do
        visit('/account_requests/new')

        choose(option: 'partner')

        expect(page).to have_link('here', href: 'https://humanessentials.app/users/sign_in')
      end
    end
  end
end

