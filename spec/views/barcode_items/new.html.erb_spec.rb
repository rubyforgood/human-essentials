require 'rails_helper'

RSpec.describe "barcode_items/new.html.erb", type: :view do
  before(:each) do
  	assign(:barcode_item, BarcodeItem.new)
  	render
  end

  it "shows a form that asks for a name quantity and barcode value" do
    expect(rendered).to have_xpath("//form/div/input[@type='number'][@name='barcode_item[quantity]']")
    expect(rendered).to have_xpath("//form/div/select[@name='barcode_item[item_id]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='barcode_item[value]']")
  end
end
