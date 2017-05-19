RSpec.describe "storage_locations/edit.html.erb", type: :view do
  it "shows a form that asks for a name and address" do
    assign(:storage_location, create(:storage_location))
    render
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='storage_location[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='storage_location[address]']")
  end
end
