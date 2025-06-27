RSpec.describe "Reports Distributions", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let!(:partner) { create(:partner, organization: organization, name: "Test Partner") }
  let!(:storage_location) { create(:storage_location, organization: organization, name: "Test Storage Location") }

  context "while logged in" do
    before do
      sign_in(user)
    end

    context "Distributions - Itemized" do
      before do
        create(:item, organization: organization)
        create(:storage_location, organization: organization)
        create(:donation_site, organization: organization)
        create(:product_drive, organization: organization)
        create(:product_drive_participant, organization: organization)
        create(:product_drive_participant, organization: organization, contact_name: "contact without business name", business_name: "")
        create(:manufacturer, organization: organization)
        organization.reload

        visit new_donation_path

        select Donation::SOURCES[:misc], from: "donation_source"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "5"
        fill_in "donation_issued_at", with: "2001-01-01"

        click_button "Save"

        visit new_distribution_path
      end

      it "Ensuring that the result of the distribution index is zero instead of Unknow" do
        select "Test Partner", from: "Partner"
        select "Test Storage Location", from: "From storage location"
        fill_in "distribution_line_items_attributes_0_quantity", with: "5"
        choose "Pick up"

        click_button "Save", match: :first
        within "#distributionConfirmationModal" do
          click_button "Yes, it's correct"
        end

        visit reports_itemized_distributions_path

        expect(page).to have_selector(:table_row, "Total On Hand" => "0")
      end
    end

    context "Donations - Itemized" do
      let(:donation) { create :donation, :with_items }

      before do
        create(:item, organization: organization)
        create(:storage_location, organization: organization)
        create(:donation_site, organization: organization)
        create(:product_drive, organization: organization)
        create(:product_drive_participant, organization: organization)
        create(:product_drive_participant, organization: organization, contact_name: "contact without business name", business_name: "")
        create(:manufacturer, organization: organization)
        organization.reload
      end

      it "Ensuring that the result of the donation index is zero instead of Unknow" do
        visit new_donation_path
        select Donation::SOURCES[:misc], from: "donation_source"
        select StorageLocation.first.name, from: "donation_storage_location_id"
        select Item.alphabetized.first.name, from: "donation_line_items_attributes_0_item_id"
        fill_in "donation_line_items_attributes_0_quantity", with: "20"
        fill_in "donation_issued_at", with: "2025-04-15"

        click_button "Save"

        visit new_distribution_path

        select "Test Partner", from: "Partner"
        select "Test Storage Location", from: "From storage location"
        fill_in "distribution_line_items_attributes_0_quantity", with: "20"
        choose "Pick up"

        click_button "Save", match: :first

        within "#distributionConfirmationModal" do
          click_button "Yes, it's correct"
        end

        visit reports_itemized_donations_path
        fill_in "filters_date_range", with: "April 15, 2025 - July 15, 2025"
        click_button "Filter"

        expect(page).to have_selector(:table_row, "Total On Hand" => "0")
      end
    end
  end
end
