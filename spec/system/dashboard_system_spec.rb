require 'ostruct'

RSpec.describe "Dashboard", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "With a new essentials bank" do
    before do
      sign_in(user)
    end

    it "displays the getting started guide until the steps are completed" do
      org_dashboard_page = OrganizationDashboardPage.new
      org_dashboard_page.visit

      # rubocop:disable Layout/ExtraSpacing

      # When dashboard loads, ensure that we are on step 1 (Storage Locations)
      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).to     have_add_storage_location_call_to_action
      expect(org_dashboard_page).not_to have_add_partner_call_to_action
      expect(org_dashboard_page).not_to have_add_donation_site_call_to_action
      expect(org_dashboard_page).not_to have_add_inventory_call_to_action

      # After we create a storage location, ensure that we are on step 2 (Partner Agency)
      create(:storage_location, organization: organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).to     have_add_partner_call_to_action
      expect(org_dashboard_page).not_to have_add_storage_location_call_to_action
      expect(org_dashboard_page).not_to have_add_donation_site_call_to_action
      expect(org_dashboard_page).not_to have_add_inventory_call_to_action

      # After we create a partner agency, ensure that we are on step 3 (Donation Site)
      create(:partner, organization: organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).not_to have_add_partner_call_to_action
      expect(org_dashboard_page).not_to have_add_storage_location_call_to_action
      expect(org_dashboard_page).to     have_add_donation_site_call_to_action
      expect(org_dashboard_page).not_to have_add_inventory_call_to_action

      # After we create a donation site, ensure that we are on step 4 (Inventory)
      create(:donation_site, organization: organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).to     have_getting_started_guide
      expect(org_dashboard_page).not_to have_add_partner_call_to_action
      expect(org_dashboard_page).not_to have_add_storage_location_call_to_action
      expect(org_dashboard_page).not_to have_add_donation_site_call_to_action
      expect(org_dashboard_page).to     have_add_inventory_call_to_action

      # rubocop:enable Layout/ExtraSpacing

      # After we add inventory to a storage location, ensure that the getting starting guide is gone
      create(:storage_location, :with_items, item_quantity: 125, organization: organization)
      org_dashboard_page.visit

      expect(org_dashboard_page).not_to have_getting_started_guide
    end
  end

  context "With an existing essentials bank" do
    before do
      sign_in(user)
    end

    let!(:storage_location) { create(:storage_location, :with_items, item_quantity: 1, organization: organization) }
    let(:org_dashboard_page) { OrganizationDashboardPage.new }

    describe "Outstanding Requests" do
      it "has a card" do
        org_dashboard_page.visit
        org_dashboard_page.outstanding_section # wait for the section
        expect(org_dashboard_page).to have_outstanding_section
      end

      context "when empty" do
        before do
          org_dashboard_page.visit
          org_dashboard_page.outstanding_section # wait for the section
        end

        it "displays a message" do
          expect(org_dashboard_page.outstanding_section).to have_content "No outstanding requests!"
        end

        it "has a See More link" do
          expect(org_dashboard_page.outstanding_requests_link).to have_content "View all requests"
        end
      end

      context "with a pending request" do
        let!(:request) { create :request, :pending }
        let!(:outstanding_request) do
          org_dashboard_page.visit
          org_dashboard_page.outstanding_section # wait for the section
          requests = org_dashboard_page.outstanding_requests
          expect(requests.length).to eq 1
          requests.first
        end

        it "displays the date" do
          date = outstanding_request.find "td.date"
          expect(date.text).to eq request.created_at.strftime("%m/%d/%Y")
        end

        it "displays the partner" do
          expect(outstanding_request).to have_content request.partner.name
        end

        it "displays the requestor" do
          expect(outstanding_request).to have_content request.partner_user.name
        end

        it "displays the comment" do
          expect(outstanding_request).to have_content request.comments
        end

        it "links to the request" do
          expect { outstanding_request.find('a').click }
            .to change { page.current_path }
            .to request_path(request.id)
        end

        it "has a See More link" do
          expect(org_dashboard_page.outstanding_requests_link).to have_content "View all requests"
        end
      end

      it "does display a started request" do
        create :request, :started
        org_dashboard_page.visit
        org_dashboard_page.outstanding_section # wait for the section
        expect(org_dashboard_page.outstanding_requests.length).to eq 1
      end

      it "does not display a fulfilled request" do
        create :request, :fulfilled
        org_dashboard_page.visit
        org_dashboard_page.outstanding_section # wait for the section
        expect(org_dashboard_page.outstanding_section).to have_content "No outstanding requests!"
        # expect(org_dashboard_page.outstanding_requests).to be_empty
      end

      it "does not display a discarded request" do
        create :request, :discarded
        org_dashboard_page.visit
        org_dashboard_page.outstanding_section # wait for the section
        expect(org_dashboard_page.outstanding_requests).to be_empty
      end

      context "with many pending requests" do
        let(:num_requests) { 50 }
        let(:limit) { 25 }
        before do
          create_list :request, num_requests, :pending
          org_dashboard_page.visit
          org_dashboard_page.outstanding_section # wait for the section
        end

        it "displays a limited number of requests" do
          expect(org_dashboard_page.outstanding_requests.length).to eq limit
        end

        it "has a See More link" do
          expect(org_dashboard_page.outstanding_requests_link).to have_content "View all requests"
        end
      end
    end

    describe "Partner Approvals" do
      it "has a card" do
        org_dashboard_page.visit
        expect(org_dashboard_page).to have_partner_approvals_section
      end

      context "when empty" do
        it "displays a message" do
          org_dashboard_page.visit
          expect(org_dashboard_page.partner_approvals_section).to have_content "No partners waiting for approval"
        end
      end

      context "with no awaiting partners" do
        let!(:partner) { create :partner, :approved }

        it "still displays the simple message" do
          org_dashboard_page.visit
          expect(org_dashboard_page.partner_approvals_section).to have_content "No partners waiting for approval"
        end
      end

      context "with awaiting partners" do
        let!(:org) { create :organization }
        let!(:user) { create :user, organization: org }
        let!(:partner_to_see1) { create :partner, status: :awaiting_review, organization: org }
        let!(:partner_to_see2) { create :partner, status: :awaiting_review, organization: org }
        let!(:partner_hidden1) { create :partner, status: :approved, organization: org }
        let!(:partner_hidden2) { create :partner, status: :invited, organization: org }

        it "only displays awaiting partners" do
          sign_in user
          org_dashboard_page.visit
          within(org_dashboard_page.partner_approvals_section) do
            [partner_to_see1, partner_to_see2].each do |partner|
              expect(page).to have_content partner.name
              expect(page).to have_content partner.profile.primary_contact_email
              expect(page).to have_content partner.profile.primary_contact_name
              expect(page).to have_link "Review Application", href: partner_path(id: partner) + "#partner-information"
            end
            [partner_hidden1, partner_hidden2].each do |hidden_partner|
              expect(page).to_not have_content hidden_partner.name
              expect(page).to_not have_content hidden_partner.profile.primary_contact_email
              expect(page).to_not have_content hidden_partner.profile.primary_contact_name
              expect(page).to_not have_link "Review Application", href: partner_path(id: hidden_partner) + "#partner-information"
            end
          end
        end
      end
    end

    describe "Bank-wide Low inventory" do
      it "displays no low inventory message" do
        org_dashboard_page.visit
        expect(org_dashboard_page).to have_low_inventory_section
        expect(org_dashboard_page.low_inventory_section).to have_text "Inventory is at recommended levels (minimum and recommended levels can be set on each item)"
      end

      context "with low inventory" do
        let(:below_recommended_item) { create :item, organization: organization, on_hand_minimum_quantity: 0, on_hand_recommended_quantity: 200 }
        let(:below_minimum_item) { create :item, organization: organization, on_hand_minimum_quantity: 150, on_hand_recommended_quantity: 200 }

        let!(:below_recommended_inventory_purchase) {
          create :purchase, :with_items,
            organization: organization,
            storage_location: storage_location,
            item: below_recommended_item,
            item_quantity: 100,
            issued_at: Time.current
        }

        let!(:below_minimum_inventory_purchase) {
          create :purchase, :with_items,
            organization: organization,
            storage_location: storage_location,
            item: below_minimum_item,
            item_quantity: 100,
            issued_at: Time.current
        }

        it "displays low inventory report" do
          org_dashboard_page.visit
          expect(org_dashboard_page).to have_low_inventory_section
          inventories = org_dashboard_page.low_inventories
          minimum_item = "#{below_minimum_item.name}\t100\t150\t200"
          recommended_item = "#{below_recommended_item.name}\t100\t0\t200"
          expect(inventories.count).to eq 2
          expect(inventories).to include minimum_item
          expect(inventories).to include recommended_item
        end
      end
    end
  end
end
