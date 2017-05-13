RSpec.describe "tickets/show.html.erb", type: :view do
  context "when viewing a ticket" do
    before :each do
      item = create(:item)
      inventory = create(:inventory, :with_items, item_quantity: 5, item: item)
      @ticket = create(:ticket, :with_items, inventory: inventory, item_quantity: 5, item: item)
      assign(:ticket, @ticket)
      assign(:containers, @ticket.containers)
      render
    end

    it "DOES list the items found in the ticket, along with quantities" do
    	expect(rendered).to have_xpath("//section[@id='containers']/table/tbody/tr", count: 1)
    end
  end
end
