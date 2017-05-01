require 'rails_helper'

RSpec.describe "items/index.html.erb", type: :view do
  before(:each) do
  	@item1 = create(:item, category: "same")
  	@item2 = create(:item, category: "different")
  	create(:barcode_item, item: @item1)
    assign(:items, [
    	@item1,
    	@item2
    	])
    assign(:categories, Item.categories)
    render
  end

  it "Shows all items in a table" do
  	expect(rendered).to have_css("table#items tbody tr", count: 2)
  end

  it "Has CRUD links in each row" do
		expect(rendered).to have_css("table#items tbody tr td a", text: "View")
		expect(rendered).to have_css("table#items tbody tr td a", text: "Edit")
		expect(rendered).to have_css("table#items tbody tr td a", text: "Delete")
  end

  context "With filters" do
  	it "Has filters" do
  		expect(rendered).to have_css("#filters")
  	end

    it "Has a filter option to constrain Item category" do
      expect(rendered).to have_css("select#filters_in_category")
      expect(rendered).to have_css("select#filters_in_category option", count: 2)
    end
  
  end
end
