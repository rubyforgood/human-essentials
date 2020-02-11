RSpec.describe "Barcode Items Admin", type: :system, js: true do
  before do
    sign_in(@super_admin)
  end

  context "while signed in as a super admin" do
    before do
      visit admin_barcode_items_path
    end

    let(:item) { create(:item) }
    let!(:barcode_item) { create(:global_barcode_item) }
    it "should create a new global barcode" do
      barcode_value = 66_666
      click_on "Add New Barcode"
      fill_in "Quantity", with: 100
      select item.base_item.name, from: "barcode_item_barcodeable_id"
      fill_in "Barcode", with: barcode_value
      click_on "Save"
      expect(page).to have_content(barcode_value)
      expect(page).to have_content("Tampons")
      expect(page).to have_content("100")
    end

    it "should edit an existing global barcode"
    it "should delete a global barcode" do
      visit admin_barcode_items_path
      page.refresh
      expect(page).to have_content barcode_item.base_item.name
      expect(
        accept_confirm do
          click_on "Delete"
        end
      ).to include "Are you sure you want to delete"
      expect(page).to have_no_content barcode_item.base_item.name
    end

    it "should view a barcode shows details about it"
  end
end
