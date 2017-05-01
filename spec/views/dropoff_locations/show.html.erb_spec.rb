require 'rails_helper'

RSpec.describe "dropoff_locations/show.html.erb", type: :view do
  before(:each) do
  	@dropoff_location = create(:dropoff_location)
    assign(:dropoff_location, @dropoff_location)
    render
  end

  it "shows the name and address for the dropoff location" do
    expect(rendered).to have_content(@dropoff_location.name)
    expect(rendered).to have_content(@dropoff_location.address)
  end

end
