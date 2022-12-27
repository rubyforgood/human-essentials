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
        expect(page).to have_field("profile_partner_counties_attributes_0_client_share", with: "25")
        fill_in "profile_partner_counties_attributes_0_client_share", with: "26"

        expect(page).to have_field("profile_partner_counties_attributes_0_client_share", with: "26")
        puts "County 1 is: " + partner1.partner_counties[0].county.name
        expect(page).to have_content("101 %")
        expect(page).to have_selector("partner-county-client-share-total-warning", visible: true)
      end

      it "handles changing back to a valid total client share properly" do
        fill_in "profile_partner_counties_attributes_0_client_share", with: "26"
        expect(page).to have_selector("partner-county-client-share-total-warning", visible: true)
        fill_in "profile_partner_counties_attributes_1_client_share", with: "24"
        expect(page).to have_selector("partner-county-client-share-total-warning", visible: false)
      end



    end
  end
end

