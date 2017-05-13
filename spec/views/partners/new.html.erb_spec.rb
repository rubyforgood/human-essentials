

RSpec.describe "partners/new.html.erb", type: :view do
  before(:each) do
  	assign(:partner, Partner.new)

  	render
  end

  it "shows a form that asks for a name and email" do
    expect(rendered).to have_xpath("//form/div/input[@type='text']")
    expect(rendered).to have_xpath("//form/div/input[@type='email']")
  end
end
