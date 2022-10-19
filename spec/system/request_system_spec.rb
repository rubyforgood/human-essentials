RSpec.describe "Requests", type: :system, js: true do
  before do
    sign_in(@user)
    @storage_location = create(:storage_location, :with_items, organization: @organization)
  end

  let!(:url_prefix) { "/#{@organization.to_param}" }

  let(:item1) { create(:item, name: "Good item") }
  let(:item2) { create(:item, name: "Crap item") }
  let(:partner1) { create(:partner, name: "This Guy", email: "thisguy@example.com") }
  let(:partner2) { create(:partner, name: "That Guy", email: "ntg@example.com") }

  before { travel_to Time.zone.local(2020, 1, 1) }
  after { travel_back }

  context "#index" do
    subject { url_prefix + "/requests" }

    before do
      create(:request, :started, partner: partner1, request_items: [{ "item_id": item1.id, "quantity": '12' }])
      create(:request, :started, partner: partner1, request_items: [{ "item_id": item2.id, "quantity": '13' }])
      create(:request, :started, partner: partner2, request_items: [{ "item_id": item1.id, "quantity": '14' }])
      create(:request, :fulfilled, partner: partner1, request_items: [{ "item_id": item1.id, "quantity": '15' }])
      create(:request, :pending, partner: partner1, request_items: [{ "item_id": item1.id, "quantity": '16' }])
    end

    it "lists requests" do
      visit subject
      expect(page).to have_xpath("//h1", text: "Requests")
    end

    it "can be exported in CSV" do
      visit subject
      click_on "Export Requests"

      wait_for_download
      expect(downloads.length).to eq(1)
      expect(download).to match(/.*\.csv/)

      headers, *rows = download_content.split("\n")

      expect(rows.size).to eq(5)
      expect(rows.join).to have_text(partner1.name, count: 4)
      expect(headers).to have_text(item2.name, count: 1)
    end

    context "when filtering on the index page" do
      context "with filters cleared" do
        it "displays all requests" do
          visit subject
          expect(page).to have_css("table tbody tr", count: 5)
          click_on "Clear Filters"
          expect(page).to have_css("table tbody tr", count: 5)
        end
      end

      context "when filtering by item" do
        it "constrains the list" do
          visit subject
          expect(page).to have_css("table tbody tr", count: 5)
          select(item2.name, from: "filters_by_request_item_id")
          click_on "Filter"
          expect(page).to have_css("table tbody tr", count: 1)
        end
      end

      context "when filtering by partner" do
        it "constrains the list" do
          visit subject
          expect(page).to have_css("table tbody tr", count: 5)
          select(partner2.name, from: "filters_by_partner")
          click_on 'Filter'
          expect(page).to have_css("table tbody tr", count: 1)
        end
      end

      context "when filtering by status" do
        it "constrains the list" do
          visit subject
          # check for all requests
          expect(page).to have_css("table tbody tr", count: 5)
          # filter
          select('Fulfilled', from: "filters_by_status")
          click_on 'Filter'
          # check for filtered requests
          expect(page).to have_css("table tbody tr", count: 1)
        end
      end

      context "when exporting as CSV" do
        it "respects the applied filters" do
          visit subject
          expect(page).to have_css("table tbody tr", count: 5)
          select(item2.name, from: "filters_by_request_item_id")
          click_on 'Filter'
          expect(page).to have_css("table tbody tr", count: 1)
          click_on 'Export Requests'

          wait_for_download
          expect(downloads.length).to eq(1)
          expect(download).to match(/.*\.csv/)

          rows = download_content.split("\n").slice(1..)

          expect(rows.size).to eq(1)
          expect(rows.join).to have_text('13', count: 1)
          expect(rows.join).to have_text(partner1.name, count: 1)
        end
      end
    end
    it_behaves_like "Date Range Picker", Request, :created_at
  end

  context "#show" do
    subject { url_prefix + "/requests/#{request.id}" }

    let!(:request) { create(:request, organization: @organization) }

    it "should show the request with a request sender if a partner user is set" do
      visit subject
      expect(page).to have_content("Request from #{request.partner.name}")
      expect(page).to have_content("Fulfillment Location Inventory")
      expect(page).to have_content("Request Sender:")
      partner_user = request.partner_user
      expect(page).to have_content("#{partner_user.name} <#{partner_user.email}>")
    end

    it "should show the request without a request sender if a partner user is not set" do
      partner_user = request.partner_user
      request.partner_user_id = nil
      request.save!
      visit subject
      expect(page).to have_content("Request from #{request.partner.name}")
      expect(page).to have_content("Fulfillment Location Inventory")
      expect(page).to have_content("Request Sender:")
      expect(page).not_to have_content("#{partner_user.name} <#{partner_user.email}>")
    end

    it "should show the number of items on-hand" do
      ####
      # Create a secondary storage location to test the sum view of estimated on-hand items
      # Add inventory items to both storage locations
      ####
      second_storage_location = create(:storage_location, organization: @organization)
      item = Item.find(request.request_items.first["item_id"])
      @storage_location.inventory_items.create!(quantity: 234, item: item)
      second_storage_location.inventory_items.create!(quantity: 100, item: item)
      visit subject
      expect(page).to have_content("334")
    end

    context "change status request" do
      before do
        visit subject
        click_on "Fulfill request"
      end

      it "should change to started" do
        visit url_prefix + "/requests"
        expect(page).to have_content "Started"
        expect(request.reload).to be_status_started
      end

      context "when save the distribution" do
        it "should change request to fulfilled", js: true do
          expect(page).to have_content "started"
          choose "Delivery"
          select @storage_location.name, from: "From storage location"
          fill_in "Comment", with: "Take my wipes... please"
          click_on "Save"

          expect(page).not_to have_content("New Distribution")
          expect(page).to have_content "Distributions"
          expect(page).to have_content "Distribution created"
          expect(request.reload.distribution_id).to eq Distribution.last.id
          expect(request.reload).to be_status_fulfilled
        end
      end
    end
  end

  describe 'canceling a request as a bank user' do
    let!(:request) { create(:request, organization: @organization) }

    context 'when a bank user cancels a request' do
      let(:reason) { Faker::Lorem.sentence }
      before do
        visit url_prefix + "/requests"
      end

      it 'should set the request as canceled/discarded and contain the reason' do
        click_on 'Cancel'
        fill_in 'Cancelation reason *', with: reason
        click_on 'Yes. Cancel Request'

        expect(page).to have_content("Request #{request.id} has been removed")
        expect(request.reload.discarded_at).not_to eq(nil)
        expect(request.reload.discard_reason).to eq(reason)
      end
    end
  end
end
