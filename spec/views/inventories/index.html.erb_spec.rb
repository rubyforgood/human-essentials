require 'rails_helper'

RSpec.describe "inventories/index.html.erb", type: :view do
  before(:each) do
  	item = create(:item)
  	@inventory1 = create(:inventory, :with_items, item: item, item_quantity: 100)
    assign(:inventories, [@inventory1, create(:inventory)])
    render
  end

  it "shows a table of all inventories" do
  	expect(rendered).to have_css("table#inventories tbody tr", count: 2)
  end

  it "shows the sum total of units at each location" do
  	expect(rendered).to have_css("table#inventories tbody tr td", text: "100")
  end

  it "has CRUD options for each one" do
  	expect(rendered).to have_css("table#inventories tbody tr td a", text: "View")
	expect(rendered).to have_css("table#inventories tbody tr td a", text: "Edit")
	expect(rendered).to have_css("table#inventories tbody tr td a", text: "Delete")
  end
end

