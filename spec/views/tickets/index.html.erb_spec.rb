RSpec.describe "tickets/index.html.erb", type: :view do
  before :each do
      item = create(:item)
      inventory = create(:inventory, :with_items, item_quantity: 10, item: item)
      @ticket = create(:ticket, :with_items, inventory: inventory, item_quantity: 10, item: item)

      assign(:tickets, [@ticket])
      render
    end

    it "shows summary information about the tickets, including CRUD controls" do
      # The Partner Name
      expect(rendered).to have_xpath("//table/tbody/tr/td", text: @ticket.partner.name)
      # The source inventory
      expect(rendered).to have_xpath("//table/tbody/tr/td", text: @ticket.inventory.name)
      # The total quantity of items in this ticket so far
      expect(rendered).to have_xpath("//table/tbody/tr/td", text: "10")
      # The link for viewing the ticket
      expect(rendered).to have_xpath("//table/tbody/tr/td/a[@href='#{ticket_path(@ticket)}']")
      # The link for reclaiming the ticket
      expect(rendered).to have_xpath("//table/tbody/tr/td/a[@href='#{reclaim_ticket_path(@ticket)}']")
      # The link for printing the ticket
      expect(rendered).to have_xpath("//table/tbody/tr/td/a[@href='#{print_ticket_path(@ticket)}']")
    end
end
