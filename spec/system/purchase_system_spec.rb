RSpec.describe "Purchases", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  include ItemsHelper

  context "while signed in as a normal user" do
    before :each do
      sign_in user
    end

    context "When visiting the index page" do
      subject { purchases_path }

      context "In the middle of the year" do
        before :each do
          travel_to Time.zone.local(2019, 7, 1)
          visit subject
        end

        after do
          travel_back
        end

        it "User can click to the new purchase form" do
          find(".fa-plus").click

          expect(current_path).to eq(new_purchase_path)
          expect(page).to have_content "Start a new purchase"
        end

        it "User sees purchased date column" do
          storage1 = create(:storage_location, name: "storage1", organization: organization)
          purchase_date = 1.week.ago
          create(:purchase, storage_location: storage1, issued_at: purchase_date, organization: organization)
          page.refresh
          expect(page).to have_text("Purchased Date")
          expect(page).to have_text(1.week.ago.strftime("%Y-%m-%d"))
        end

        it "User sees total purchases value" do
          purchase1 = create(:purchase, amount_spent_in_cents: 1234, organization: organization)
          purchase2 = create(:purchase, amount_spent_in_cents: 2345, organization: organization)
          purchases = [purchase1, purchase2]
          page.refresh
          expect(page).to have_text("Total")
          expect(page).to have_text(purchases.sum(&:total_quantity))
          expect(page).to have_text(dollar_value(purchases.sum(&:amount_spent_in_cents)))
          expect(page).to have_text(dollar_value(3579))
        end
      end

      context "When filtering on the index page" do
        let!(:item) { create(:item, organization: organization) }
        let(:storage) { create(:storage_location, organization: organization) }
        subject { purchases_path }

        it "User can filter the #index by storage location" do
          storage1 = create(:storage_location, name: "storage1", organization: organization)
          storage2 = create(:storage_location, name: "storage2", organization: organization)
          create(:purchase, storage_location: storage1, organization: organization)
          create(:purchase, storage_location: storage2, organization: organization)
          visit subject
          expect(page).to have_css("table tbody tr", count: 2)
          select storage1.name, from: "filters[at_storage_location]"
          click_button "Filter"
          expect(page).to have_css("table tbody tr", count: 1)
        end

        it "User can filter the #index by vendor" do
          organization = create(:organization)
          vendor1 = create(:vendor, business_name: "vendor 1", organization: organization)
          vendor2 = create(:vendor, business_name: "vendor 2", organization: organization)
          create(:purchase, vendor: vendor1, organization: organization)
          create(:purchase, vendor: vendor2, organization: organization)

          sign_in create(:user, organization: organization)
          visit purchases_path

          expect(page).to have_css("table tbody tr", count: 2)
          select vendor1.business_name, from: "filters[from_vendor]"
          click_button "Filter"
          expect(page).to have_css("table tbody tr", count: 1)
        end

        it_behaves_like "Date Range Picker", Purchase, :issued_at
      end
    end

    context "When creating a new purchase" do
      before(:each) do
        @item = create(:item, organization: organization)
        @storage_location = create(:storage_location, organization: organization)
        @vendor = create(:vendor, organization: organization)
        organization.reload
      end
      subject { new_purchase_path }

      context "via manual entry" do
        before(:each) do
          visit subject
        end

        it "User can create vendor from purchase" do
          select "---Not Listed---", from: "purchase_vendor_id"

          find(".modal-content")
          expect(page).to have_content("New Vendor")

          fill_in "vendor_business_name", with: "businesstest"
          fill_in "vendor_contact_name", with: "test"
          fill_in "vendor_email", with: "123@mail.ru"
          find("#vendor-submit").click
          select "businesstest", from: "purchase_vendor_id"
          expect(page).to have_no_content("New Vendor")
        end

        it "User can create a purchase using dollars decimal amount" do
          select @storage_location.name, from: "purchase_storage_location_id"
          select @item.name, from: "purchase_line_items_attributes_0_item_id"
          select @vendor.business_name, from: "purchase_vendor_id"
          fill_in "purchase_line_items_attributes_0_quantity", with: "5"
          fill_in "purchase_amount_spent", with: "1,234.56"

          expect do
            click_button "Save"
          end.to change { Purchase.count }.by(1)

          expect(Purchase.last.amount_spent_in_dollars).to eq(1234.56)
          expect(Purchase.last.amount_spent_in_cents).to eq(123_456)
        end

        it "User can create a purchase IN THE PAST" do
          select @storage_location.name, from: "purchase_storage_location_id"
          select @item.name, from: "purchase_line_items_attributes_0_item_id"
          select @vendor.business_name, from: "purchase_vendor_id"
          fill_in "purchase_line_items_attributes_0_quantity", with: "5"
          fill_in "purchase_issued_at", with: "2001-01-01"
          fill_in "purchase_amount_spent", with: "10"

          expect do
            click_button "Save"
          end.to change { Purchase.count }.by(1)

          visit purchase_path(Purchase.last)

          expected_date = "January 1 2001 (entered: #{Purchase.last.created_at.to_fs(:distribution_date)})"
          expected_breadcrumb_date = "#{@vendor.business_name} on January 1 2001"
          aggregate_failures do
            expect(page).to have_text(expected_date)
            expect(page).to have_text(expected_breadcrumb_date)
          end
        end

        it "Does not include inactive items in the line item fields" do
          visit new_purchase_path

          select @storage_location.name, from: "purchase_storage_location_id"
          expect(page).to have_content(@item.name)
          select @item.name, from: "purchase_line_items_attributes_0_item_id"

          @item.update(active: false)

          page.refresh
          select @storage_location.name, from: "purchase_storage_location_id"
          expect(page).to have_no_content(@item.name)
        end

        it "multiple line items for the same item type are accepted and combined on the backend" do
          select @storage_location.name, from: "purchase_storage_location_id"
          select @item.name, from: "purchase_line_items_attributes_0_item_id"
          select @vendor.business_name, from: "purchase_vendor_id"
          fill_in "purchase_line_items_attributes_0_quantity", with: "5"
          page.find(:css, "#__add_line_item").click
          all(".li-name select").last.find('option', text: @item.name).select_option
          all(".li-quantity input").last.set(11)

          fill_in "purchase_amount_spent", with: "10"

          expect do
            click_button "Save"
          end.to change { Purchase.count }.by(1)

          expect(Purchase.last.line_items.first.quantity).to eq(16)
        end

        context 'when creating a purchase incorrectly' do
          # Bug fix -- Issue #71
          # When a user creates a purchase without it passing validation, the items
          # dropdown is not populated on the return trip.
          it "items dropdown is still repopulated even if initial submission doesn't validate" do
            item_count = organization.items.count + 1 # Adds 1 for the "choose an item" option
            expect(page).to have_css("#purchase_line_items_attributes_0_item_id option", count: item_count + 1)
            click_button "Save"

            expect(page).to have_content("Failed to create purchase due to:")
            expect(page).to have_css("#purchase_line_items_attributes_0_item_id option", count: item_count + 1)
          end

          it "should display failure with error messages" do
            click_button "Save"
            expect(page).to have_content("Failed to create purchase due to:\nVendor must exist\nAmount spent is not a number\nAmount spent in cents must be greater than 0")
          end
        end
      end

      # Bug fix -- Issue #378
      # A user can view another organizations purchase
      context "Editing purchase" do
        it "A user can see purchased_from value" do
          purchase = create(:purchase, purchased_from: "Old Vendor", organization: organization)
          visit edit_purchase_path(purchase)
          expect(page).to have_content("Vendor (Old Vendor)")
        end

        it "A user can view another organizations purchase" do
          purchase = create(:purchase, organization: create(:organization))
          visit edit_purchase_path(purchase)
          expect(page).to have_content("Still haven't found what you're looking for")
        end
      end

      context "via barcode entry" do
        before(:each) do
          @existing_barcode = create(:barcode_item, organization: organization)
          @item_with_barcode = @existing_barcode.item
          @item_no_barcode = create(:item, organization: organization)
          visit new_purchase_path
        end

        it "a user can add items via scanning them in by barcode" do
          # enter the barcode into the barcode field
          within "#purchase_line_items" do
            expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
            Barcode.boop(@existing_barcode.value)
          end
          expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: @existing_barcode.quantity.to_s
        end

        it "User scan same barcode 2 times" do
          within "#purchase_line_items" do
            expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
            Barcode.boop(@existing_barcode.value)
          end

          expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: @existing_barcode.quantity.to_s

          within "#purchase_line_items" do
            expect(page).to have_css('.__barcode_item_lookup', count: 2)
            Barcode.boop(@existing_barcode.value)
          end

          expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: (@existing_barcode.quantity * 2).to_s
        end

        it "a user can add items that do not yet have a barcode" do
          new_barcode_value = "8594159081517"
          within "#purchase_line_items" do
            expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
            Barcode.boop(new_barcode_value)
          end

          expect(page.find(".modal-title").text).to eq("Add New Barcode")

          within ".modal-content" do
            fill_in "barcode_item_quantity", with: 3
            select Item.alphabetized.first.name, from: "barcode_item_barcodeable_id"
            find("button", text: "Save").click
          end

          expect(page).to have_field "purchase_line_items_attributes_0_quantity", with: 3
          expect(page).to have_field "_barcode-lookup-0", with: new_barcode_value

          new_barcode_item = BarcodeItem.last
          expect(new_barcode_item.value).to eq(new_barcode_value)
          expect(new_barcode_item.quantity).to eq(3)
          expect(new_barcode_item.barcodeable_type).to eq("Item")
          expect(new_barcode_item.barcodeable_id).to eq(Item.alphabetized.first.id)
        end
      end
      it "should not display inactive storage locations in dropdown" do
        create(:storage_location, name: "Inactive R Us", discarded_at: Time.zone.now)
        visit subject
        expect(page).to have_no_content "Inactive R Us"
      end
    end

    context "When visiting an existing purchase" do
      subject { purchases_path }

      it "does not allow deletion of a purchase" do
        purchase = create(:purchase, organization: organization)
        visit "#{subject}/#{purchase.id}"
        expect(page).to_not have_link("Delete")
      end
    end
  end

  context "while signed in as an organization admin" do
    let!(:purchase) { create(:purchase, :with_items, item_quantity: 10, organization: organization) }
    subject { purchases_path }

    before do
      sign_in organization_admin
    end

    it "allows deletion of a purchase" do
      visit "#{subject}/#{purchase.id}"
      expect(page).to have_link("Delete")
      accept_confirm do
        click_on "Delete"
      end
      expect(page).to have_content "Purchase #{purchase.id} has been removed!"
      expect(page).to have_content "0 (Total)"
    end
  end
end
