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
