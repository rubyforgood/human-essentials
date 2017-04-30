require 'rails_helper'

RSpec.describe "partners/index.html.erb", type: :view do
  before(:each) do
    @partner1 = create(:partner, email: "test@test.com")
    @partner2 = create(:partner, email: "foo@bar.com")
    assign(:partners, [@partner1, @partner2])
    render
  end

  it "lists all community partners" do
    expect(rendered).to have_css("table#partners tbody tr", count: 2)
  end

  it "shows the e-mail, if available" do
  	expect(rendered).to have_xpath("//table[@id='partners']/tbody/tr/td/a[@href='mailto:#{@partner1.email}']", text: @partner1.email)
  end

  it "has CRUD options for each one" do
  	expect(rendered).to have_css("table#partners tbody tr td a", text: "View")
	expect(rendered).to have_css("table#partners tbody tr td a", text: "Edit")
	expect(rendered).to have_css("table#partners tbody tr td a", text: "Delete")
  end
end
