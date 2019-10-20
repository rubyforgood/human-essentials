RSpec.describe "Purchases", type: :system, js: true do
  let!(:url_prefix) { "/#{@organization.short_name}" }
  before :each do
    sign_in @user
  end

  context "When visiting the index page" do
    before(:each) do
      visit url_prefix + "/purchases"
    end

    it "User can click to the new purchase form" do
      find(".fa-plus").click

      expect(current_path).to eq(new_purchase_path(@organization))
      expect(page).to have_content "Start a new purchase"
    end

    it "User sees purchased date column" do
      storage1 = create(:storage_location, name: "storage1")
      purchase_date = Time.zone.parse("Dec 8 1971 10:19")
      create(:purchase, storage_location: storage1, created_at: purchase_date)
      page.refresh
      expect(page).to have_text("Purchased Date")
      expect(page).to have_text("1971-12-08")
    end
  end

  context "When filtering on the index page" do
    let!(:item) { create(:item) }
    let(:storage) { create(:storage_location) }
    subject { url_prefix + "/purchases" }

    it "User can filter the #index by storage location" do
      storage1 = create(:storage_location, name: "storage1")
      storage2 = create(:storage_location, name: "storage2")
      create(:purchase, storage_location: storage1)
      create(:purchase, storage_location: storage2)
      visit subject
      expect(page).to have_css("table tbody tr", count: 3)
      select storage1.name, from: "filters_at_storage_location"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end

    it "User can filter the #index by vendor" do
      vendor1 = create(:vendor, business_name: "vendor 1")
      vendor2 = create(:vendor, business_name: "vendor 2")
      create(:purchase, vendor: vendor1)
      create(:purchase, vendor: vendor2)
      visit subject
      expect(page).to have_css("table tbody tr", count: 3)
      select vendor1.business_name, from: "filters_from_vendor"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end

    it "Filters by date" do
      storage = create(:storage_location, name: "storage")
      create(:purchase, storage_location: storage, issued_at: Date.new(2018, 3, 1))
      create(:purchase, storage_location: storage, issued_at: Date.new(2018, 3, 1))
      create(:purchase, storage_location: storage, issued_at: Date.new(2018, 2, 1))

      visit subject
      fill_in("dates[date_from]", with: "01/01/2018").send_keys(:escape)
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 4)

      fill_in("dates_date_from", with: "03/01/2018").send_keys(:escape)
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 3)

      fill_in("dates_date_to", with: "03/01/2018").send_keys(:escape)
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 3)

      fill_in("dates_date_to", with: "02/28/2018").send_keys(:escape)
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 1)
    end
  end

  context "When creating a new purchase" do
    before(:each) do
      create(:item, organization: @organization)
      create(:storage_location, organization: @organization)
      create(:vendor, organization: @organization)
      @organization.reload
    end
    subject { url_prefix + "/purchases/new" }

    context "via manual entry" do
      before(:each) do
        visit subject
      end

      it "User can create vendor from purchase" do
        select "---Not Listed---", from: "purchase_vendor_id"
        expect(page).to have_content("New Vendor")
        fill_in "vendor_business_name", with: "businesstest"
        fill_in "vendor_contact_name", with: "test"
        fill_in "vendor_email", with: "123@mail.ru"
        click_on "vendor-submit"
        select "businesstest", from: "purchase_vendor_id"
      end

      it "User can create a purchase IN THE PAST" do
        select StorageLocation.first.name, from: "purchase_storage_location_id"
        select Item.alphabetized.first.name, from: "purchase_line_items_attributes_0_item_id"
        select Vendor.first.business_name, from: "purchase_vendor_id"
        fill_in "purchase_line_items_attributes_0_quantity", with: "5"
        fill_in "purchase_issued_at", with: "01/01/2001"
        fill_in "purchase_amount_spent_in_cents", with: "10"

        expect do
          click_button "Save"
        end.to change { Purchase.count }.by(1)

        expect(Purchase.last.issued_at).to eq(Date.parse("01/01/2001"))
      end

      it "Does not include inactive items in the line item fields" do
        visit url_prefix + "/purchases/new"

        item = Item.alphabetized.first

        select StorageLocation.first.name, from: "purchase_storage_location_id"
        expect(page).to have_content(item.name)
        select item.name, from: "purchase_line_items_attributes_0_item_id"

        item.update(active: false)

        page.refresh
        select StorageLocation.first.name, from: "purchase_storage_location_id"
        expect(page).to have_no_content(item.name)
      end

      it "multiple line items for the same item type are accepted and combined on the backend" do
        select StorageLocation.first.name, from: "purchase_storage_location_id"
        select Item.alphabetized.first.name, from: "purchase_line_items_attributes_0_item_id"
        select Vendor.first.business_name, from: "purchase_vendor_id"
        fill_in "purchase_line_items_attributes_0_quantity", with: "5"
        page.find(:css, "#__add_line_item").click
        select_id = page.find(:xpath, '//*[@id="purchase_line_items"]/section[2]/div/*/div/select')[:id]
        select Item.alphabetized.first.name, from: select_id
        text_id = page.find(:xpath, '//*[@id="purchase_line_items"]/section[2]/div/*/div/input[@type="number"]')[:id]
        fill_in text_id, with: "10"
        fill_in "purchase_amount_spent_in_cents", with: "10"

        expect do
          click_button "Save"
        end.to change { Purchase.count }.by(1)

        expect(Purchase.last.line_items.first.quantity).to eq(15)
      end

      # Bug fix -- Issue #71
      # When a user creates a purchase without it passing validation, the items
      # dropdown is not populated on the return trip.
      it "items dropdown is still repopulated even if initial submission doesn't validate" do
        item_count = @organization.items.count + 1 # Adds 1 for the "choose an item" option
        expect(page).to have_xpath("//select[@id='purchase_line_items_attributes_0_item_id']/option", count: item_count + 1)
        click_button "Save"

        expect(page).to have_content("error")
        expect(page).to have_xpath("//select[@id='purchase_line_items_attributes_0_item_id']/option", count: item_count + 1)
      end
    end

    # Bug fix -- Issue #378
    # A user can view another organizations purchase
    context "Editing purchase" do
      it "A user can see purchased_from value" do
        purchase = create(:purchase, purchased_from: "Old Vendor")
        visit edit_purchase_path(@organization.to_param, purchase)
        expect(page).to have_content("Vendor (Old Vendor)")
      end

      it "A user can view another organizations purchase" do
        purchase = create(:purchase, organization: create(:organization))
        visit edit_purchase_path(@user.organization.short_name, purchase)
        expect(page).to have_content("Still haven't found what you're looking for")
      end
    end

    context "via barcode entry" do
      before(:each) do
        initialize_barcodes
        visit url_prefix + "/purchases/new"
      end

      it "a user can add items via scanning them in by barcode" do
        # enter the barcode into the barcode field
        within "#purchase_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          Barcode.boop(@existing_barcode.value)
        end
        # the form should update
        expect(page).to have_xpath('//input[@id="purchase_line_items_attributes_0_quantity"]')
        qty = page.find(:xpath, '//input[@id="purchase_line_items_attributes_0_quantity"]').value

        expect(qty).to eq(@existing_barcode.quantity.to_s)
      end

      it "User scan same barcode 2 times" do
        within "#purchase_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          Barcode.boop(@existing_barcode.value)
        end

        expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: @existing_barcode.quantity.to_s

        within "#purchase_line_items" do
          expect(page).to have_css('.__barcode_item_lookup', count: 2)
          Barcode.boop(@existing_barcode.value, "new_line_items")
        end

        expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: (@existing_barcode.quantity * 2).to_s
      end

      it "a user can add items that do not yet have a barcode" do
        # enter a new barcode
        # form finds no barcode and responds by prompting user to choose an item and quantity
        # fill that in
        # saves new barcode
        # form updates
        pending "TODO: adding items with a new barcode"
        raise
      end
    end
  end
end
