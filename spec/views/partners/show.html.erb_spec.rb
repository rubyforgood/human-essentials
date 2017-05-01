require 'rails_helper'

RSpec.describe "partners/show.html.erb", type: :view do
  before(:each) do
  	@partner = create(:partner)
    assign(:partner, @partner)
    render
  end

  it "shows the name and email address for the partner" do
    expect(rendered).to have_content(@partner.name)
    expect(rendered).to have_xpath("//p/a[@href='mailto:#{@partner.email}']", text: @partner.email)
  end

end
