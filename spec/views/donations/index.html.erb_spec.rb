RSpec.describe "donations/index.html.erb", type: :view do
  before :each do
    item = create(:item)
    @donation = create(:donation, :with_item, item_quantity: 10, item_id: item.id)

    render
  end

  it "shows summary information about the donations, including CRUD controls" do
    # The Dropoff Name
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td", text: @donation.dropoff_location.name)
    # The donation source
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td", text: @donation.source)
    # The storage location
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td", text: @donation.storage_location.name)
    # The link for adding more items
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td/a[@href='#{edit_donation_path(@donation)}']")
    # The link to cancel it
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td/a", text: "Cancel")
    # The donation status
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td", text: "In Progress")
    # The total quantity of items in this donation so far
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td", text: "5")
    # The total number of different types of items in this donation so far
    expect(rendered).to have_xpath("//table[@id='donations']/tbody/tr/td", text: "1")
  end
end
