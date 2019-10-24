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
    it "should delete a global barcode", focus: true do
      visit admin_barcode_items_path
      target_name = barcode_item.base_item.name
      page.refresh

      options = page.all('option').map(&:text)
      expect(options).to include(target_name)

      expect(
        accept_confirm do
          click_on "Delete"
        end
      ).to include "Are you sure you want to delete"

      test_deletion_using_have_content = -> do
        expect(page).not_to have_content target_name, exact: true
      end

      test_deletion_using_options = -> do
        options = page.all('option').map(&:text)
        expect(options).not_to include(target_name)
      end

      test_deletion_using_css = -> do
        expect page.all('#tbl_barcode_items_name').include?(target_name)
      end

      test_deletion_using_have_css = -> do
        expect(page).not_to have_css("#tbl_barcode_items_name", text: target_name)
      end

      test_deletion_using_options.()
      test_deletion_using_have_content.()
      test_deletion_using_css.()
      test_deletion_using_have_css.()
      # require 'pry'; binding.pry


    end

    it "should view a barcode shows details about it"
  end
end
