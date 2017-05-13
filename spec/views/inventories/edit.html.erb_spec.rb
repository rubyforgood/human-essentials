

RSpec.describe "inventories/edit.html.erb", type: :view do
  it "shows a form that asks for a name and address" do
  	assign(:inventory, create(:inventory))
    render
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='inventory[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='inventory[address]']")
  end
end
