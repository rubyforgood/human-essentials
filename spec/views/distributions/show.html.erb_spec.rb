RSpec.describe "distributions/show.html.erb", type: :view do
  context "when viewing a distribution" do
    before :each do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item_quantity: 5, item: item)
      @distribution = create(:distribution, :with_items, storage_location: storage_location, item_quantity: 5, item: item)
      assign(:distribution, @distribution)
      assign(:line_items, @distribution.line_items)
      render
    end

    it "DOES list the items found in the distribution, along with quantities" do
      expect(rendered).to have_xpath("//section[@id='line_items']/table/tbody/tr", count: 1)
    end
  end
end
