RSpec.feature "Purchases", type: :feature, js: true do
  before :each do
    sign_in @user
    @url_prefix = "/#{@organization.short_name}"
  end

  context "When visiting the index page" do
    before(:each) do
      visit @url_prefix + "/purchases"
    end

    scenario "User can click to the new purchase form" do
      find(".fa-plus").click

      expect(current_path).to eq(new_purchase_path(@organization))
      expect(page).to have_content "Start a new purchase"
    end
  end

  context "When filtering on the index page" do
    let!(:item) { create(:item) }

    scenario "User can filter the #index by storage location" do
      storage1 = create(:storage_location, name: "storage1")
      storage2 = create(:storage_location, name: "storage2")
      create(:purchase, storage_location: storage1)
      create(:purchase, storage_location: storage2)
      visit @url_prefix + "/purchases"
      expect(page).to have_css("table tbody tr", count: 2)
      select storage1.name, from: "filters_at_storage_location"
      click_button "Filter"
      expect(page).to have_css("table tbody tr", count: 1)
    end
  end

  context "When creating a new purchase" do
    before(:each) do
      create(:item, organization: @organization)
      create(:storage_location, organization: @organization)
      @organization.reload
    end

    context "via manual entry" do
      before(:each) do
        visit @url_prefix + "/purchases/new"
      end

      scenario "User can create a purchase IN THE PAST" do
        select StorageLocation.first.name, from: "purchase_storage_location_id"
        select Item.alphabetized.first.name, from: "purchase_line_items_attributes_0_item_id"
        fill_in "purchase_line_items_attributes_0_quantity", with: "5"
        fill_in "purchase_issued_at", with: "01/01/2001"
        fill_in "purchase_amount_spent", with: "10"

        expect do
          click_button "Create Purchase"
        end.to change { Purchase.count }.by(1)

        expect(Purchase.last.issued_at).to eq(Date.parse("01/01/2001"))
      end

      scenario "multiple line items for the same item type are accepted and combined on the backend" do
        select StorageLocation.first.name, from: "purchase_storage_location_id"
        select Item.alphabetized.first.name, from: "purchase_line_items_attributes_0_item_id"
        fill_in "purchase_line_items_attributes_0_quantity", with: "5"
        page.find(:css, "#__add_line_item").click
        select_id = page.find(:xpath, '//*[@id="purchase_line_items"]/div[2]/select')[:id]
        select Item.alphabetized.first.name, from: select_id
        text_id = page.find(:xpath, '//*[@id="purchase_line_items"]/div[2]/input[2]')[:id]
        fill_in text_id, with: "10"
        fill_in "purchase_amount_spent", with: "10"

        expect do
          click_button "Create Purchase"
        end.to change { Purchase.count }.by(1)

        expect(Purchase.last.line_items.first.quantity).to eq(15)
      end

      # Bug fix -- Issue #71
      # When a user creates a purchase without it passing validation, the items
      # dropdown is not populated on the return trip.
      scenario "items dropdown is still repopulated even if initial submission doesn't validate" do
        item_count = @organization.items.count + 1 # Adds 1 for the "choose an item" option
        expect(page).to have_xpath("//select[@id='purchase_line_items_attributes_0_item_id']/option", count: item_count)
        click_button "Create Purchase"

        expect(page).to have_content("error")
        expect(page).to have_xpath("//select[@id='purchase_line_items_attributes_0_item_id']/option", count: item_count)
      end
    end

    # Bug fix -- Issue #378
    # A user can view another organizations purchase
    context "Editing purchase" do
      before(:each) do
        purchase = create(:purchase, organization: create(:organization))
        visit edit_purchase_path(@user.organization.short_name, purchase)
      end

      scenario "A user can view another organizations puchanse" do
        expect(page).to have_content("Still haven't found what you're looking for")
      end
    end

    context "via barcode entry" do
      before(:each) do
        initialize_barcodes
        visit @url_prefix + "/purchases/new"
      end

      scenario "a user can add items via scanning them in by barcode", :js do
        pending "The JS doesn't appear to be executing in this correctly"
        # enter the barcode into the barcode field
        within "#purchase_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          fill_in "_barcode-lookup-0", with: @existing_barcode.value + 13.chr
        end
        # the form should update
        # save_and_open_page
        expect(page).to have_xpath('//input[@id="purchase_line_items_attributes_0_quantity"]')
        qty = page.find(:xpath, '//input[@id="purchase_line_items_attributes_0_quantity"]').value

        expect(qty).to eq(@existing_barcode.quantity.to_s)
      end

      scenario "User scan same barcode 2 times", :js do
        pending "The JS doesn't appear to be executing in this correctly"
        within "#purchase_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
          fill_in "_barcode-lookup-0", with: @existing_barcode.value + 13.chr
        end

        expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: @existing_barcode.quantity.to_s

        page.find(:css, "#__add_line_item").click

        within "#purchase_line_items" do
          expect(page).to have_xpath("//input[@id='_barcode-lookup-1']")
          fill_in "_barcode-lookup-1", with: @existing_barcode.value + 13.chr
        end

        expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: (@existing_barcode.quantity * 2).to_s
      end

      scenario "a user can add items that do not yet have a barcode" do
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
