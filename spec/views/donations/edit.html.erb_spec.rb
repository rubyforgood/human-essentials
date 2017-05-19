

RSpec.describe "donations/edit.html.erb", type: :view do
  before(:each) do
  	@dropoff_location = create(:dropoff_location)
  	@inventory = create(:inventory)
  	@item_existing = create(:item)
  	@new_item = create(:item)
  	@donation = create(:donation, :with_item, item_quantity: 10, item_id: @item_existing.id)

    assign(:dropoff_locations, [@dropoff_location])
    assign(:inventories, [@inventory])
    assign(:items, [@item_existing, @new_item])
  	assign(:donation, @donation)

  	render
  end

  it "allows you to edit the existing donation traits from the #new action" do
    expect(rendered).to have_xpath("//form/div/select[@name='donation[inventory_id]']/option[@value='#{@inventory.id}']")
    expect(rendered).to have_xpath("//form/div/select[@name='donation[dropoff_location_id]']/option[@value='#{@dropoff_location.id}']")
    expect(rendered).to have_xpath("//form/div/select[@name='donation[source]']/option[@value='#{@donation.sources.first}']")
  end

end
