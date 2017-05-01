require 'rails_helper'

RSpec.describe "dropoff_locations/edit.html.erb", type: :view do
  it "shows a form that asks for a name and address" do
  	assign(:dropoff_location, create(:dropoff_location))
    render
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='dropoff_location[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='dropoff_location[address]']")
  end
end
