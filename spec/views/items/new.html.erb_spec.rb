require 'rails_helper'

RSpec.describe "items/new.html.erb", type: :view do
  it "shows a form that asks for a name and category" do
  	assign(:item, Item.new)
    render
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='item[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='item[category]']")
  end
end
