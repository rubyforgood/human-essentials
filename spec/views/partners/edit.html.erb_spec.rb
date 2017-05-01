require 'rails_helper'

RSpec.describe "partners/edit.html.erb", type: :view do
  it "shows a form that asks for a name and email" do
  	assign(:partner, create(:partner))
    render
    expect(rendered).to have_xpath("//form/div/input[@type='text']")
    expect(rendered).to have_xpath("//form/div/input[@type='email']")
  end
end
