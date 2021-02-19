RSpec.describe "Partner management", type: :system, js: true do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  describe "#index" do
    before(:each) do
      @uninvited = create(:partner, name: "Bcd", status: :uninvited)
      @invited = create(:partner, name: "Abc", status: :invited)
      @approved = create(:partner, :approved, name: "Cde", status: :approved)
      visit url_prefix + "/partners"
    end

    it "displays the partner agency names in alphabetical order" do
      expect(page).to have_css("table tr", count: 5)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@invited.name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@approved.name)
    end

    it "allows a user to invite a partner", :js do
      partner = create(:partner, name: 'Charities')
      visit url_prefix + "/partners"

      within("table > tbody > tr:nth-child(4) > td:nth-child(5)") { click_on "Invite" }
      invite_alert = page.driver.browser.switch_to.alert
      expect(invite_alert.text).to eq("Send an invitation to #{partner.name} to begin using the partner application?")

      invite_alert.accept
      expect(page.find(".alert")).to have_content "invited!"
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

    context "when exporting as CSV" do
      let(:fake_get_return) do
        { "agency" => {
          "contact_person" => { name: "A Name" }
        } }.to_json
      end

      before do
        allow(DiaperPartnerClient).to receive(:get).and_return(fake_get_return)
      end

      context "when filtering" do
        it "preserves the filter constraints in the CSV output" do
          approved_partners = Partner.approved.to_a
          within "#partner-status" do
            click_on "Approved"
          end

          page.find 'a.filtering', text: /Approved/

          click_on "Export Partner Agencies"
          wait_for_download
          expect(downloads.length).to eq(1)
          expect(download).to match(/.*\.csv/)

          rows = download_content.split("\n").slice(1..)
          expect(rows.size).to eq(approved_partners.size)
          expect(rows.first).to match(/#{approved_partners.first.email}/)
        end
      end
    end
  end

  describe "#show" do
    context "when viewing an uninvited partner" do
      let(:uninvited) { create(:partner, name: "Uninvited Partner", status: :uninvited) }
      subject { url_prefix + "/partners/#{uninvited.id}" }

      it 'only has an edit option available' do
        visit subject

        expect(page).to have_selector(:link_or_button, 'Edit')
        expect(page).to_not have_selector(:link_or_button, 'View')
        expect(page).to_not have_selector(:link_or_button, 'Activate Partner Now')
        expect(page).to_not have_selector(:link_or_button, 'Add/Remind Partner')
      end
    end

    context "when exporting as CSV" do
      subject { url_prefix + "/partners/#{partner.id}" }

      let(:partner) do
        partner = create(:partner, :approved)
        partner.distributions << create(:distribution, :with_items, item_quantity: 1231)
        partner.distributions << create(:distribution, :with_items, item_quantity: 4564)
        partner.distributions << create(:distribution, :with_items, item_quantity: 7897)
        partner
      end

      let(:fake_get_return) do
        { "agency" => {
          "families_served" => Faker::Number.number,
          "children_served" => Faker::Number.number,
          "family_zipcodes" => Faker::Number.number,
          "family_zipcodes_list" => [Faker::Number.number]
        } }.to_json
      end

      before do
        allow(DiaperPartnerClient).to receive(:get).with({ id: partner.to_param }, query_params: { impact_metrics: true }).and_return(fake_get_return)
      end

      context "when filtering" do
        it "preserves the filter constraints in the CSV output" do
          visit subject

          click_on "Export Partner Distributions"
          wait_for_download
          expect(downloads.length).to eq(1)
          expect(download).to match(/.*\.csv/)

          rows = download_content.split("\n").slice(1..)

          expect(rows.size).to eq(partner.distributions.size)
          expect(rows.join).to have_text('1231', count: 2)
          expect(rows.join).to have_text('4564', count: 2)
          expect(rows.join).to have_text('7897', count: 2)
        end
      end
    end
  end

  describe "#new" do
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

  describe "#edit" do
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

  describe "#approve_partner" do
    let(:tooltip_message) do
      "Partner has not requested approval yet. \
Partners are able to request approval going into 'My Organization' \
and clicking 'Request Approval' button"
    end
    let!(:invited_partner) { create(:partner, name: "Amelia Ebonheart", status: :invited) }
    let!(:awaiting_review_partner) { create(:partner, name: "Beau Brummel", status: :awaiting_review) }

    context "when partner has :invited status" do
      before { visit_approval_page(invited_partner.id, 1) }

      it { expect(page).to have_selector(:link_or_button, 'Approve Partner') }
      it { expect(page).to have_selector('span#pending-approval-request-tooltip > a.btn.btn-success.btn-md.disabled') }

      it 'shows correct tooltip' do
        page.execute_script('$("#pending-approval-request-tooltip").mouseover()')
        expect(page).to have_content tooltip_message
      end
    end

    context "when partner has :awaiting_review status" do
      before { visit_approval_page(awaiting_review_partner.id, 2) }

      it { expect(page).to have_selector(:link_or_button, 'Approve Partner') }
      it { expect(page).not_to have_selector('span#pending-approval-request-tooltip > a.btn.btn-success.btn-md.disabled') }

      it 'shows no tooltip' do
        page.execute_script('$("#pending-approval-request-tooltip").mouseover()')
        expect(page).not_to have_content tooltip_message
      end
    end
  end
end

def stub_get_partner_request(partner_id)
  allow(ENV).to receive(:[]).and_return(ENV)
  allow(ENV).to receive(:[]).with("PARTNER_REGISTER_URL").and_return("https://partner-register.com")
  allow(ENV).to receive(:[]).with("PARTNER_BASE_URL").and_return("https://partner-register.com")
  allow(ENV).to receive(:[]).with("PARTNER_KEY").and_return("partner-key")

  partner_response = File.read("spec/fixtures/partner_api/partner.json")

  stub_request(:get, "https://partner-register.com/#{partner_id}")
    .to_return(status: 200, body: partner_response, headers: {})
end

def visit_approval_page(partner_id, table_row)
  visit url_prefix + "/partners"
  stub_get_partner_request(partner_id)
  within("table > tbody > tr:nth-child(#{table_row}) > td:nth-child(5)") { click_on "Review Application" }
end