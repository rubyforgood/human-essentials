RSpec.feature "Audit management", type: :feature do
  let!(:url_prefix) { "/#{@organization.to_param}" }
  let(:quantity) { 7 }

  context "while signed in as a normal user" do
    before do
      sign_in(@user)
    end

    scenario "User can not visit the audits #index page" do
      visit url_prefix + "/audits"
      expect(page).to have_content("Access Denied")
    end

    scenario "User can not visit the audits #new page" do
      visit url_prefix + "/audits/new"
      expect(page).to have_content("Access Denied")
    end

    scenario "User can not visit the audits #edit page" do
      visit url_prefix + "/audits/1/edit"
      expect(page).to have_content("Access Denied")
    end

    scenario "User can not visit the audits #show page" do
      visit url_prefix + "/audits/1"
      expect(page).to have_content("Access Denied")
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end

    scenario "User can filter the #index by storage location" do
      storage_location = create(:storage_location, name: "here", organization: @organization)
      storage_location2 = create(:storage_location, name: "there", organization: @organization)
      create(:audit, organization: @organization, storage_location: storage_location)
      create(:audit, organization: @organization, storage_location: storage_location2)

      visit url_prefix + "/audits"
      select storage_location.name, from: "filters_at_location"
      click_button "Filter"

      expect(page).to have_css("table tr", count: 2)
    end

    scenario "User can save progress of an audit" do
      storage_location = create(:storage_location, :with_items, organization: @organization)
      visit url_prefix + "/audits"
      click_link "New Audit"
      select storage_location.name, from: "From storage location"
      select Item.last.name, from: "audit_line_items_attributes_0_item_id"
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

    scenario "User can resume the audit that is in progress" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity)
      visit url_prefix + "/audits/" + audit.to_param

      expect(page).to have_content(quantity)
      expect(page).to have_content("Resume Audit")
      click_link "Resume Audit"
      expect(page).to have_content("Edit")
      expect(page).to have_content("Confirm Audit")
      expect(page).to have_content("Save Progress")
    end

    scenario "User can delete the audit that is in progress", js: true do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity)
      visit url_prefix + "/audits/" + audit.to_param

      expect(page).to have_content(quantity)
      expect(page).to have_content("Delete Audit")
      expect do
        click_link "Delete Audit"
        page.driver.browser.switch_to.alert.accept
        expect(page).to have_content("Audit is successfully deleted.")
      end.to change { Audit.count }.by(-1)
    end

    scenario "User can confirm the audit from the #new page", js: true do
      storage_location = create(:storage_location, :with_items, organization: @organization)
      visit url_prefix + "/audits"
      click_link "New Audit"
      select storage_location.name, from: "From storage location"
      select Item.last.name, from: "audit_line_items_attributes_0_item_id"
      fill_in "audit_line_items_attributes_0_quantity", with: quantity.to_s

      expect(page).to have_content("Confirm Audit")
      click_button "Confirm Audit"
      page.driver.browser.switch_to.alert.accept
      expect(page).to have_content("Audit is confirmed.")
      expect(page).to have_content(quantity)
      expect(page).to have_content("Confirmed")
      expect(page).not_to have_content("Resume Audit")
      expect(page).to have_content("Delete Audit")
      expect(page).to have_content("Finalize Audit")
    end

    scenario "User can confirm the audit from the #edit page", js: true do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity)

      visit url_prefix + "/audits/" + audit.to_param + "/edit"
      expect(page).to have_content("Confirm Audit")
      click_button "Confirm Audit"
      page.driver.browser.switch_to.alert.accept
      expect(page).to have_content("Audit is confirmed.")
      expect(page).to have_content(quantity)
      expect(page).to have_content("Confirmed")
      expect(page).not_to have_content("Resume Audit")
      expect(page).to have_content("Delete Audit")
      expect(page).to have_content("Finalize Audit")
    end

    scenario "User can edit the audit that is confirmed" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity, status: :confirmed)
      visit url_prefix + "/audits/" + audit.to_param
      expect(page).not_to have_content("Resume Audit")
    end

    scenario "User can delete the audit that is confirmed", js: true do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity, status: :confirmed)
      visit url_prefix + "/audits/" + audit.to_param

      expect(page).to have_content(quantity)
      expect(page).to have_content("Delete Audit")
      expect do
        click_link "Delete Audit"
        page.driver.browser.switch_to.alert.accept
        expect(page).to have_content("Audit is successfully deleted.")
      end.to change { Audit.count }.by(-1)
    end

    scenario "User can finalize the audit", js: true do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity, status: :confirmed)
      visit url_prefix + "/audits/" + audit.to_param
      expect(page).to have_content(quantity)
      expect(page).to have_content("Finalize Audit")
      expect do
        click_link "Finalize Audit"
        page.driver.browser.switch_to.alert.accept
        expect(page).to have_content("Audit is Finalized.")
      end.to change { Audit.finalized.count }.by(1)
    end

    scenario "Finalizing the audit creates an adjustment with the differential", js: true do
      item = create(:item)
      item_quantity = 10
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: item_quantity)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity, status: :confirmed)
      visit url_prefix + "/audits/" + audit.to_param
      expect(page).to have_content(quantity)
      expect(page).to have_content("Finalize Audit")
      expect do
        click_link "Finalize Audit"
        page.driver.browser.switch_to.alert.accept
        expect(page).to have_content("Audit is Finalized.")
      end.to change { storage_location.size }.by(quantity - item_quantity)
      expect(Adjustment.last.comment == "Created Automatically through the Auditing Process").to be_truthy
    end

    scenario "Finalized audit is immutable", js: true do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity, status: :confirmed)
      visit url_prefix + "/audits/" + audit.to_param
      expect(page).to have_content("Finalize Audit")
      click_link "Finalize Audit"
      page.driver.browser.switch_to.alert.accept
      expect(page).not_to have_content("Resume Audit")
      expect(page).not_to have_content("Delete Audit")
      expect(page).not_to have_content("Finalize Audit")
      visit url_prefix + "/audits/" + audit.to_param + "/edit"
      expect(page).not_to have_current_path(edit_audit_path(@organization.to_param, audit.to_param))
      expect(page).to have_current_path(audits_path(@organization.to_param))
    end

    scenario "User can not delete the audit that is finalized", js: true do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = create(:audit, :with_items, storage_location: storage_location, item: storage_location.items.first, item_quantity: quantity, status: :confirmed)
      visit url_prefix + "/audits/" + audit.to_param
      expect(page).to have_content("Finalize Audit")
      click_link "Finalize Audit"
      page.driver.browser.switch_to.alert.accept
      expect(page).not_to have_content("Delete Audit")
      # Actual Deletion(`delete :destroy`) Check is done in audits_controller_spec
    end
  end
end
