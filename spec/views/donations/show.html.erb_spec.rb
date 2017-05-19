RSpec.describe "donations/show.html.erb", type: :view do
  context "when viewing an incomplete donation" do
    before :each do
      # create an incomplete donation
      @incomplete = create(:donation, :with_item, item_quantity: 5, item_id: create(:item).id, completed: false)
      assign(:donation, @incomplete)

      render
    end

    xit "shows a form for adding items to this donation" do
      # TODO: what's the workflow for this?
    end

    it "shows the details of the donation" do
      expect(rendered).to have_content(@incomplete.source)
      expect(rendered).to have_content(@incomplete.dropoff_location.name)
      expect(rendered).to have_content(@incomplete.storage_location.name)
    end

    it "shows a 'Complete' link" do
      expect(rendered).to have_xpath("//a[@href='#{complete_donation_path(@incomplete)}']")
    end
  end

  context "when viewing a completed donation" do
    before :each do
      @complete = create(:donation, :with_item, item_quantity: 5, item_id: create(:item).id, completed: true)
      assign(:donation, @complete)
      assign(:line_items, @complete.line_items)
      render
    end

    it "DOES list the items found in the donation, along with quantities" do
      expect(rendered).to have_xpath("//section[@id='line_items']/table/tbody/tr", count: 1)
    end

    it "does NOT show any forms for doing anything" do
      expect(rendered).not_to have_xpath("//section[@id='line_items']/select")
      expect(rendered).not_to have_xpath("//section[@id='line_items']/input")
    end

    it "does NOT show a 'Complete' link" do
      expect(rendered).not_to have_xpath("//a[@href='#{complete_donation_path(@complete)}']")
    end

  end
end
