require "rails_helper"

RSpec.describe "BarcodeItems", type: :system do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let!(:barcode_items) { create_list(:barcode_item, 6, organization: organization) }
  let(:items) { barcode_items.map(&:barcodeable) }
  let(:barcode_item) { barcode_items.first }

  context "when organizational admin is signed in" do
    before do
      sign_in(organization_admin)
    end
    describe "Creating a Barcode Item" do
      before { visit new_barcode_item_path }

      it "retains item dropdown options after an unsuccessful form submission" do
        select items.first.name, from: "Item"
        click_button "Save"
        expect(page).to have_content("Something didn't work quite right -- try again?")
        items.each do |item|
          expect(page).to have_select("Item", with_options: [item.name])
        end
      end
    end

    describe "Editing a Barcode Item" do
      before { visit edit_barcode_item_path(barcode_item) }
      it "retains item dropdown options after an unsuccessful form submission" do
        fill_in "Barcode", with: ""
        click_button "Save"
        expect(page).to have_content("Something didn't work quite right -- try again?")
        items.each do |item|
          expect(page).to have_select("Item", with_options: [item.name])
        end
      end
    end

    describe "when admin visits index page" do
      before { visit barcode_items_path }

      it "displays all barcode items" do
        barcode_items.each do |barcode_item|
          expect(page).to have_content(barcode_item.value)
          expect(page).to have_content(barcode_item.quantity)
          expect(page).to have_content(barcode_item.barcodeable_type)
        end
      end
    end
  end
end
