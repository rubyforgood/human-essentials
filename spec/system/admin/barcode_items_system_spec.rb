RSpec.describe "Barcode Items Admin", type: :system do
  let(:organization) { create(:organization) }
  let(:super_admin) { create(:super_admin, organization: organization) }

  let!(:base_item) { create(:base_item) }
  let!(:item) { create(:item, base_item: base_item) }
  let!(:barcode_item) { create(:global_barcode_item, base_item: base_item) }

  context "while signed in as a super admin" do
    before do
      sign_in(super_admin)
    end

    context "user visits the index page" do
      before do
        visit admin_barcode_items_path
      end

      it 'shows the barcode item' do
        expect(page).to have_content(barcode_item.barcodeable.name)
        expect(page).to have_content(barcode_item.value)
      end

      it "deletes a global barcode" do
        expect(accept_confirm { click_on "Delete" }).to include "Are you sure you want to delete"
        expect(page).to have_no_content "\n#{barcode_item.base_item.name}"
      end

      it 'creates a new global barcode item' do
        click_on "Add New Barcode"

        fill_in "Quantity", with: 100
        select item.base_item.name, from: "barcode_item_barcodeable_id"
        fill_in "Barcode", with: 66_666

        click_on "Save"

        expect(page).to have_content(66_666)
        expect(page).to have_content("Barcode Item added!")
      end
    end

    context "user visits the new page" do
      before do
        visit new_admin_barcode_item_path
      end

      it 'creates a new global barcode item' do
        fill_in "Quantity", with: 100
        select item.base_item.name, from: "barcode_item_barcodeable_id"
        fill_in "Barcode", with: 66_666

        click_on "Save"

        expect(page).to have_content(66_666)
        expect(page).to have_content("Barcode Item added!")
      end
    end

    context "user visits the edit page" do
      before do
        visit edit_admin_barcode_item_path(barcode_item)
      end

      it 'updates the barcode item' do
        fill_in "Quantity", with: 100
        select item.base_item.name, from: "barcode_item_barcodeable_id"
        fill_in "Barcode", with: 66_666

        click_on "Save"

        expect(page).to have_content(66_666)
        expect(page).to have_content("Updated Barcode Item!")
      end
    end

    context "user visits the show page" do
      before do
        visit admin_barcode_item_path(barcode_item)
      end

      it 'shows the barcode item' do
        expect(page).to have_content(barcode_item.barcodeable.name)
        expect(page).to have_content(barcode_item.value)
      end
    end
  end
end
