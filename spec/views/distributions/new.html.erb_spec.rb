RSpec.describe "distributions/new.html.erb", type: :view do
  before(:each) do
    @organization = create(:organization)
    @storage_location = create(:storage_location, organization_id: @organization.id)
    @partner = create(:partner, organization_id: @organization.id)

    assign(:distribution, Distribution.new)
    assign(:storage_locations, [@storage_location])
    assign(:partner, @partner)
    assign(:organization, @organization)

    render
  end

  it "Asks for storage location and partner", :focus do
    expect(rendered).to have_xpath("//form/div/select[@name='distribution[storage_location_id]']")
    expect(rendered).to have_xpath("//form/div/select[@name='distribution[partner_id]']")
  end
end
