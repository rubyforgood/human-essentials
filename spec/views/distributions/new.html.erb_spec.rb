RSpec.describe "distributions/new.html.erb", type: :view do
  before(:each) do
    @organization = create(:organization)
    @storage_location = create(:storage_location, organization_id: @organization.id)
    @partner = create(:partner, organization_id: @organization.id)

    assign(:distribution, Distribution.new)
    assign(:storage_locations, [@storage_location])
    assign(:partner, @partner)
    assign(:organization_id, @organization.id)

    render
  end

  it "Asks for storage location and partner" do
    expect(rendered).to have_xpath("//form/div/select[@name='distribution[storage_location_id]']")
    expect(rendered).to have_xpath("//form/div/select[@name='distribution[partner_id]']")
  end

  xit "shows fields for the user to add items to this distribution" do
    # TODO: How should this work?
  end
end
