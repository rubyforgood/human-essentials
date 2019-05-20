RSpec.describe "Barcode management", type: :system, js: true do
  before do
    sign_in(@user)
  end
  let(:url_prefix) { "/#{@organization.to_param}" }

  context "While viewing the barcode items index page" do
    subject { url_prefix + "/barcode_items" }

    before do
      Item.delete_all
    end

    it "should only show the barcodes created within the organization" do
      create(:barcode_item, organization_id: @organization.id)
      create(:barcode_item, global: true)
      visit subject
      expect(page).to have_css("table#tbl_barcode_items tbody tr", count: 1)
    end

    it "can have a user filter the #index by barcode value" do
      b = create(:barcode_item, organization: @organization)
      create(:barcode_item, organization: @organization)
      visit subject
      fill_in "filters_by_value", with: b.value
      click_button "Filter"

      expect(page).to have_css("table tbody tr", count: 1)
    end

    it "should have the filter presented to user list items in alphabetical order" do
      item1 = create(:item, name: "AAA Diapers")
      item2 = create(:item, name: "Wonder Diapers")
      item3 = create(:item, name: "ABC Diapers")
      expected_order = ["", item1.name, item3.name, item2.name]

      create(:barcode_item, barcodeable: item3)
      create(:barcode_item, barcodeable: item2)
      create(:barcode_item, barcodeable: item1)
      visit subject

      expect(page.all("select#filters_barcodeable_id option").map(&:text)).to eq(expected_order)
      expect(page.all("select#filters_barcodeable_id option").map(&:text)).not_to eq(expected_order.reverse)
    end

    it "can have a user filter the #index by item type" do
      b = create(:barcode_item, organization: @organization)
      create(:barcode_item, organization: @organization)
      visit subject
      select b.item.name, from: "filters_barcodeable_id"
      click_button "Filter"

      expect(page).to have_css("table tbody tr", count: 1)
    end

    it "can have a user filter the #index by base item type" do
      item = create(:item, name: "Red 1T Diapers", base_item: BaseItem.first)
      item2 = create(:item, name: "Blue 1T Diapers", base_item: BaseItem.first)
      create(:barcode_item, organization: @organization, barcodeable: item)
      create(:barcode_item, organization: @organization, barcodeable: item2)
      visit subject
      select BaseItem.first.name, from: "filters_by_item_partner_key"
      click_button "Filter"

      expect(page).to have_css("table tbody tr", count: 2)
    end
  end

  context "With organization-specific barcodes" do
    let(:barcode_traits) { attributes_for(:barcode_item, organization_id: @organization.id) }

    it "can have a user add a new barcode" do
      Item.delete_all
      item = create(:item, name: "1T Diapers")
      visit url_prefix + "/barcode_items/new"
      select item.name, from: "Item"
      fill_in "Quantity", id: "barcode_item_quantity", with: barcode_traits[:quantity]
      fill_in "Barcode", id: "barcode_item_value", with: barcode_traits[:value]
      click_button "Save"

      expect(page.find(".alert")).to have_content "added to your"

      expect(page.find("table")).to have_content "1T Diapers"

      click_button "Filter"

      expect(page.find("table")).to have_content "1T Diapers"
    end

    context "when editing an existing barcode" do
      subject { url_prefix + "/barcode_items/#{barcode.id}/edit" }
      let!(:barcode) { create(:barcode_item, organization_id: @organization.id) }

      it "saves the changes if they are valid" do
        create(:item)
        visit subject
        fill_in "Quantity", id: "barcode_item_quantity", with: (barcode.quantity.to_i + 10).to_s
        click_button "Save"

        expect(page.find(".alert")).to have_content "updated"
      end

      it "fails to save the changes if the attributes are empty" do
        visit subject
        fill_in "Quantity", id: "barcode_item_quantity", with: ""
        click_button "Save"

        expect(page.find(".alert")).to have_content "didn't work"
      end
    end
  end

  it "prevents a user from adding a new barcode with empty attributes" do
    visit url_prefix + "/barcode_items/new"
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end
end
