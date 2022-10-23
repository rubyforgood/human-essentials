  RSpec.describe "Partner counties", type: :system, js: true do
    # With a partner with no partner counties, but has social media
    let(:partner_user) { partner.primary_partner_user }
    let!(:partner) { FactoryBot.create(:partner) }

    before do
      partner.profile.update(partner_status: :verified)
      login_as(partner_user)
      visit edit_partners_profile_path
    end

    describe "when signed in as a partner and editing the profile" do
      it "handles the partner county appropriately" do
        county_1 = "A"
        # county_2 = "B"

        # update button is available, total is 0, no message


        expect(page).to have_content("Edit My Organization")
        expect(page).to have_button("Update Information", count: 1)
        expect(page).to have_css("#__add_partner_county", count: 1)
        expect(page).to have_content("0 %")
        expect(page).not_to have_css("partner_county_error_message")

        # add a county with 25% client share

        click_on("Add another county")

        select(county_1, from: "county_select_1")

        # fill_in (:id_for_first_county_client_share, 25)

        # update button is not available, total is 25, messages appear

        # expect(page).not_to have_css("update-button", count: 1)
        # expect(page).to have_css("update-button-disabled", count: 1)
        # expect(page).to have_css("add_partner_county_button", count: 1)
        # expect(page).to have_content("25%")
        # expect(page).to have_css("partner_county_error_message")

        # add a county with 75% client share
        # click_on(add_partner_county_button)

        # select(county_2, from: "county_select_2")
        # fill_in (:id_for_2nd_county_client_share, 25)

        # update button is available, total is 100, no message
        # expect(page).to have_css("update-button", count: 1)
        # expect(page).not_to have_css("update-button-disabled", count: 1)
        # expect(page).to have_css("add_partner_county_button", count: 1)
        # expect(page).to have_content("100%")
        # expect(page).not_to have_css("partner_county_error_message")

        # click("update-button")
        # it goes where expected, with no message
        # expect(page).to have_content("Organization Details")
        # expect(page).to have_content("75 %")
        # clink("Edit Information")

        # change the amount on the first county to 26%
        # fill_in (:id_for_first_county_client_share, 26)

        # update button is not available, total is 101, messages appear
        # expect(page).not_to have_css("update-button", count: 1)
        # expect(page).to have_css("update-button-disabled", count: 1)
        # expect(page).to have_css("add_partner_county_button", count: 1)
        # expect(page).to have_content("101%")
        # expect(page).to have_css("partner_county_error_message")

        # remove first county

        # click_on("county_1_remove")

        # might have to do a "are yousure here?"

        # update button is not available, total is 75, messages appear

        # expect(page).not_to have_css("update-button", count: 1)
        # expect(page).to have_css("update-button-disabled", count: 1)
        # expect(page).to have_css("add_partner_county_button", count: 1)

        # expect(page).to have_content("75%")
        # expect(page).to have_css("partner_county_error_message")

        # click("update-button")
        # it goes where expected, with no message
        # expect(page).to have_content("Organization Details")
        #



        # remove remaining county
        # click_on("county_2_remove")
        # update button is available, etc.
        # expect(page).to have_css("update-button", count: 1)
        # expect(page).not_to have_css("update-button-disabled", count: 1)
        # expect(page).to have_css("add_partner_county_button", count: 1)
        # expect(page).to have_content("0%")
        # expect(page).not_to have_css("partner_county_error_message")

        # click update button

        # click("update-button")
        # it goes where expected, with no message
        # expect(page).to have_content("Organization Details")
        # expect(page).to have_content("Unspecified")
      end
    end
  end
