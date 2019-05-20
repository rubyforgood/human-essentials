RSpec.describe "Barcode Items Admin", type: :system, js: true do
  before do
    sign_in(@super_admin)
  end

  context "while signed in as a super admin" do
    before do
      visit admin_barcode_items_path
    end

    let(:item) { create(:item) }

    it "should create a new global barcode" do
      click_on "Add New Barcode"
      fill_in "Quantity", with: 100
      select item.base_item.name, from: "barcode_item_barcodeable_id"
      fill_in "Barcode", with: 6666
      click_on "Save"
      expect(page).to have_content("6666")
      expect(page).to have_content("Tampons")
      expect(page).to have_content("100")
    end

    it "should edit an existing global barcode"
    it "should delete a global barcode"
    it "should view a barcode shows details about it"
  end
end
