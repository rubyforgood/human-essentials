require 'rails_helper'

RSpec.describe "barcode_items/edit.html.erb", type: :view do
  it "shows a form that asks for an item, quantity, and barcode" do
  	assign(:barcode_item, create(:barcode_item))
    render
    expect(rendered).to have_xpath("//form/div/input[@type='number'][@name='barcode_item[quantity]']")
    expect(rendered).to have_xpath("//form/div/select[@name='barcode_item[item_id]']")
    expect(rendered).to have_xpath("//form/div/input[@type='text'][@name='barcode_item[value]']")
  end
end
