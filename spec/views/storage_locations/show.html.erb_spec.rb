

RSpec.describe "storage_locations/show.html.erb", type: :view do
  before(:each) do
    storage_location = create(:storage_location)
    item1 = create(:item)
    item2 = create(:item)
    create(:inventory_item, storage_location: storage_location, item: item1, quantity: 100)
    create(:inventory_item, storage_location: storage_location, item: item2, quantity: 50)

    assign(:storage_location, storage_location)
    render
  end

  it "shows the full listing of the storage location's contents" do
    expect(rendered).to have_xpath("//table[@id='storage_location']/tbody/tr", count: 2)
    expect(rendered).to have_xpath("//table[@id='storage_location']/tfoot/tr/td", text: "150")
  end

  it "has links for the items in the item column" do
    item = Item.first
    expect(rendered).to have_xpath("//table[@id='storage_location']/tbody/tr/td/a[@href='#{item_path(item)}']", text: item.name)
  end
end
