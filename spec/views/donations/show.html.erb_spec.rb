RSpec.describe "donations/show.html.erb", type: :view do
  context "when viewing a donation" do
    before :each do
      @donation = create(:donation, :with_item, item_quantity: 5, item_id: create(:item).id, donationd: true)
      assign(:donation, @donation)
      assign(:line_items, @donation.line_items)
      render
    end

    it "Lists the items found in the donation, along with quantities" do
      expect(rendered).to have_xpath("//section[@id='line_items']/table/tbody/tr", count: 1)
    end
  end
end
