RSpec.describe "Partner management", type: :system, js: true do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  describe 'approving a partner that is awaiting approval' do
    let!(:partner_awaiting_approval) { create(:partner, :awaiting_review) }

    before do
      expect(partner_awaiting_approval.profile.partner_status).not_to eq('approval')
    end

    context 'when the approval succeeds' do
      it 'should approve the partner' do
        visit url_prefix + "/partners"

        assert page.has_content? partner_awaiting_approval.name
        click_on 'Review Application'
        assert page.has_content? "Partner Approval Request for #{partner_awaiting_approval.name}"
        assert page.has_content? "#{partner_awaiting_approval.name} - Application Details - #{partner_awaiting_approval.email}"

        click_on 'Approve Partner'
        assert page.has_content? 'Partner approved!'

        expect(partner_awaiting_approval.reload.approved?).to eq(true)
        expect(partner_awaiting_approval.profile.reload.partner_status).to eq(Partners::Partner::VERIFIED_STATUS)
      end
    end

    context 'when the approval does not succeed' do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }
      before do
        allow_any_instance_of(PartnerApprovalService).to receive(:call)
        allow_any_instance_of(PartnerApprovalService).to receive_message_chain(:errors, :none?).and_return(false)
        allow_any_instance_of(PartnerApprovalService).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
      end

      it 'should show an error message and not approve the partner' do
        visit url_prefix + "/partners"

        assert page.has_content? partner_awaiting_approval.name
        click_on 'Review Application'
        assert page.has_content? "Partner Approval Request for #{partner_awaiting_approval.name}"
        assert page.has_content? "#{partner_awaiting_approval.name} - Application Details - #{partner_awaiting_approval.email}"

        click_on 'Approve Partner'
        assert page.has_content? "Failed to approve partner because: #{fake_error_msg}"

        expect(partner_awaiting_approval.reload.approved?).to eq(false)
        expect(partner_awaiting_approval.profile.reload.partner_status).not_to eq(Partners::Partner::VERIFIED_STATUS)
      end
    end
  end

  describe 'adding another user to a partner account' do
    let(:partner) { create(:partner, status: 'invited') }
    before do
      @user.update(organization_admin: true)
    end

    context 'when adding a new user to a partner account succesfully' do
      let(:email) { Faker::Internet.email }

      before do
        visit url_prefix + "/partners/#{partner.id}"

        click_on 'Add/Remind Partner'
        assert page.has_content? "Add a User or Send a Reminder for #{partner.name}"

        fill_in 'email', with: email

        find_button('Invite User').click
        assert page.has_content? "We have invited #{email} to #{partner.name}!"
      end

      it 'should create a new user for that partner' do
        expect(Partners::User.find_by(email: email, partner: partner.profile)).not_to eq(nil)
      end
    end
  end

  describe 'adding a new partner and inviting them' do
    context 'when adding & inviting a partner successfully' do
      let(:partner_attributes) do
        {
          name: Faker::Name.name,
          email: Faker::Internet.email,
          quota: Faker::Number.within(range: 5..100),
          notes: Faker::Lorem.paragraph
        }
      end
      before do
        visit url_prefix + "/partners"
        assert page.has_content? "Partner Agencies for #{@organization.name}"

        click_on 'New Partner Agency'

        fill_in 'Name *', with: partner_attributes[:name]
        fill_in 'E-mail *', with: partner_attributes[:email]
        fill_in 'Quota', with: partner_attributes[:quota]
        fill_in 'Notes', with: partner_attributes[:notes]
        find('button', text: 'Add Partner Agency').click

        assert page.has_content? "Partner #{partner_attributes[:name]} added!"

        accept_confirm do
          find('tr', text: partner_attributes[:name]).find_link('Invite').click
        end

        assert page.has_content? "Partner #{partner_attributes[:name]} invited!"
      end

      it 'should have added the partner and invited them' do
        expect(Partner.find_by(email: partner_attributes[:email]).status).to eq('invited')
      end
    end

    context 'when adding a partner incorrectly' do
      let(:partner_attributes) do
        {
          name: Faker::Name.name
        }
      end
      before do
        visit url_prefix + "/partners"
        assert page.has_content? "Partner Agencies for #{@organization.name}"
        click_on 'New Partner Agency'

        fill_in 'Name *', with: partner_attributes[:name]

        find('button', text: 'Add Partner Agency').click
      end

      it 'should have not added a new partner and indicate the failure' do
        assert page.has_content? "Failed to add partner due to: "
        assert page.has_content? "New Partner for #{@organization.name}"

        partner = Partner.find_by(name: partner_attributes[:name])
        expect(partner).to eq(nil)
      end
    end
  end

  describe 'requesting recertification of a partner' do
    context 'GIVEN a user goes through the process of requesting recertificaiton of partner' do
      let!(:partner_to_request_recertification) { create(:partner, status: 'approved') }

      before do
        sign_in(@user)
        visit partners_path(@organization)
      end

      it 'should notify the user that its been successful and change the partner status' do
        accept_confirm do
          find_button('Request Recertification').click
        end

        assert page.has_content? "#{partner_to_request_recertification.name} recertification successfully requested!"
        expect(partner_to_request_recertification.reload.recertification_required?).to eq(true)
      end
    end
  end

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
      partner.profile.primary_user.delete

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

      expect(page.find(".alert")).to have_content "Failed to add partner due to:"
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

      expect(page.find(".alert")).to have_content "Something didn't work quite right -- try again?"
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
Partners are able to request approval by going into 'My Organization' \
and clicking 'Request Approval' button."
    end
    let!(:invited_partner) { create(:partner, name: "Amelia Ebonheart", status: :invited) }
    let!(:awaiting_review_partner) { create(:partner, name: "Beau Brummel", status: :awaiting_review) }

    context "when partner has :invited status" do
      before { visit_approval_page(1) }

      it { expect(page).to have_selector(:link_or_button, 'Approve Partner') }
      it { expect(page).to have_selector('span#pending-approval-request-tooltip > a.btn.btn-success.btn-md.disabled') }

      it 'shows correct tooltip' do
        page.execute_script('$("#pending-approval-request-tooltip").mouseover()')
        expect(page).to have_content tooltip_message
      end
    end

    context "when partner has :awaiting_review status" do
      before { visit_approval_page(2) }

      it { expect(page).to have_selector(:link_or_button, 'Approve Partner') }
      it { expect(page).not_to have_selector('span#pending-approval-request-tooltip > a.btn.btn-success.btn-md.disabled') }

      it 'shows no tooltip' do
        page.execute_script('$("#pending-approval-request-tooltip").mouseover()')
        expect(page).not_to have_content tooltip_message
      end
    end
  end
end

def visit_approval_page(table_row)
  visit url_prefix + "/partners"
  within("table > tbody > tr:nth-child(#{table_row}) > td:nth-child(5)") { click_on "Review Application" }
end
