

RSpec.describe "storage_locations/new.html.erb", type: :view do
  before(:each) do
    assign(:storage_location, StorageLocation.new)
    render
  end

  it "shows a form that asks for a name and address" do
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='storage_location[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='storage_location[address]']")
  end
end
