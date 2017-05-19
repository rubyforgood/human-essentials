

RSpec.describe "items/show.html.erb", type: :view do
  context "With an item among others in a category" do
    before(:each) do
      @item = create(:item, name: "Foo", category: "same")
      create(:item, name: "Bar", category: "same")
      create(:item, name: "Baz", category: "Not same")
      assign(:item, @item)
      assign(:items_in_category, Item.in_same_category_as(@item))
      render
    end

    it "shows the name and category for the item" do
      expect(rendered).to have_content(@item.name)
      expect(rendered).to have_content(@item.category)
    end

    it "shows any associated items in the same category" do
      expect(rendered).to have_css("ul#category li a", count: 1)
    end
  end

  context "With an item with no fellow items in the same category" do
    it "does not display the list" do
      @item = create(:item, category: "same")
      create(:item, category: "not same")

      assign(:item, @item)
      render
      expect(rendered).not_to have_css("ul#category")
    end
  end

  context "With an inventoried item" do
    it "lists which inventories contain the item, and how many are at that location" do
      @item = create(:item)
      location1 = create(:storage_location, :with_items, item: @item, item_quantity: 10)
      location2 = create(:storage_location, :with_items, item: @item, item_quantity: 30)
      assign(:item, @item)
      assign(:in_inventories, Item.storage_locations_containing(@item))

      render

      expect(rendered).to have_css("table#inventories tbody tr", count: 2)
      expect(rendered).to have_css("table#inventories tbody tr td", text: location1.name)
      expect(rendered).to have_css("table#inventories tbody tr td", text: '10')
      expect(rendered).to have_css("table#inventories tfoot tr td", text: '40')
    end
  end

  context "With a barcoded item" do
    it "lists all barcodes associated with the item" do
      @item = create(:item)
      barcode1 = create(:barcode_item, item: @item, quantity: 10)
      barcode2 = create(:barcode_item, item: @item, quantity: 100)
      assign(:item, @item)
      assign(:barcodes_for, Item.barcodes_for(@item))

      render

      expect(rendered).to have_css("table#barcode_items tbody tr", count: 2)
      expect(rendered).to have_css("table#barcode_items tbody tr td", text: barcode1.quantity)
    end
  end
end
