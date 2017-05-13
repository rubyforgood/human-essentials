

RSpec.describe "dropoff_locations/new.html.erb", type: :view do
  before(:each) do
  	assign(:dropoff_location, DropoffLocation.new)

  	render
  end

  it "shows a form that asks for a name and address" do
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='dropoff_location[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='dropoff_location[address]']")
  end
end
