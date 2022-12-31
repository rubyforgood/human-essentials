RSpec.describe "Partner counties behaviour", type: :system, js: true do
  describe 'changing the client share' do

    let!(:partner1) { create(:partner, :with_4_counties) }
    let(:partner1_user) { partner1.primary_user }

    context "changing the client share" do
      before do
        login_as(partner1_user)
        visit edit_partners_profile_path
      end

      it "handles an invalid total client share properly" do

        fill_in 'profile_partner_counties_attributes_0_client_share', with: '26'
        expect(page).to have_content('101 %')
        expect(page).to have_content('The total client share must be either 0 or 100 %')
      end

      it "handles a changed but correct total client share properly" do

        fill_in 'profile_partner_counties_attributes_0_client_share', with: '26'
        fill_in 'profile_partner_counties_attributes_1_client_share', with: '24'
        expect(page).to have_content('100 %')
        expect(page).not_to have_content('The total client share must be either 0 or 100 %')
      end
    end
  end
end

