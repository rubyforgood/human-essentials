

RSpec.describe "items/edit.html.erb", type: :view do
  it "shows a form that asks for a name and category" do
  	assign(:item, create(:item))
    render
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='item[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='item[category]']")
  end
end
