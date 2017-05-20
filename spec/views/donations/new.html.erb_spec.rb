RSpec.describe "donations/new.html.erb", type: :view do
  before(:each) do
    @organization     = create(:organization)
    @dropoff_location = create(:dropoff_location)
    @storage_location = create(:storage_location)

    assign(:dropoff_locations, [@dropoff_location])
    assign(:storage_locations, [@storage_location])
    assign(:organization_id,   @organzation.id)
    assign(:donation, Donation.new)

    render
  end

  it "asks for a dropoff location, storage location, and source" do
    expect(rendered).to have_xpath("//form/div/select[@name='donation[storage_location_id]']/option[@value='#{@storage_location.id}']")
    expect(rendered).to have_xpath("//form/div/select[@name='donation[dropoff_location_id]']/option[@value='#{@dropoff_location.id}']")
    expect(rendered).to have_xpath("//form/div/input[@name='donation[source]']")
  end
end
