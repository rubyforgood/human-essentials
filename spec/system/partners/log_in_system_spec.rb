RSpec.describe "Authentication", type: :system, js: true do
  describe 'logging in as a partner user' do
    let!(:partner_user) { FactoryBot.create(:partners_user, password: password) }
    let(:password) { Faker::Alphanumeric.alpha(number: 10) }

    context 'successfully through the partner user login page' do
      before do
        visit partner_user_session_path
      end

      it 'should take the user to the partners dashboard' do
        fill_in "partner_user_email", with: partner_user.email
        fill_in "partner_user_password", with: password
        find('input[name="commit"]').click

        expect(current_path).to eq(partners_dashboard_path)
      end
    end

    context 'failing to login because' do
      context 'due to attempting to login to diaperbase as a partner user' do
        before do
          visit new_user_session_path
        end

        it 'should show a error message and stay on the login page' do
          fill_in "user_email", with: partner_user.email
          fill_in "user_password", with: password
          find('input[name="commit"]').click

          expect(page).to have_content("Invalid Email or password")
        end
      end

      context 'giving invalid credentials' do
        before do
          visit partner_user_session_path
        end

        it 'should show a error message and stay on the login page' do
          fill_in "partner_user_email", with: partner_user.email
          fill_in "partner_user_password", with: 'not-the-right-password'
          find('input[name="commit"]').click

          expect(page).to have_content("Invalid Email or password")

          expect(current_path).to eq(partner_user_session_path)
        end
      end
    end
  end
end

