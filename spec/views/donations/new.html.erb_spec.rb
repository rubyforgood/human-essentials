

RSpec.describe "donations/new.html.erb", type: :view do
  before(:each) do
  	@dropoff_location = create(:dropoff_location)
  	@inventory = create(:inventory)

    assign(:dropoff_locations, [@dropoff_location])
    assign(:inventories, [@inventory])
  	assign(:donation, Donation.new)

  	render
  end

  it "asks for a dropoff location, storage location, and source" do
    expect(rendered).to have_xpath("//form/div/select[@name='donation[inventory_id]']/option[@value='#{@inventory.id}']")
    expect(rendered).to have_xpath("//form/div/select[@name='donation[dropoff_location_id]']/option[@value='#{@dropoff_location.id}']")
    expect(rendered).to have_xpath("//form/div/input[@name='donation[source]']")
  end
end
