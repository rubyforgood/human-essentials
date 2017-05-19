RSpec.describe "storage_locations/index.html.erb", type: :view do
  before(:each) do
    item = create(:item)
    @location1 = create(:storage_location, :with_items, item: item, item_quantity: 100)
    assign(:storage_locations, [@location1, create(:storage_location)])
    render
  end

  it "shows a table of all storage locations" do
    expect(rendered).to have_css("table#storage_locations tbody tr", count: 2)
  end

  it "shows the sum total of units at each location" do
    expect(rendered).to have_css("table#storage_locations tbody tr td", text: "100")
  end

  it "has CRUD options for each one" do
    expect(rendered).to have_css("table#storage_locations tbody tr td a", text: "View")
    expect(rendered).to have_css("table#storage_locations tbody tr td a", text: "Edit")
    expect(rendered).to have_css("table#storage_locations tbody tr td a", text: "Delete")
  end
end

