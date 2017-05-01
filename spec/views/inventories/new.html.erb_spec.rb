require 'rails_helper'

RSpec.describe "inventories/new.html.erb", type: :view do
  before(:each) do
  	assign(:inventory, Inventory.new)

  	render
  end

  it "shows a form that asks for a name and address" do
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='inventory[name]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='inventory[address]']")
  end
end
