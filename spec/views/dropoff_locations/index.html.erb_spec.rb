

RSpec.describe "dropoff_locations/index.html.erb", type: :view do
  before(:each) do
  	assign(:dropoff_locations, [create(:dropoff_location),create(:dropoff_location)])
    render
  end

  it "shows a table of all locations" do
  	expect(rendered).to have_css("table#dropoff_locations tbody tr", count: 2)
  end

  it "has CRUD options for each one" do
  	expect(rendered).to have_css("table#dropoff_locations tbody tr td a", text: "View")
	expect(rendered).to have_css("table#dropoff_locations tbody tr td a", text: "Edit")
	expect(rendered).to have_css("table#dropoff_locations tbody tr td a", text: "Delete")
  end
end

