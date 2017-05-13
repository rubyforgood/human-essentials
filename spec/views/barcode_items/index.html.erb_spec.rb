

RSpec.describe "barcode_items/index.html.erb", type: :view do
  before(:each) do
  	@item1 = create(:item)
  	@item2 = create(:item)
    assign(:barcode_items, [
    	create(:barcode_item, item: @item1, quantity: 10),
    	create(:barcode_item, item: @item1, quantity: 100),
    	create(:barcode_item, item: @item2, quantity: 10)
    	])
    assign(:items, [@item1, @item2])
    render
  end

  it "Shows all barcodes in a table" do
  	expect(rendered).to have_css("table#barcode_items tbody tr", count: 3)
  end

  it "Has CRUD links in each row" do
		expect(rendered).to have_css("table#barcode_items tbody tr td a", text: "View")
		expect(rendered).to have_css("table#barcode_items tbody tr td a", text: "Edit")
		expect(rendered).to have_css("table#barcode_items tbody tr td a", text: "Delete")
  end

  context "With filters" do
  	it "Has filters" do
  		expect(rendered).to have_css("#filters")
  	end

    it "Has a filter option to constrain Barcodes by Item type" do
      expect(rendered).to have_css("select#filters_item_id")
      expect(rendered).to have_css("select#filters_item_id option", count: 2)
    end
  
  end
end
