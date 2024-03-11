RSpec.describe "Partners profile served area behaviour", type: :system, js: true do
  let!(:partner1) { create(:partner) }
  let(:partner1_user) { partner1.primary_user }
  let!(:served_areas) {
    partner1.profile.served_areas << create_list(:partners_served_area, 4,
      partner_profile: partner1.profile, client_share: 25)
  }
  context "changing the client share" do
    before do
      login_as(partner1_user)
      visit edit_partners_profile_path
    end

    it "handles an invalid total client share properly" do
      county_1_text = find_field("partner_profile_served_areas_attributes_0_county_id").find("option[selected]").text
      select "26", from: "partner_profile_served_areas_attributes_0_client_share"
      expect(page).to have_content("101 %")
      expect(page).to have_content("The total client share must be either 0 or 100 %")
      click_on "Update Information"
      text_2 = find_field("partner_profile_served_areas_attributes_0_county_id").find("option[selected]").text
      expect(text_2).to eq(county_1_text)
      expect(page).to have_field("partner_profile_served_areas_attributes_0_client_share", with: "26")
      expect(page).to have_content("The total client share must be either 0 or 100 %")
    end

    it "handles a changed but correct total client share properly" do
      check "partner_profile_no_social_media_presence"
      select "26", from: "partner_profile_served_areas_attributes_0_client_share"
      select "24", from: "partner_profile_served_areas_attributes_1_client_share"
      expect(page).to have_content("100 %")
      expect(page).not_to have_content("The total client share must be either 0 or 100 %")
      click_on "Update Information"
      expect(page).to have_content("Organization Details")
      expect(page).to have_content("26 %")
    end

    it "handles addition properly" do
      click_on("Add Another County")
      matching = page.all(".remove_served_area") # The fields have unpredicatable numbers, so I have to count how many *soemthing* there is
      expect(matching.size).to eq(5)
    end

    it "handles deletion properly" do
      first(".remove_served_area").click
      assert page.has_content? "75 %"
      assert page.has_content? "The total client share must be either 0 or 100 %."
      first(".remove_served_area").click
      assert page.has_content? "50 %"
      click_on "Update Information"
      assert page.has_content? "50 %"
    end
  end
end
