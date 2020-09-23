RSpec.describe "Partner management", type: :system, js: true do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  context "When a user views the index page" do
    before(:each) do
      @uninvited = create(:partner, name: "Bcd", status: :uninvited)
      @invited = create(:partner, name: "Abc", status: :invited)
      @approved = create(:partner, :approved, name: "Cde", status: :approved)
      visit url_prefix + "/partners"
    end

    it "the partner agency names are in alphabetical order" do
      expect(page).to have_css("table tr", count: 5)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@invited.name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@approved.name)
    end

    it "shows invite button only for unapproved partners" do
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[5]")).to have_no_content('Invite')
      expect(page.find(:xpath, "//table/tbody/tr[2]/td[5]")).to have_content('Invite')
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[5]")).to have_no_content('Invite')
    end

    context "when filtering" do
      it "allows the user to click on one of the statuses at the top to filter the results" do
        approved_count = Partner.approved.count
        within "table tbody" do
          expect(page).to have_css("tr", count: Partner.count)
        end
        within "#partner-status" do
          click_on "Approved"
        end
        within "table tbody" do
          expect(page).to have_css("tr", count: approved_count)
        end
      end
    end
  end

  context "when creating a new partner" do
    subject { url_prefix + "/partners/new" }

    it "User can add a new partner" do
      visit subject
      fill_in "Name", with: "Frank"
      fill_in "E-mail", with: "frank@frank.com"
      check 'send_reminders'
      click_button "Add Partner Agency"

      expect(page.find(".alert")).to have_content "added"
    end

    it "disallows a user from creating a new partner with empty name" do
      visit subject
      click_button "Add Partner Agency"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "when editing an existing partner" do
    let!(:partner) { create(:partner, name: "Frank") }
    subject { url_prefix + "/partners/#{partner.id}/edit" }

    it "User can update a partner" do
      visit subject
      fill_in "Name", with: "Franklin"
      click_button "Update Partner"

      expect(page.find(".alert")).to have_content "updated"
      partner.reload
      expect(partner.name).to eq("Franklin")
    end

    it "prevents a user from updating a partner with empty name" do
      visit subject
      fill_in "Name", with: ""
      click_button "Update Partner"

      expect(page.find(".alert")).to have_content "didn't work"
    end

    it "User can uncheck send_reminders" do
      visit subject
      uncheck 'send_reminders'
      click_button "Update Partner"

      expect(page.find(".alert")).to have_content "updated"
      partner.reload
      expect(partner.send_reminders).to be false
    end
  end

  it "User invite a partner", :js do
    partner = create(:partner, name: 'Charities')
    visit url_prefix + "/partners"

    within("table > tbody > tr:nth-child(1) > td:nth-child(5)") { click_on "Invite" }
    invite_alert = page.driver.browser.switch_to.alert
    expect(invite_alert.text).to eq("Send an invitation to #{partner.name} to begin using the partner application?")

    invite_alert.accept
    expect(page.find(".alert")).to have_content "invited!"
  end
end
