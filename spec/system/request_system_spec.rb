RSpec.describe "Requests", type: :system, js: true do
  before do
    sign_in(@user)
    @request = create(:request, organization: @organization)
    @storage_location = create(:storage_location, organization: @organization)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }

  context "While viewing the requests index page" do
    subject { url_prefix + "/requests" }

    it "should list requests" do
      visit subject
      expect(page).to have_xpath("//h1", text: "Requests")
    end

    it_behaves_like "Date Range Picker", Request
  end

  context "While viewing the request page" do
    it "should show the request" do
      visit url_prefix + "/requests/#{@request.id}"
      expect(page).to have_content("Request from #{@request.partner.name}")
      expect(page).to have_content("Estimated on-hand")
    end

    it "should show the number of items on-hand" do
      ####
      # Create a secondary storage location to test the sum view of estimated on-hand items
      # Add inventory items to both storage locations
      ####
      @second_storage_location = create(:storage_location, organization: @organization)
      @item = Item.find(@request.request_items.first["item_id"])
      @storage_location.inventory_items.create!(quantity: 234, item: @item)
      @second_storage_location.inventory_items.create!(quantity: 100, item: @item)
      visit url_prefix + "/requests/#{@request.id}"
      expect(page).to have_content("334")
    end

    context "change status request" do
      before do
        visit url_prefix + "/requests/#{@request.id}"
        click_on "Fulfill request"
      end

      it "should change to started" do
        visit url_prefix + "/requests"
        expect(page).to have_content "Started"
        expect(@request.reload).to be_status_started
      end

      context "when save the distribution" do
        it "should change request to fulfilled", js: true do
          expect(page).to have_content "started"
          choose "Delivery"
          select @storage_location.name, from: "From storage location"
          fill_in "Comment", with: "Take my wipes... please"
          click_on "Save"
          expect(page).to have_content "Distributions"
          expect(page).to have_content "Distribution created"
          expect(@request.reload.distribution_id).to eq Distribution.last.id
          expect(@request.reload).to be_status_fulfilled
        end
      end
    end

    context "when filtering on the index page" do
      subject { url_prefix + "/requests" }

      let(:item1) { create(:item, name: "Good item") }
      let(:item2) { create(:item, name: "Crap item") }
      let(:partner1) { create(:partner, name: "This Guy", email: "thisguy@example.com") }
      let(:partner2) { create(:partner, name: "Not This Guy", email: "ntg@example.com") }

      it "filters by item id" do
        create(:request, request_items: [{ "item_id": item1.id, "quantity": '3' }])
        create(:request, request_items: [{ "item_id": item2.id, "quantity": '3' }])

        visit subject
        # check for all requests
        expect(page).to have_css("table tbody tr", count: 3)
        # filter
        select(item1.name, from: "filters_by_request_item_id")
        click_button("Filter")
        # check for filtered requests
        expect(page).to have_css("table tbody tr", count: 1)
      end

      it "filters by partner" do
        create(:request, partner: partner1)
        create(:request, partner: partner2)

        visit subject
        # check for all requests
        expect(page).to have_css("table tbody tr", count: 3)
        # filter
        select(partner1.name, from: "filters_by_partner")
        click_button("Filter")
        # check for filtered requests
        expect(page).to have_css("table tbody tr", count: 1)
      end

      it "filters by status" do
        request1 = create(:request, status: "fulfilled")
        create(:request, status: "pending")

        visit subject
        # check for all requests
        expect(page).to have_css("table tbody tr", count: 3)
        # filter
        select(request1.status.humanize, from: "filters_by_status")
        click_button("Filter")
        # check for filtered requests
        expect(page).to have_css("table tbody tr", count: 1)
      end

      it_behaves_like "Date Range Picker", Request, :created_at
    end
  end
end
