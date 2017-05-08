require 'rails_helper'

RSpec.describe "transfers/new.html.erb", type: :view do
  before(:each) do
  	@item = create(:item)
  	@item2 = create(:item)
  	@from = create(:inventory, :with_items, item: @item, item_quantity: 10)
  	@to = create(:inventory)

    assign(:transfer, Transfer.new)
    assign(:inventories, [@from, @to])
    assign(:items, [@item, @item2])

  	render
  end

  it "asks for 2 different inventories" do
  	expect(rendered).to have_xpath("//form/div/select[@name='transfer[from_id]']")
  	expect(rendered).to have_xpath("//form/div/select[@name='transfer[to_id]']")
  end

  xit "shows fields for the user to add items to this transfer manifest" do
  	# TODO: How should this work?
  end
end
