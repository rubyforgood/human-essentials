RSpec.describe "Audit management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:quantity) { 7 }
  let(:item) { create(:item, organization: organization) }
  let!(:storage_location) { create(:storage_location, :with_items, item: item, item_quantity: 10, organization: organization) }

  context "while signed in as a normal user" do
    before do
      sign_in(user)
    end

    it "should not be able to visit the audits #index page" do
      visit audits_path
      expect(page).to have_content("Access Denied")
    end

    it "should not be able to visit the audits #new page" do
      visit new_audit_path
      expect(page).to have_content("Access Denied")
    end

    it "should not be able to visit the audits #edit page" do
      visit edit_audit_path(1)
      expect(page).to have_content("Access Denied")
    end

    it "should not be able to visit the audits #show page" do
      visit audit_path(1)
      expect(page).to have_content("Access Denied")
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    context "when starting a new audit" do
      subject { new_audit_path }

      it "does not display quantities in line-item drop down selector" do
        create(:storage_location, :with_items, item: item, item_quantity: 10)
        visit subject
        first('.storage-location-source').all("option").last.select_option

        find('option', text: item.name.to_s)
      end

      context "when adding new items" do
        let!(:existing_barcode) { create(:barcode_item) }
        let(:item_with_barcode) { existing_barcode.item }

        it "allows user to add items by barcode" do
          visit new_audit_path

          within "#audit_line_items" do
            # Scan existing barcode
            expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
            Barcode.boop(existing_barcode.value)

            # Ensure item quantity and name have been filled in
            expect(page).to have_field "_barcode-lookup-0", with: existing_barcode.value
            expect(page).to have_field "audit_line_items_attributes_0_quantity", with: existing_barcode.quantity.to_s
            expect(page).to have_field "audit_line_items_attributes_0_item_id", with: existing_barcode.item.id.to_s
          end
        end

        it "allows auditing items that are not in a storage location", :js do
          item = create(:item, name: "TestItemNotInStorageLocation", organization: organization)
          audit_quantity = 1234
          visit new_audit_path

          await_select2("#audit_line_items_attributes_0_item_id") do
            select storage_location.name, from: "Storage location"
          end
          select item.name, from: "audit_line_items_attributes_0_item_id"
          fill_in "audit_line_items_attributes_0_quantity", with: audit_quantity

          accept_confirm do
            click_button "Confirm Audit"
          end
          expect(page.find(".alert-info")).to have_content "Audit is confirmed"
          expect(page).to have_content(item.name)
          expect(page).to have_content(audit_quantity)

          accept_confirm do
            click_link "Finalize Audit"
          end
          expect(page.find(".alert-info")).to have_content "Audit is Finalized"

          event = Event.last
          expect(event.type).to eq "AuditEvent"
          event_line_item = Event.last.data.items.first
          expect(event_line_item.item_id).to eq item.id
          expect(event_line_item.quantity).to eq audit_quantity
        end

        it "allows user to add items that do not yet have a barcode", :js do
          item_without_barcode = create(:item)
          new_barcode = "00000000"
          new_item_name = item_without_barcode.name

          visit new_audit_path

          # Scan new barcode
          within "#audit_line_items" do
            expect(page).to have_xpath("//input[@id='_barcode-lookup-0']")
            Barcode.boop(new_barcode)
          end

          # Item lookup finds no barcode and responds by prompting user to choose an item and quantity
          within "#newBarcode" do
            fill_in "Quantity", with: 10
            select new_item_name, from: "Item"
            expect(page).to have_field("barcode_item_quantity", with: '10')
            expect(page).to have_field("barcode_item_value", with: new_barcode)
            click_on "Save"
          end

          within "#audit_line_items" do
            # Ensure item fields have been filled in
            expect(page).to have_field "audit_line_items_attributes_0_quantity", with: '10'
            expect(page).to have_field "audit_line_items_attributes_0_item_id", with: item_without_barcode.id.to_s

            # Ensure new line item was added and has focus
            expect(page).to have_field("_barcode-lookup-1", focused: true)
          end
        end
      end
    end

    context "when viewing the audits index" do
      subject { audits_path }

      it "should be able to filter the #index by storage location" do
        storage_location2 = create(:storage_location, name: "there", organization: organization)
        create(:audit, organization: organization, storage_location: storage_location)
        create(:audit, organization: organization, storage_location: storage_location2)

        visit subject
        select storage_location.name, from: "filters[at_location]"
        click_button "Filter"

        expect(page).to have_css("table tr", count: 2)
      end

      it "should be able to save progress of an audit" do
        visit subject
        click_link "New Audit"

        await_select2("#audit_line_items_attributes_0_item_id") do
          select storage_location.name, from: "Storage location"
        end

        select item.name, from: "audit_line_items_attributes_0_item_id"
        fill_in "audit_line_items_attributes_0_quantity", with: quantity.to_s

        expect do
          click_button "Save Progress"
          expect(Audit.last.in_progress?).to be_truthy
          expect(Audit.last.line_items.count).to be(1)
          expect(Audit.last.line_items.last.quantity).to be(quantity)
        end.to change { Audit.count }.by(1)

        expect(page).to have_content("Audit's progress was successfully saved.")
        expect(page).to have_content(quantity)
        expect(page).to have_content("In Progress")
        expect(page).not_to have_content("Finalize Audit")
        expect(page).to have_content("Resume Audit")
        expect(page).to have_content("Delete Audit")
      end

      it "should be able to confirm the audit from the #new page", js: true do
        visit subject
        click_link "New Audit"

        await_select2("#audit_line_items_attributes_0_item_id") do
          select storage_location.name, from: "Storage location"
        end

        select Item.last.name, from: "audit_line_items_attributes_0_item_id"
        fill_in "audit_line_items_attributes_0_quantity", with: quantity.to_s

        expect(page).to have_content("Confirm Audit")
        accept_confirm do
          click_button "Confirm Audit"
        end
        expect(page).to have_content("Audit is confirmed.")
        expect(page).to have_content(quantity)
        expect(page).to have_content("Confirmed")
        expect(page).not_to have_content("Resume Audit")
        expect(page).to have_content("Delete Audit")
        expect(page).to have_content("Finalize Audit")
      end
    end

    context "with an existing audit" do
      subject { audit_path(audit) }

      let(:audit) { create(:audit, :with_items, storage_location: storage_location, item: item, item_quantity: quantity) }

      it "should be able to delete the audit that is in progress" do
        visit subject

        expect(page).to have_content(quantity)
        expect(page).to have_content("Delete Audit")
        expect do
          accept_confirm do
            click_link "Delete Audit"
          end
          expect(page).to have_content("Audit is successfully deleted.")
        end.to change { Audit.count }.by(-1)
      end

      it "should be able to resume the audit that is in progress" do
        visit subject

        expect(page).to have_content(quantity)
        expect(page).to have_content("Resume Audit")
        click_link "Resume Audit"
        expect(page).to have_content("Edit")
        expect(page).to have_content("Confirm Audit")
        expect(page).to have_content("Save Progress")
      end

      it "should be able to confirm the audit from the #edit page" do
        visit edit_audit_path(audit)
        expect(page).to have_content("Confirm Audit")
        accept_confirm do
          click_button "Confirm Audit"
        end
        expect(page).to have_content("Audit is confirmed.")
        expect(page).to have_content(quantity)
        expect(page).to have_content("Confirmed")
        expect(page).not_to have_content("Resume Audit")
        expect(page).to have_content("Delete Audit")
        expect(page).to have_content("Finalize Audit")
      end
    end

    context "with a confirmed audit" do
      subject { audit_path(audit) }
      let(:audit) { create(:audit, :with_items, storage_location: storage_location, item: item, item_quantity: quantity, status: :confirmed) }

      it "should be able to edit the audit that is confirmed" do
        visit subject
        expect(page).not_to have_content("Resume Audit")
      end

      it "User can delete the audit that is confirmed" do
        visit subject

        expect(page).to have_content(quantity)
        expect(page).to have_content("Delete Audit")
        expect do
          accept_confirm do
            click_link "Delete Audit"
          end
          expect(page).to have_content("Audit is successfully deleted.")
        end.to change { Audit.count }.by(-1)
      end

      it "is able to finalize the audit" do
        visit subject
        expect(page).to have_content(quantity)
        expect(page).to have_content("Finalize Audit")
        expect do
          accept_confirm do
            click_link "Finalize Audit"
          end
          expect(page).to have_content("Audit is Finalized.")
        end.to change { Audit.finalized.count }.by(1)
      end

      describe "Finalizing an audit" do
        it "creates an adjustment with the differential" do
          item_quantity = 10

          visit subject
          expect(page).to have_content(quantity)
          expect(page).to have_content("Finalize Audit")
          expect do
            accept_confirm do
              click_link "Finalize Audit"
            end
            expect(page).to have_content("Audit is Finalized.")
          end.to change { storage_location.size }.by(quantity - item_quantity)
          expect(Adjustment.last.comment == "Created Automatically through the Auditing Process").to be_truthy
        end

        it "is immutable" do
          visit subject
          expect(page).to have_content("Finalize Audit")
          accept_confirm do
            click_link "Finalize Audit"
          end
          expect(page).not_to have_content("Resume Audit")
          expect(page).not_to have_content("Delete Audit")
          expect(page).not_to have_content("Finalize Audit")
          visit edit_audit_path(audit)
          expect(page).not_to have_current_path(edit_audit_path(audit))
          expect(page).to have_current_path(audits_path)
        end

        it "should not be able to delete the audit that is finalized" do
          visit subject
          expect(page).to have_content("Finalize Audit")
          accept_confirm do
            click_link "Finalize Audit"
          end
          expect(page).not_to have_content("Delete Audit")
          # Actual Deletion(`delete :destroy`) Check is done in audits_controller_spec
        end

        context "with a storage location containing multiple items" do
          let(:item2) { create(:item) }

          before do
            TestInventory.create_inventory(storage_location.organization, {
              storage_location.id => {
                item2.id => 50
              }
            })
          end

          it "creates an adjustment with the differential of only the audited item" do
            item_quantity = 10

            visit subject
            expect do
              accept_confirm do
                click_link "Finalize Audit"
              end
              expect(page).to have_content("Audit is Finalized.")
            end.to change { storage_location.size }.by(quantity - item_quantity)
          end
        end
      end
    end
  end
end
