RSpec.describe "Diaper Drive Participant", type: :system, js: true do
  before do
    sign_in(@user)
  end

  let(:url_prefix) { "/#{@organization.to_param}" }
  let(:diaper_drive) { create(:diaper_drive) }
  let(:diaper_drive_participant) { create(:diaper_drive_participant) }

  context "When a user views the index page" do
    subject { url_prefix + "/diaper_drive_participants" }

    before(:each) do
      @second = create(:diaper_drive_participant, business_name: "Bcd")
      @first = create(:diaper_drive_participant, business_name: "Abc")
      @third = create(:diaper_drive_participant, business_name: "Cde")
      visit subject
    end

    it "alphabetizes the diaper drive participant names" do
      expect(page).to have_xpath("//table//tr", count: 4)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.business_name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.business_name)
    end

    context "When the Diaper Drives have donations associated with them already" do
      before(:each) do
        create(:donation, :with_items, created_at: 1.day.ago, item_quantity: 10, source: Donation::SOURCES[:diaper_drive], diaper_drive: diaper_drive, diaper_drive_participant: diaper_drive_participant)
        create(:donation, :with_items, created_at: 1.week.ago, item_quantity: 15, source: Donation::SOURCES[:diaper_drive], diaper_drive: diaper_drive, diaper_drive_participant: diaper_drive_participant)
      end

      it "shows existing Diaper Drive Participants in the #index with some summary stats" do
        visit subject
        expect(page).to have_xpath("//table/tbody/tr/td", text: diaper_drive_participant.business_name)
        expect(page).to have_xpath("//table/tbody/tr/td", text: "25")
      end

      it "allows single Diaper Drive Participants to show semi-detailed stats about donations from that diaper drive" do
        visit url_prefix + "/diaper_drive_participants/#{diaper_drive_participant.to_param}"
        expect(page).to have_xpath("//table/tbody/tr", count: 3)
      end
    end
  end

  context "when creating new diaper drive participants" do
    subject { url_prefix + "/diaper_drive_participants/new" }

    it "allows a user to create a new diaper drive instance" do
      visit subject
      diaper_drive_participant_traits = attributes_for(:diaper_drive_participant)
      fill_in "Contact Name", with: diaper_drive_participant_traits[:contact_name]
      fill_in "Business Name", with: diaper_drive_participant_traits[:business_name]
      fill_in "Phone", with: diaper_drive_participant_traits[:phone]

      expect do
        click_button "Save"
      end.to change { DiaperDriveParticipant.count }.by(1)

      expect(page.find(".alert")).to have_content "added"
    end

    it "does not allow a user to add a new diaper drive instance with empty attributes" do
      visit subject
      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "when editing an existing diaper drive participant" do
    subject { url_prefix + "/diaper_drive_participants/#{diaper_drive_participant.id}/edit" }

    it "allows a user to update the contact info for a diaper drive participant" do
      new_email = "foo@bar.com"
      visit subject
      fill_in "Phone", with: ""
      fill_in "E-mail", with: new_email
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
      expect(page).to have_content(diaper_drive_participant.contact_name)
      expect(page).to have_content(new_email)
    end

    it "does not allow a user to update a diaper drive participant with empty attributes" do
      visit subject
      fill_in "Business Name", with: ""
      fill_in "Contact Name", with: ""
      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end
end
