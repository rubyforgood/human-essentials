

RSpec.describe "inventories/show.html.erb", type: :view do
  before(:each) do
    inventory = create(:inventory)
    item1 = create(:item)
    item2 = create(:item)
    create(:inventory_item, inventory: inventory, item: item1, quantity: 100)
    create(:inventory_item, inventory: inventory, item: item2, quantity: 50)

    assign(:inventory, inventory)
    render
  end

  it "shows the full listing of the inventory's contents" do
    expect(rendered).to have_xpath("//table[@id='inventory']/tbody/tr", count: 2)
    expect(rendered).to have_xpath("//table[@id='inventory']/tfoot/tr/td", text: "150")
  end

  it "has links for the items in the item column" do
    item = Item.first
    expect(rendered).to have_xpath("//table[@id='inventory']/tbody/tr/td/a[@href='#{item_path(item)}']", text: item.name)
  end
end
