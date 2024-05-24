RSpec.describe "Partners profile served area behaviour when accessed as bank", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end
  let!(:partner1) { create(:partner, organization: organization) }
  let!(:served_areas) {
    partner1.profile.served_areas << create_list(:partners_served_area, 4,
      partner_profile: partner1.profile, client_share: 25)
  }

  context "changing the client share" do
    before do
      visit edit_profile_path(id: partner1.id, partner_id: partner1.id)
    end

    it "handles an invalid total client share properly" do
      county_1_text = find_field("partner_profile_served_areas_attributes_0_county_id").find("option[selected]").text
      select "26", from: "partner_profile_served_areas_attributes_0_client_share"
      expect(page).to have_content("101 %")
      expect(page).to have_content("The total client share must be either 0 or 100 %")
      click_on "Update Information"
      text_2 = find_field("partner_profile_served_areas_attributes_0_county_id").find("option[selected]").text # There is at least one county already
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
      expect(page).to have_content("Application & Information")
      expect(page).to have_content("26 %")
    end

    it "handles addition properly" do
      click_on("Add Another County")
      matching = page.all(".remove_served_area") # The fields have unpredicatable numbers, so I have to count how many *soemthing* there is
      expect(matching.size).to eq(5)
      select = page.all("select.percentage-selector").last
      expect(select.value).to eq("")
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
