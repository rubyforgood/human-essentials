RSpec.describe "tickets/index.html.erb", type: :view do
  before :each do
      item = create(:item)
      # create a completed donation
      @completed = create(:donation, :with_item, item_quantity: 10, item_id: item.id, completed: true)
      assign(:completed, [@completed])
      # create an incomplete donation
      @incomplete = create(:donation, :with_item, item_quantity: 5, item_id: item.id, completed: false)
      assign(:incomplete, [@incomplete])

      render
    end

    xit "shows the incomplete donations displayed separately from completed donations" do
      # The incomplete table
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr", count: 1)
      # The completed table
      expect(rendered).to have_xpath("//table[@id='completed']/tbody/tr", count: 1)
    end

    xit "shows summary information about the donations, including CRUD controls" do
      # The Dropoff Name
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td", text: @incomplete.dropoff_location.name)
      # The donation source
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td", text: @incomplete.source)
      # The storage location
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td", text: @incomplete.inventory.name)
      # The link for adding more items
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td/a[@href='#{edit_donation_path(@incomplete)}']")
      # The link to cancel it
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td/a", text: "Cancel")
      # The donation status
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td", text: "In Progress")
      # The total quantity of items in this donation so far
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td", text: "5")
      # The total number of different types of items in this donation so far
      expect(rendered).to have_xpath("//table[@id='incomplete']/tbody/tr/td", text: "1")

      # The donation status
      expect(rendered).to have_xpath("//table[@id='completed']/tbody/tr/td", text: "Completed")
      # The link for viewing the donation
      expect(rendered).to have_xpath("//table[@id='completed']/tbody/tr/td/a", text: "View")
      # Shouldn't have a cancel link anymore
      expect(rendered).not_to have_xpath("//table[@id='completed']/tbody/tr/td/a", text: "Cancel")
      # Shouldn't be able to add new items to it
      expect(rendered).not_to have_xpath("//table[@id='completed']/tbody/tr/td/a[@href='#{edit_donation_path(@completed)}']")
      # The total quantity of items in this donation
      expect(rendered).to have_xpath("//table[@id='completed']/tbody/tr/td", text: "10")
      # The total different types of items in this donation
      expect(rendered).to have_xpath("//table[@id='completed']/tbody/tr/td", text: "1")
    end
end
